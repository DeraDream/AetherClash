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

enum _ConnectionColumn {
  status,
  establishTime,
  connectionType,
  host,
  process,
  rule,
  proxyChain,
  uploadSpeed,
  downloadSpeed,
  upload,
  download,
  remoteDestination,
}

class _ColumnSpec {
  final _ConnectionColumn column;
  final double width;

  const _ColumnSpec(this.column, this.width);
}

const _connectionColumns = <_ColumnSpec>[
  _ColumnSpec(_ConnectionColumn.status, 88),
  _ColumnSpec(_ConnectionColumn.establishTime, 126),
  _ColumnSpec(_ConnectionColumn.connectionType, 112),
  _ColumnSpec(_ConnectionColumn.host, 220),
  _ColumnSpec(_ConnectionColumn.process, 160),
  _ColumnSpec(_ConnectionColumn.rule, 190),
  _ColumnSpec(_ConnectionColumn.proxyChain, 240),
  _ColumnSpec(_ConnectionColumn.uploadSpeed, 118),
  _ColumnSpec(_ConnectionColumn.downloadSpeed, 118),
  _ColumnSpec(_ConnectionColumn.upload, 108),
  _ColumnSpec(_ConnectionColumn.download, 108),
  _ColumnSpec(_ConnectionColumn.remoteDestination, 220),
];

const _actionColumnWidth = 52.0;
const _minimumColumnWidth = 64.0;

