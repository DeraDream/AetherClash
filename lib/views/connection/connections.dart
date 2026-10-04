import 'dart:async';
import 'dart:convert';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/event.dart';
import 'package:fl_clash/core/method.dart';
import 'package:fl_clash/features/features.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

enum _ConnectionTab { active, closed }

enum _ConnectionOrder {
  time,
  upload,
  download,
  uploadSpeed,
  downloadSpeed,
}

// Match Clash Party's page-level cache: recently closed entries remain when
// the user leaves Activity and comes back, but never grow without bounds.
List<TrackerInfo> _cachedClosedConnections = const [];

class ConnectionsView extends ConsumerStatefulWidget {
  final Future<List<TrackerInfo>> Function()? connectionsReader;

  const ConnectionsView({super.key, @visibleForTesting this.connectionsReader});

  @override
  ConsumerState<ConnectionsView> createState() => _ConnectionsViewState();
}

class _ConnectionsViewState extends ConsumerState<ConnectionsView>
    with
        WidgetsBindingObserver,
        ActivePollingMixin<ConnectionsView>,
        CoreEventListener {
  CoreController get _core => ref.read(coreHandlerProvider);

  final ScrollController _scrollController = ScrollController();
  final Map<String, TrackerInfo> _previousActive = {};

  List<TrackerInfo> _activeConnections = const [];
  List<TrackerInfo> _closedConnections = List.of(_cachedClosedConnections);
  _ConnectionTab _tab = _ConnectionTab.active;
  _ConnectionOrder _order = _ConnectionOrder.time;
  bool _ascending = true;
  String _query = '';
  List<String> _keywords = const [];
  DateTime? _lastSnapshotAt;
  Timer? _requestRefreshTimer;

  @override
  Duration get pollInterval => const Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    coreEventManager.addListener(this);
  }

  @override
  void onRequest(TrackerInfo connection) {
    // The core already emits a request event as soon as a connection appears.
    // Use it to wake the snapshot reader immediately; the 500ms poll remains
    // responsible for speed deltas and detecting closed connections.
    _requestRefreshTimer ??= Timer(const Duration(milliseconds: 80), () {
      _requestRefreshTimer = null;
      if (mounted) {
        unawaited(_refreshConnections());
      }
    });
  }

  String _text(String zh, String en) {
    return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  }

  @override
  Future<void> poll(PollGuard isCurrent) async {
    final trackerInfos = await _readConnections();
    if (trackerInfos == null || !isCurrent()) {
      return;
    }
    _applyConnections(trackerInfos);
  }

  Future<void> _refreshConnections() async {
    final trackerInfos = await _readConnections();
    if (trackerInfos == null || !mounted) {
      return;
    }
    _applyConnections(trackerInfos);
  }

  Future<List<TrackerInfo>?> _readConnections() async {
    try {
      final connectionsReader = widget.connectionsReader;
      return connectionsReader != null
          ? await connectionsReader()
          : await _core.getConnections();
    } catch (error) {
      commonPrint.log(
        'updateConnections error: $error',
        logLevel: coreFailureLogLevel(error),
      );
      return null;
    }
  }

  void _applyConnections(List<TrackerInfo> snapshot) {
    final now = DateTime.now();
    final previousAt = _lastSnapshotAt;
    final elapsedMs = previousAt == null
        ? 1000
        : (now.difference(previousAt).inMilliseconds).clamp(1, 10000);
    _lastSnapshotAt = now;

    final currentIds = snapshot.map((item) => item.id).toSet();
    final closed = List<TrackerInfo>.from(_closedConnections);

    // Anything that existed in the previous snapshot but no longer exists is
    // moved to Closed, preserving its last counters exactly like Clash Party.
    for (final previous in _previousActive.values) {
      if (currentIds.contains(previous.id)) continue;
      closed.removeWhere((item) => item.id == previous.id);
      closed.insert(
        0,
        previous.copyWith(downloadSpeed: 0, uploadSpeed: 0),
      );
    }

    final active = <TrackerInfo>[];
    final nextPrevious = <String, TrackerInfo>{};
    for (final current in snapshot) {
      final previous = _previousActive[current.id];
      final downloadDelta = previous == null
          ? 0
          : (current.download - previous.download).clamp(0, 1 << 62);
      final uploadDelta = previous == null
          ? 0
          : (current.upload - previous.upload).clamp(0, 1 << 62);
      final downloadSpeed = (downloadDelta * 1000 / elapsedMs).round();
      final uploadSpeed = (uploadDelta * 1000 / elapsedMs).round();
      final withSpeed = current.copyWith(
        downloadSpeed: downloadSpeed,
        uploadSpeed: uploadSpeed,
      );
      active.add(withSpeed);
      nextPrevious[current.id] = withSpeed;

      // A reused/reconnected id must not appear in both tabs.
      closed.removeWhere((item) => item.id == current.id);
    }

    if (closed.length > 200) {
      closed.removeRange(200, closed.length);
    }

    _previousActive
      ..clear()
      ..addAll(nextPrevious);
    _cachedClosedConnections = List.unmodifiable(closed);

    if (!mounted) return;
    setState(() {
      _activeConnections = active;
      _closedConnections = closed;
    });
  }

  String _searchBlob(TrackerInfo connection) {
    final metadata = connection.metadata;
    return [
      jsonEncode(connection.toJson()),
      connection.id,
      connection.rule,
      connection.rulePayload,
      connection.chains.join(' '),
      metadata.network,
      metadata.host,
      metadata.sourceIP,
      metadata.sourcePort,
      metadata.destinationIP,
      metadata.destinationPort,
      metadata.process,
      metadata.processPath,
      metadata.remoteDestination,
      metadata.destinationIPASN,
      metadata.sourceIPASN,
      metadata.specialRules,
      metadata.specialProxy,
      metadata.sourceGeoIP.join(' '),
      metadata.destinationGeoIP.join(' '),
    ].join(' ').toLowerCase();
  }

  List<TrackerInfo> _visibleConnections() {
    final source = _tab == _ConnectionTab.active
        ? _activeConnections
        : _closedConnections;
    final query = _query.trim().toLowerCase();
    final keywords = _keywords
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    final filtered = source.where((connection) {
      final blob = _searchBlob(connection);
      if (query.isNotEmpty && !blob.contains(query)) return false;
      return keywords.every(blob.contains);
    }).toList(growable: false);

    final result = List<TrackerInfo>.from(filtered);
    result.sort((a, b) {
      final comparison = switch (_order) {
        // Clash Party calls this "asc": newest first.
        _ConnectionOrder.time => b.start.compareTo(a.start),
        _ConnectionOrder.upload => a.upload.compareTo(b.upload),
        _ConnectionOrder.download => a.download.compareTo(b.download),
        _ConnectionOrder.uploadSpeed =>
          (a.uploadSpeed ?? 0).compareTo(b.uploadSpeed ?? 0),
        _ConnectionOrder.downloadSpeed =>
          (a.downloadSpeed ?? 0).compareTo(b.downloadSpeed ?? 0),
      };
      return _ascending ? comparison : -comparison;
    });
    return result;
  }

  Future<void> _closeConnection(String id) async {
    await _core.closeConnection(id);
    await _refreshConnections();
  }

  Future<void> _closeVisible(List<TrackerInfo> visible) async {
    if (_tab == _ConnectionTab.closed) {
      setState(() {
        final ids = visible.map((item) => item.id).toSet();
        _closedConnections = _closedConnections
            .where((item) => !ids.contains(item.id))
            .toList(growable: false);
        _cachedClosedConnections = List.unmodifiable(_closedConnections);
      });
      return;
    }

    final filtering = _query.trim().isNotEmpty || _keywords.isNotEmpty;
    if (!filtering) {
      await _core.closeConnections();
      await _refreshConnections();
      return;
    }
    await Future.wait([
      for (final connection in visible) _core.closeConnection(connection.id),
    ]);
    await _refreshConnections();
  }

  void _removeClosed(String id) {
    setState(() {
      _closedConnections = _closedConnections
          .where((item) => item.id != id)
          .toList(growable: false);
      _cachedClosedConnections = List.unmodifiable(_closedConnections);
    });
  }

  String _orderLabel(_ConnectionOrder order) => switch (order) {
    _ConnectionOrder.time => _text('时间', 'Time'),
    _ConnectionOrder.upload => _text('上传总量', 'Upload amount'),
    _ConnectionOrder.download => _text('下载总量', 'Download amount'),
    _ConnectionOrder.uploadSpeed => _text('上传速度', 'Upload speed'),
    _ConnectionOrder.downloadSpeed => _text('下载速度', 'Download speed'),
  };

  Widget _buildToolbar(List<TrackerInfo> visible) {
    final activeTraffic = Traffic(
      up: _activeConnections.fold<int>(
        0,
        (sum, item) => sum + item.upload,
      ),
      down: _activeConnections.fold<int>(
        0,
        (sum, item) => sum + item.download,
      ),
    );

    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 230,
                  child: GlassSegmented<_ConnectionTab>(
                    height: 36,
                    values: _ConnectionTab.values,
                    selected: _tab,
                    labelOf: (tab) => switch (tab) {
                      _ConnectionTab.active =>
                        '${_text('活动', 'Active')} '
                            '(${_activeConnections.length})',
                      _ConnectionTab.closed =>
                        '${_text('已关闭', 'Closed')} '
                            '(${_closedConnections.length})',
                    },
                    selectedColor: _tab == _ConnectionTab.active
                        ? context.colorScheme.primary
                        : context.colorScheme.error,
                    selectedForegroundColor: _tab == _ConnectionTab.active
                        ? context.colorScheme.onPrimary
                        : context.colorScheme.onError,
                    onChanged: (tab) => setState(() => _tab = tab),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 190),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<_ConnectionOrder>(
                      value: _order,
                      isDense: true,
                      isExpanded: true,
                      items: [
                        for (final order in _ConnectionOrder.values)
                          DropdownMenuItem(
                            value: order,
                            child: Text(
                              _orderLabel(order),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _order = value);
                      },
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _ascending
                      ? _text('切换为降序', 'Sort descending')
                      : _text('切换为升序', 'Sort ascending'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _ascending = !_ascending),
                  icon: Icon(
                    _ascending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                  ),
                ),
                if (_tab == _ConnectionTab.active)
                  Text(
                    '↑ ${activeTraffic.up.traffic.show}   '
                    '↓ ${activeTraffic.down.traffic.show}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                Badge(
                  label: Text('${visible.length}'),
                  child: IconButton(
                    tooltip: _tab == _ConnectionTab.active
                        ? _text('关闭当前结果', 'Close matching connections')
                        : _text('删除当前记录', 'Delete matching records'),
                    visualDensity: VisualDensity.compact,
                    onPressed: visible.isEmpty
                        ? null
                        : () => unawaited(_closeVisible(visible)),
                    icon: Icon(
                      _tab == _ConnectionTab.active
                          ? Icons.close_rounded
                          : Icons.delete_outline_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
        ],
      ),
    );
  }

  Widget _trailingFor(TrackerInfo connection) {
    final uploadSpeed = connection.uploadSpeed ?? 0;
    final downloadSpeed = connection.downloadSpeed ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_tab == _ConnectionTab.active)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 118),
            child: Text(
              '↑ ${uploadSpeed.traffic.show}/s\n'
              '↓ ${downloadSpeed.traffic.show}/s',
              textAlign: TextAlign.end,
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: _tab == _ConnectionTab.active
              ? _text('断开连接', 'Close connection')
              : _text('删除记录', 'Delete record'),
          visualDensity: VisualDensity.compact,
          icon: Icon(
            _tab == _ConnectionTab.active
                ? Icons.close_rounded
                : Icons.delete_outline_rounded,
            size: 20,
          ),
          onPressed: () {
            if (_tab == _ConnectionTab.active) {
              unawaited(_closeConnection(connection.id));
            } else {
              _removeClosed(connection.id);
            }
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    coreEventManager.removeListener(this);
    _requestRefreshTimer?.cancel();
    _cachedClosedConnections = List.unmodifiable(_closedConnections);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final visible = _visibleConnections();

    return CommonScaffold(
      title: appLocalizations.connections,
      searchState: AppBarSearchState(
        onSearch: (query) => setState(() => _query = query),
      ),
      onKeywordsUpdate: (keywords) => setState(() => _keywords = keywords),
      body: Column(
        children: [
          _buildToolbar(visible),
          Expanded(
            child: NullStatusSwitcher(
              isEmpty: visible.isEmpty,
              nullStatus: NullStatus(
                label: _query.trim().isNotEmpty || _keywords.isNotEmpty
                    ? _text('没有匹配的连接', 'No matching connections')
                    : _tab == _ConnectionTab.active
                    ? _text('暂无活动连接', 'No active connections')
                    : _text('暂无已关闭连接', 'No closed connections'),
                illustration: NullStatusIllustration.connections,
              ),
              child: TrackerInfoList(
                controller: _scrollController,
                trackerInfos: visible,
                detailTitle: appLocalizations.details(
                  appLocalizations.connection,
                ),
                padding: EdgeInsets.only(
                  bottom: 16 + BottomInsetScope.of(context),
                ),
                trailingBuilder: _trailingFor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