// Match Clash Party's page-level cache: recently closed entries remain when
// the user leaves Activity and comes back, but never grow without bounds.
List<TrackerInfo> _cachedClosedConnections = const [];
String _cachedConnectionFilter = '';
_ConnectionColumn _cachedSortColumn = _ConnectionColumn.establishTime;
bool _cachedSortDescending = true;
Set<_ConnectionColumn> _cachedVisibleColumns = {
  for (final spec in _connectionColumns) spec.column,
};
Map<_ConnectionColumn, double> _cachedColumnWidths = {};

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

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  late final TextEditingController _filterController;
  final Map<String, TrackerInfo> _previousActive = {};
  late final Map<_ConnectionColumn, double> _columnWidths;
  late final Set<_ConnectionColumn> _visibleColumns;

  List<TrackerInfo> _activeConnections = const [];
  List<TrackerInfo> _closedConnections = List.of(_cachedClosedConnections);
  _ConnectionTab _tab = _ConnectionTab.active;
  _ConnectionColumn _sortColumn = _cachedSortColumn;
  bool _sortDescending = _cachedSortDescending;
  bool _trackingPaused = false;
  bool _resetSpeedBaseline = false;
  String _query = _cachedConnectionFilter;
  DateTime? _lastSnapshotAt;
  Timer? _requestRefreshTimer;

  @override
  Duration get pollInterval => const Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _filterController = TextEditingController(text: _query);
    _columnWidths = Map.of(_cachedColumnWidths);
    _visibleColumns = Set.of(_cachedVisibleColumns);
    coreEventManager.addListener(this);
  }

  @override
  void onRequest(TrackerInfo connection) {
    if (_trackingPaused) return;
    // Core request events wake the snapshot immediately. The 500 ms polling
    // remains responsible for speed deltas and closed-connection detection.
    _requestRefreshTimer ??= Timer(const Duration(milliseconds: 80), () {
      _requestRefreshTimer = null;
      if (mounted && !_trackingPaused) {
        unawaited(_refreshConnections());
      }
    });
  }

  String _text(String zh, String en) {
    return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  }

  @override
  Future<void> poll(PollGuard isCurrent) async {
    if (_trackingPaused) return;
    final trackerInfos = await _readConnections();
    if (trackerInfos == null || !isCurrent() || _trackingPaused) {
      return;
    }
    _applyConnections(trackerInfos);
  }

  Future<void> _refreshConnections() async {
    if (_trackingPaused) return;
    final trackerInfos = await _readConnections();
    if (trackerInfos == null || !mounted || _trackingPaused) {
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
      final downloadDelta = previous == null || _resetSpeedBaseline
          ? 0
          : (current.download - previous.download).clamp(0, 1 << 62);
      final uploadDelta = previous == null || _resetSpeedBaseline
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
      closed.removeWhere((item) => item.id == current.id);
    }

    if (closed.length > 200) {
      closed.removeRange(200, closed.length);
    }

    _previousActive
      ..clear()
      ..addAll(nextPrevious);
    _resetSpeedBaseline = false;
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
    final result = source
        .where(
          (connection) =>
              query.isEmpty || _searchBlob(connection).contains(query),
        )
        .toList(growable: false);

    result.sort((a, b) {
      final comparison = _compareByColumn(a, b, _sortColumn);
      if (comparison == 0) {
        return _sortDescending
            ? b.id.compareTo(a.id)
            : a.id.compareTo(b.id);
      }
      return _sortDescending ? -comparison : comparison;
    });
    return result;
  }

  int _compareByColumn(
    TrackerInfo a,
    TrackerInfo b,
    _ConnectionColumn column,
  ) {
    switch (column) {
      case _ConnectionColumn.status:
        final aStatus = _tab == _ConnectionTab.active ? 1 : 0;
        final bStatus = _tab == _ConnectionTab.active ? 1 : 0;
        return aStatus.compareTo(bStatus);
      case _ConnectionColumn.establishTime:
        return a.start.compareTo(b.start);
      case _ConnectionColumn.connectionType:
        return a.metadata.network.toLowerCase().compareTo(
          b.metadata.network.toLowerCase(),
        );
      case _ConnectionColumn.host:
        return _hostText(a).toLowerCase().compareTo(_hostText(b).toLowerCase());
      case _ConnectionColumn.process:
        return a.metadata.process.toLowerCase().compareTo(
          b.metadata.process.toLowerCase(),
        );
      case _ConnectionColumn.rule:
        return _ruleText(a).toLowerCase().compareTo(_ruleText(b).toLowerCase());
      case _ConnectionColumn.proxyChain:
        return _proxyChainText(a).toLowerCase().compareTo(
          _proxyChainText(b).toLowerCase(),
        );
      case _ConnectionColumn.uploadSpeed:
        return (a.uploadSpeed ?? 0).compareTo(b.uploadSpeed ?? 0);
      case _ConnectionColumn.downloadSpeed:
        return (a.downloadSpeed ?? 0).compareTo(b.downloadSpeed ?? 0);
      case _ConnectionColumn.upload:
        return a.upload.compareTo(b.upload);
      case _ConnectionColumn.download:
        return a.download.compareTo(b.download);
      case _ConnectionColumn.remoteDestination:
        return _remoteDestinationText(a).toLowerCase().compareTo(
          _remoteDestinationText(b).toLowerCase(),
        );
    }
  }

  String _hostText(TrackerInfo connection) {
    final host = connection.metadata.host;
    return host.isNotEmpty ? host : connection.metadata.destinationIP;
  }

  String _ruleText(TrackerInfo connection) {
    final payload = connection.rulePayload;
    return payload.isEmpty ? connection.rule : '${connection.rule}($payload)';
  }

  String _proxyChainText(TrackerInfo connection) {
    return connection.chains.reversed.join(' → ');
  }

  String _remoteDestinationText(TrackerInfo connection) {
    final metadata = connection.metadata;
    if (metadata.remoteDestination.isNotEmpty) {
      return metadata.remoteDestination;
    }
    if (metadata.destinationIP.isEmpty) return '-';
    if (metadata.destinationPort.isEmpty) return metadata.destinationIP;
    return '${metadata.destinationIP}:${metadata.destinationPort}';
  }

  void _sortBy(_ConnectionColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortDescending = !_sortDescending;
      } else {
        _sortColumn = column;
        // User-requested Clash Party behavior: every newly selected column
        // starts high-to-low, then a second click toggles to ascending.
        _sortDescending = true;
      }
      _cachedSortColumn = _sortColumn;
      _cachedSortDescending = _sortDescending;
    });
  }

  void _toggleTracking() {
    final resume = _trackingPaused;
    setState(() => _trackingPaused = !_trackingPaused);
    _requestRefreshTimer?.cancel();
    _requestRefreshTimer = null;
    if (resume) {
      // A long pause must not be interpreted as one giant 500 ms speed delta.
      _resetSpeedBaseline = true;
      _lastSnapshotAt = null;
      // ActivePollingMixin polls immediately on start, so this both resumes
      // the 500 ms loop and refreshes the current snapshot once.
      restartPolling();
    } else {
      // Match Clash Party unsubscribe behavior: pause means no background
      // connection snapshots are read until the user resumes tracking.
      stopPolling();
    }
  }

  Future<void> _closeConnection(String id) async {
    await _core.closeConnection(id);
    if (!_trackingPaused) {
      await _refreshConnections();
    }
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

    if (_query.trim().isEmpty) {
      await _core.closeConnections();
      if (!_trackingPaused) {
        await _refreshConnections();
      }
      return;
    }
    await Future.wait([
      for (final connection in visible) _core.closeConnection(connection.id),
    ]);
    if (!_trackingPaused) {
      await _refreshConnections();
    }
  }

  void _removeClosed(String id) {
    setState(() {
      _closedConnections = _closedConnections
          .where((item) => item.id != id)
          .toList(growable: false);
      _cachedClosedConnections = List.unmodifiable(_closedConnections);
    });
  }

  String _columnLabel(_ConnectionColumn column) => switch (column) {
    _ConnectionColumn.status => _text('状态', 'Status'),
    _ConnectionColumn.establishTime => _text('连接建立时间', 'Established'),
    _ConnectionColumn.connectionType => _text('连接类型', 'Type'),
    _ConnectionColumn.host => _text('主机', 'Host'),
    _ConnectionColumn.process => _text('进程名', 'Process'),
    _ConnectionColumn.rule => _text('规则', 'Rule'),
    _ConnectionColumn.proxyChain => _text('代理链', 'Proxy chain'),
    _ConnectionColumn.uploadSpeed => _text('上传速度', 'Upload speed'),
    _ConnectionColumn.downloadSpeed => _text('下载速度', 'Download speed'),
    _ConnectionColumn.upload => _text('上传量', 'Upload'),
    _ConnectionColumn.download => _text('下载量', 'Download'),
    _ConnectionColumn.remoteDestination => _text('远程目标', 'Remote target'),
  };

  String _cellText(TrackerInfo connection, _ConnectionColumn column) {
    final metadata = connection.metadata;
    return switch (column) {
      _ConnectionColumn.status => _tab == _ConnectionTab.active
          ? _text('活动中', 'Active')
          : _text('已关闭', 'Closed'),
      _ConnectionColumn.establishTime =>
        connection.start.getLastUpdateTimeDesc(context),
      _ConnectionColumn.connectionType => metadata.network.toUpperCase(),
      _ConnectionColumn.host => _hostText(connection),
      _ConnectionColumn.process => metadata.process.isEmpty ? '-' : metadata.process,
      _ConnectionColumn.rule => _ruleText(connection),
      _ConnectionColumn.proxyChain =>
        _proxyChainText(connection).isEmpty ? '-' : _proxyChainText(connection),
      _ConnectionColumn.uploadSpeed =>
        '${(connection.uploadSpeed ?? 0).traffic.show}/s',
      _ConnectionColumn.downloadSpeed =>
        '${(connection.downloadSpeed ?? 0).traffic.show}/s',
      _ConnectionColumn.upload => connection.upload.traffic.show,
      _ConnectionColumn.download => connection.download.traffic.show,
      _ConnectionColumn.remoteDestination => _remoteDestinationText(connection),
    };
  }

  bool _numericColumn(_ConnectionColumn column) {
    return column == _ConnectionColumn.uploadSpeed ||
        column == _ConnectionColumn.downloadSpeed ||
        column == _ConnectionColumn.upload ||
        column == _ConnectionColumn.download;
  }

  Widget _buildTabButton(_ConnectionTab tab) {
    final selected = _tab == tab;
    final count = tab == _ConnectionTab.active
        ? _activeConnections.length
        : _closedConnections.length;
    final color = tab == _ConnectionTab.active
        ? context.colorScheme.primary
        : context.colorScheme.error;
    final glass = context.glass;
    final label = tab == _ConnectionTab.active
        ? _text('活动中', 'Active')
        : _text('已关闭', 'Closed');
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => setState(() => _tab = tab),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 2,
              color: selected ? color : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.textTheme.labelLarge?.copyWith(
                color: selected ? color : context.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : null,
              ),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 18),
              child: Container(
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.12)
                      : glass.fill.withValues(alpha: 0.62),
                  borderRadius: AppRadius.full,
                ),
                child: Text(
                  '$count',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: selected
                        ? color
                        : context.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _columnWidth(_ColumnSpec spec) {
    return _columnWidths[spec.column] ?? spec.width;
  }

  void _toggleColumn(_ConnectionColumn column) {
    setState(() {
      if (_visibleColumns.contains(column)) {
        // Keep at least one data column visible.
        if (_visibleColumns.length > 1) {
          _visibleColumns.remove(column);
        }
      } else {
        _visibleColumns.add(column);
      }
      _cachedVisibleColumns = Set.of(_visibleColumns);
    });
  }

  Widget _buildColumnPicker() {
    return PopupMenuButton<_ConnectionColumn>(
      tooltip: _text('显示列', 'Columns'),
      onSelected: _toggleColumn,
      itemBuilder: (_) => [
        for (final spec in _connectionColumns)
          PopupMenuItem<_ConnectionColumn>(
            value: spec.column,
            child: Row(
              children: [
                Icon(
                  _visibleColumns.contains(spec.column)
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(_columnLabel(spec.column)),
              ],
            ),
          ),
      ],
      child: Container(
        key: const Key('connections-columns'),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, size: 18),
            const SizedBox(width: 6),
            Text(_text('显示列', 'Columns')),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: context.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          _buildTabButton(_ConnectionTab.active),
          const SizedBox(width: 4),
          _buildTabButton(_ConnectionTab.closed),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 34,
              child: TextField(
                key: const Key('connections-filter'),
                controller: _filterController,
                onChanged: (value) {
                  _cachedConnectionFilter = value;
                  setState(() => _query = value);
                },
                decoration: InputDecoration(
                  hintText: _text('搜索连接', 'Search connections'),
                  prefixIcon: const Icon(Icons.search_rounded, size: 19),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: _text('清除搜索', 'Clear search'),
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            _filterController.clear();
                            _cachedConnectionFilter = '';
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                  filled: true,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildColumnPicker(),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(_ColumnSpec spec) {
    final active = _sortColumn == spec.column;
    final arrow = _sortDescending ? '↓' : '↑';
    final width = _columnWidth(spec);
    return SizedBox(
      width: width,
      height: 38,
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              key: Key('connection-header-${spec.column.name}'),
              onTap: () => _sortBy(spec.column),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Align(
                  alignment: _numericColumn(spec.column)
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Text(
                    '${_columnLabel(spec.column)}${active ? ' $arrow' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: active
                          ? context.colorScheme.onSurface
                          : context.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 8,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _columnWidths[spec.column] =
                        (width + details.delta.dx).clamp(
                          _minimumColumnWidth,
                          520.0,
                        ).toDouble();
                    _cachedColumnWidths = Map.of(_columnWidths);
                  });
                },
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 1,
                    color: context.colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCell(TrackerInfo connection, _ColumnSpec spec) {
    if (spec.column == _ConnectionColumn.status) {
      final active = _tab == _ConnectionTab.active;
      final color = active ? context.colorScheme.primary : context.colorScheme.error;
      return SizedBox(
        width: _columnWidth(spec),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _cellText(connection, spec.column),
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final value = _cellText(connection, spec.column);
    return SizedBox(
      width: _columnWidth(spec),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Align(
          alignment: _numericColumn(spec.column)
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Tooltip(
            message: value,
            waitDuration: const Duration(milliseconds: 500),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall,
            ),
          ),
        ),
      ),
    );
  }

  void _openDetails(TrackerInfo connection) {
    showExtend(
      context,
      builder: (_) => AdaptiveSheetScaffold(
        sheetTransparentToolBar: true,
        body: TrackerInfoDetailView(trackerInfo: connection),
        title: context.appLocalizations.details(context.appLocalizations.connection),
      ),
    );
  }

  Widget _buildRow(TrackerInfo connection) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetails(connection),
        child: Container(
          key: Key('connection-row-${connection.id}'),
          height: 44,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: context.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              for (final spec in _connectionColumns)
                if (_visibleColumns.contains(spec.column))
                  _buildDataCell(connection, spec),
              SizedBox(
                width: _actionColumnWidth,
                child: IconButton(
                  tooltip: _tab == _ConnectionTab.active
                      ? _text('断开连接', 'Close connection')
                      : _text('删除记录', 'Delete record'),
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: () {
                    if (_tab == _ConnectionTab.active) {
                      unawaited(_closeConnection(connection.id));
                    } else {
                      _removeClosed(connection.id);
                    }
                  },
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
      ),
    );
  }

  Widget _buildTable(List<TrackerInfo> visible) {
    final columns = _connectionColumns
        .where((spec) => _visibleColumns.contains(spec.column))
        .toList(growable: false);
    final tableWidth = columns.fold<double>(
      _actionColumnWidth,
      (sum, spec) => sum + _columnWidth(spec),
    );
    return LayoutBuilder(
      builder: (_, constraints) {
        final contentWidth = tableWidth > constraints.maxWidth
            ? tableWidth
            : constraints.maxWidth;
        final table = Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: contentWidth,
              height: constraints.maxHeight,
              child: Column(
                children: [
                  Container(
                    height: 39,
                    color: context.colorScheme.surfaceContainer,
                    child: Row(
                      children: [
                        for (final spec in columns) _buildHeaderCell(spec),
                        const SizedBox(width: _actionColumnWidth),
                      ],
                    ),
                  ),
                  Expanded(
                    child: visible.isEmpty
                        ? const SizedBox.shrink()
                        : ListView.builder(
                            controller: _verticalController,
                            padding: EdgeInsets.only(
                              bottom: 16 + BottomInsetScope.of(context),
                            ),
                            itemCount: visible.length,
                            itemBuilder: (_, index) => _buildRow(visible[index]),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (visible.isNotEmpty) {
          return table;
        }

        final emptyLabel = _query.trim().isNotEmpty
            ? _text('没有匹配的连接', 'No matching connections')
            : _tab == _ConnectionTab.active
            ? _text('暂无活动连接', 'No active connections')
            : _text('暂无已关闭连接', 'No closed connections');

        // Keep the empty illustration centered in the visible table viewport,
        // not in the much wider horizontally-scrollable table content.
        return Stack(
          children: [
            Positioned.fill(child: table),
            Positioned(
              left: 0,
              right: 0,
              top: 39,
              bottom: 0,
              child: IgnorePointer(
                child: NullStatus(
                  label: emptyLabel,
                  illustration: NullStatusIllustration.connections,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    coreEventManager.removeListener(this);
    _requestRefreshTimer?.cancel();
    _cachedClosedConnections = List.unmodifiable(_closedConnections);
    _verticalController.dispose();
    _horizontalController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final visible = _visibleConnections();
    final activeTraffic = Traffic(
      up: _activeConnections.fold<int>(0, (sum, item) => sum + item.upload),
      down: _activeConnections.fold<int>(0, (sum, item) => sum + item.download),
    );

    return CommonScaffold(
      title: appLocalizations.connections,
      actions: [
        if (_tab == _ConnectionTab.active)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: Text(
                '↑ ${activeTraffic.up.traffic.show}  ↓ ${activeTraffic.down.traffic.show}',
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        IconButton(
          key: const Key('connections-pause'),
          tooltip: _trackingPaused
              ? _text('继续实时追踪', 'Resume live tracking')
              : _text('暂停实时追踪', 'Pause live tracking'),
          onPressed: _toggleTracking,
          icon: Icon(
            _trackingPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          ),
        ),
        Badge(
          label: Text('${visible.length}'),
          child: IconButton(
            key: const Key('connections-clear'),
            tooltip: _tab == _ConnectionTab.active
                ? _text('清除当前连接', 'Close current connections')
                : _text('清除已关闭记录', 'Clear closed history'),
            onPressed: visible.isEmpty ? null : () => unawaited(_closeVisible(visible)),
            icon: Icon(
              _tab == _ConnectionTab.active
                  ? Icons.close_rounded
                  : Icons.delete_outline_rounded,
            ),
          ),
        ),
      ],
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildTable(visible)),
        ],
      ),
    );
  }
}
