import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/network_topology.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class NetworkInfoView extends ConsumerStatefulWidget {
  const NetworkInfoView({super.key});

  @override
  ConsumerState<NetworkInfoView> createState() => _NetworkInfoViewState();
}

class _NetworkInfoViewState extends ConsumerState<NetworkInfoView> {
  static const _autoSource = '__auto__';

  static const _defaultTargets = <_LatencyTarget>[
    _LatencyTarget(
      label: 'Google',
      url: 'https://www.gstatic.com/generate_204',
    ),
    _LatencyTarget(
      label: 'Cloudflare',
      url: 'https://cp.cloudflare.com/generate_204',
    ),
    _LatencyTarget(label: 'GitHub', url: 'https://github.com/robots.txt'),
  ];

  List<_LatencyTarget> _targets = List<_LatencyTarget>.from(_defaultTargets);
  final Map<String, int?> _latencies = {};
  Map<String, dynamic>? _ipDetails;
  bool _ipDetailsLoading = false;
  String _selectedIpSource = _autoSource;
  IpInfo? _sourceIpInfo;
  bool _sourceIpLoading = false;
  bool _testing = false;
  int _ipCheckVersion = 0;
  int _testVersion = 0;
  String _latencyRouteSignature = '';

  List<SpeedTestServer> _speedServers = const [];
  String? _selectedSpeedServerId;
  String _speedContextSignature = '';
  String? _speedProxyName;
  int _speedContextVersion = 0;
  bool _speedServersLoading = false;
  bool _speedTesting = false;
  SpeedTestPhase? _speedPhase;
  double _speedLiveMbps = 0;
  double? _speedDownloadMbps;
  double? _speedUploadMbps;
  String? _speedError;
  SpeedTestEngine? _speedEngine;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(networkDetectionProvider.notifier).startCheck();
      unawaited(_refreshIpDetails());
      unawaited(_loadLatencyTargets());
    });
  }

  @override
  void dispose() {
    _speedEngine?.cancel();
    super.dispose();
  }

  Group? _leadingGroup(
    List<Group> groups,
    String? preferredGroupName,
  ) {
    if (preferredGroupName != null) {
      for (final group in groups) {
        if (group.name == preferredGroupName) {
          return group;
        }
      }
    }
    return groups.isEmpty ? null : groups.first;
  }

  String? _readCurrentProxyName() {
    final mode = ref.read(patchClashConfigProvider).mode;
    if (mode == Mode.direct) {
      return 'DIRECT';
    }
    final visibleGroups = ref.read(currentGroupsStateProvider).value;
    final preferred = ref.read(currentProfileProvider)?.currentGroupName;
    final visibleGroup = _leadingGroup(visibleGroups, preferred);
    if (visibleGroup == null) return null;

    final group =
        ref.read(groupsProvider).getGroup(visibleGroup.name) ?? visibleGroup;
    final selected = ref.read(selectedProxyNameProvider(group.name));
    final rawName = selected?.isNotEmpty == true
        ? selected
        : (group.realNow.isEmpty ? null : group.realNow);
    if (rawName == null || rawName.isEmpty) return null;

    final resolved = ref.read(realSelectedProxyStateProvider(rawName));
    return resolved.proxyName.isEmpty ? rawName : resolved.proxyName;
  }

  void _syncLatencyRoute({
    required String signature,
  }) {
    if (signature == _latencyRouteSignature) return;
    _latencyRouteSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || signature != _latencyRouteSignature) return;
      unawaited(_refreshLatency());
    });
  }

  void _syncSpeedTestContext({
    required String signature,
    required String? proxyName,
  }) {
    if (signature == _speedContextSignature) return;
    _speedContextSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || signature != _speedContextSignature) return;
      unawaited(
        _reloadSpeedTestServers(
          proxyName: proxyName,
          signature: signature,
        ),
      );
    });
  }

  Future<void> _reloadSpeedTestServers({
    required String? proxyName,
    required String signature,
  }) async {
    final version = ++_speedContextVersion;
    _speedEngine?.cancel();

    if (mounted) {
      setState(() {
        _speedServersLoading = true;
        _speedTesting = false;
        _speedPhase = null;
        _speedLiveMbps = 0;
        _speedDownloadMbps = null;
        _speedUploadMbps = null;
        _speedError = null;
        _speedServers = const [];
        _selectedSpeedServerId = null;
        _speedProxyName = proxyName;
      });
    }

    if (proxyName == null || proxyName.isEmpty) {
      if (mounted && version == _speedContextVersion) {
        setState(() => _speedServersLoading = false);
      }
      return;
    }

    try {
      final core = ref.read(coreHandlerProvider);
      await core.changeProxy(
        ChangeProxyParams(
          groupName: speedTestGroupName,
          proxyName: proxyName,
        ),
      );

      final mixedPort = ref.read(patchClashConfigProvider).mixedPort;
      final engine = SpeedTestEngine(
        proxyPort: speedTestListenerPortFor(mixedPort),
      );
      _speedEngine = engine;
      final servers = await engine.fetchServers(
        limit: 24,
        latencyCandidates: 10,
      );

      if (!mounted ||
          version != _speedContextVersion ||
          signature != _speedContextSignature) {
        engine.cancel();
        return;
      }
      setState(() {
        _speedServers = servers;
        _selectedSpeedServerId = servers.isEmpty ? null : servers.first.id;
        _speedServersLoading = false;
        if (servers.isEmpty) {
          _speedError = _text(
            context,
            '未获取到可用的 Speedtest 测速节点',
            'No available Speedtest servers were found.',
          );
        }
      });
    } catch (error) {
      if (!mounted ||
          version != _speedContextVersion ||
          signature != _speedContextSignature) {
        return;
      }
      setState(() {
        _speedServersLoading = false;
        _speedError = compactError(error);
      });
    }
  }

  SpeedTestServer? get _selectedSpeedServer {
    final id = _selectedSpeedServerId;
    if (id == null) return null;
    for (final server in _speedServers) {
      if (server.id == id) return server;
    }
    return null;
  }

  void _stopSpeedTest() {
    _speedEngine?.cancel();
  }

  Future<void> _runSpeedTest() async {
    final server = _selectedSpeedServer;
    final proxyName = _speedProxyName ?? _readCurrentProxyName();
    if (server == null ||
        proxyName == null ||
        proxyName.isEmpty ||
        _speedTesting) {
      return;
    }

    final mixedPort = ref.read(patchClashConfigProvider).mixedPort;
    final core = ref.read(coreHandlerProvider);
    final engine = SpeedTestEngine(
      proxyPort: speedTestListenerPortFor(mixedPort),
    );
    _speedEngine?.cancel();
    _speedEngine = engine;

    setState(() {
      _speedTesting = true;
      _speedPhase = SpeedTestPhase.download;
      _speedLiveMbps = 0;
      _speedDownloadMbps = null;
      _speedUploadMbps = null;
      _speedError = null;
    });

    try {
      // Reassert the current app-selected proxy immediately before the test.
      // The user selects a Speedtest server in the UI; this hidden selector is
      // only the transport route and never changes the user's real group.
      await core.changeProxy(
        ChangeProxyParams(
          groupName: speedTestGroupName,
          proxyName: proxyName,
        ),
      );

      final result = await engine.run(
        server: server,
        downloadDuration: const Duration(seconds: 15),
        uploadDuration: const Duration(seconds: 15),
        onProgress: (progress) {
          if (!mounted || !identical(_speedEngine, engine)) return;
          final previousPhase = _speedPhase;
          final previousLiveMbps = _speedLiveMbps;
          setState(() {
            if (progress.phase == SpeedTestPhase.upload &&
                previousPhase == SpeedTestPhase.download &&
                _speedDownloadMbps == null &&
                previousLiveMbps > 0) {
              _speedDownloadMbps = previousLiveMbps;
            }
            _speedPhase = progress.phase;
            _speedLiveMbps = progress.mbps;
          });
        },
      );

      if (!mounted || !identical(_speedEngine, engine)) return;
      setState(() {
        _speedDownloadMbps = result.downloadMbps;
        _speedUploadMbps = result.uploadMbps;
        _speedLiveMbps = result.uploadMbps;
      });
    } on SpeedTestCancelled {
      // User stop / proxy-context refresh: keep any completed direction.
    } catch (error) {
      if (!mounted || !identical(_speedEngine, engine)) return;
      setState(() => _speedError = compactError(error));
    } finally {
      if (mounted && identical(_speedEngine, engine)) {
        setState(() {
          _speedTesting = false;
          _speedPhase = null;
        });
      }
    }
  }

  Future<void> _refreshIp() async {
    final auto = _selectedIpSource == _autoSource;
    if (auto) {
      ref.read(networkDetectionProvider.notifier).startCheck();
      unawaited(_refreshIpDetails());
      return;
    }

    final version = ++_ipCheckVersion;
    setState(() {
      _sourceIpLoading = true;
      _ipDetailsLoading = true;
    });
    final results = await (
      request.checkIp(sourceUrl: _selectedIpSource),
      request.checkIpDetails(sourceUrl: _selectedIpSource),
    ).wait;
    if (!mounted || version != _ipCheckVersion) return;
    setState(() {
      _sourceIpInfo = results.$1.data;
      _sourceIpLoading = false;
      _ipDetails = results.$2.data;
      _ipDetailsLoading = false;
    });
  }

  Future<void> _refreshIpDetails() async {
    final source = _selectedIpSource == _autoSource
        ? null
        : _selectedIpSource;
    if (mounted) {
      setState(() => _ipDetailsLoading = true);
    }
    final result = await request.checkIpDetails(sourceUrl: source);
    if (!mounted) return;
    setState(() {
      _ipDetails = result.data;
      _ipDetailsLoading = false;
    });
  }

  Future<void> _loadLatencyTargets() async {
    final saved = await preferences.getNetworkLatencyTargets();
    if (!mounted) return;
    final parsed = saved
        .map(
          (item) => _LatencyTarget(
            label: item['label']?.trim() ?? '',
            url: item['url']?.trim() ?? '',
          ),
        )
        .where((item) => item.label.isNotEmpty && item.url.isNotEmpty)
        .toList(growable: false);
    setState(() {
      _targets = parsed.isEmpty
          ? List<_LatencyTarget>.from(_defaultTargets)
          : parsed;
    });
    await _refreshLatency();
  }

  Future<void> _editLatencyTargets() async {
    final result = await dialogs.showCommonDialog<List<_LatencyTarget>>(
      child: _LatencyTargetsDialog(initial: _targets),
    );
    if (result == null || result.isEmpty || !mounted) return;
    setState(() {
      _targets = result;
      _latencies.clear();
    });
    await preferences.saveNetworkLatencyTargets([
      for (final target in result)
        {'label': target.label, 'url': target.url},
    ]);
    await _refreshLatency();
  }

  void _selectIpSource(String value) {
    if (value == _selectedIpSource) return;
    setState(() {
      _selectedIpSource = value;
      _sourceIpInfo = null;
      _ipDetails = null;
      _sourceIpLoading = value != _autoSource;
      _ipDetailsLoading = true;
    });
    unawaited(_refreshIp());
  }

  Future<void> _refreshLatency() async {
    final version = ++_testVersion;
    final proxyName = _readCurrentProxyName();
    if (mounted) {
      setState(() => _testing = true);
    }

    final core = ref.read(coreHandlerProvider);
    final results = await Future.wait(
      _targets.map((target) async {
        if (proxyName == null || proxyName.isEmpty) {
          final delay = await request.probeLatency(target.url);
          return (target.label, delay);
        }

        int? best;
        for (var attempt = 0; attempt < 2; attempt++) {
          final delay = await core.getDelay(target.url, proxyName);
          final value = delay?.value;
          if (value != null && value > 0 && (best == null || value < best)) {
            best = value;
          }
        }
        return (target.label, best);
      }),
    );
    if (!mounted || version != _testVersion) return;
    setState(() {
      for (final (label, delay) in results) {
        _latencies[label] = delay;
      }
      _testing = false;
    });
  }

  String _text(BuildContext context, String zh, String en) {
    return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  }

  String _sourceLabel(BuildContext context, String source) {
    if (source == _autoSource) {
      return _text(context, '自动', 'Auto');
    }
    return request.ipInfoSourceLabels[source] ?? source;
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final currentGroups = ref.watch(currentGroupsStateProvider).value;
    final preferredGroup = ref.watch(
      currentProfileProvider.select((state) => state?.currentGroupName),
    );
    final currentGroup = _leadingGroup(currentGroups, preferredGroup);
    final coreGroup = currentGroup == null
        ? null
        : ref.watch(
            groupsProvider.select(
              (groups) => groups.getGroup(currentGroup.name),
            ),
          );
    final selectedProxy = currentGroup == null
        ? null
        : ref.watch(selectedProxyNameProvider(currentGroup.name));
    final rawCurrentProxyName = selectedProxy?.isNotEmpty == true
        ? selectedProxy
        : coreGroup?.realNow;
    final currentProxyName = mode == Mode.direct
        ? 'DIRECT'
        : rawCurrentProxyName == null || rawCurrentProxyName.isEmpty
        ? null
        : ref.watch(
            realSelectedProxyStateProvider(rawCurrentProxyName).select(
              (state) => state.proxyName.isEmpty
                  ? rawCurrentProxyName
                  : state.proxyName,
            ),
          );
    final profileId = ref.watch(currentProfileIdProvider);
    final groupMembersSignature = (coreGroup ?? currentGroup)?.all
            .map((proxy) => proxy.name)
            .join('\u0000') ??
        '';
    final speedContextSignature =
        '$profileId|${mode.name}|${currentGroup?.name ?? ''}|'
        '${currentProxyName ?? ''}|$groupMembersSignature';
    _syncSpeedTestContext(
      signature: speedContextSignature,
      proxyName: currentProxyName,
    );
    _syncLatencyRoute(
      signature:
          '$profileId|${mode.name}|${currentGroup?.name ?? ''}|'
          '${currentProxyName ?? ''}',
    );

    final detection = ref.watch(networkDetectionProvider);
    final usingAutoSource = _selectedIpSource == _autoSource;
    final publicIp = usingAutoSource ? detection.ipInfo : _sourceIpInfo;
    final ipLoading = usingAutoSource
        ? detection.isLoading
        : _sourceIpLoading;

    return CommonScaffold(
      title: _text(context, '网络信息', 'Network info'),
      actions: [
        IconButton(
          tooltip: _text(context, '刷新全部', 'Refresh all'),
          onPressed: () {
            unawaited(_refreshIp());
            unawaited(_refreshLatency());
          },
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          18,
          12,
          18,
          24 + BottomInsetScope.of(context),
        ),
        children: [
          _SectionCard(
            title: _text(context, '当前 IP', 'Current IP'),
            icon: Icons.public_rounded,
            tone: GlassTone.accent,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IpSourceSelector(
                  selected: _selectedIpSource,
                  autoValue: _autoSource,
                  sourceLabels: request.ipInfoSourceLabels,
                  labelOf: (source) => _sourceLabel(context, source),
                  onChanged: _selectIpSource,
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: _text(context, '重新检测', 'Refresh IP'),
                  visualDensity: VisualDensity.compact,
                  onPressed: ipLoading ? null : _refreshIp,
                  icon: ipLoading
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CommonCircleLoading(),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                ),
              ],
            ),
            child: Column(
              children: [
                _IpRow(
                  ipInfo: publicIp,
                  loading: ipLoading,
                  onCopy: publicIp == null
                      ? null
                      : () => Clipboard.setData(
                            ClipboardData(text: publicIp.ip),
                          ),
                ),
                if (_ipDetailsLoading && _ipDetails == null) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(minHeight: 2),
                ],
                if (_ipDetails case final details?) ...[
                  const SizedBox(height: 12),
                  _IpDetailGrid(
                    details: _IpDetailData.fromRaw(details),
                    sourceLabel: _sourceLabel(
                      context,
                      details['_source']?.toString() ?? _selectedIpSource,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: _text(context, '网络拓扑', 'Network topology'),
            icon: Icons.hub_rounded,
            tone: GlassTone.success,
            child: const NetworkTopologyView(),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: _text(context, 'Speedtest 测速', 'Speedtest'),
            icon: Icons.speed_rounded,
            tone: GlassTone.teal,
            trailing: _SpeedTestServerSelector(
              servers: _speedServers,
              selectedId: _selectedSpeedServerId,
              loading: _speedServersLoading,
              enabled: !_speedTesting,
              onChanged: (value) {
                if (value == null || value == _selectedSpeedServerId) return;
                setState(() {
                  _selectedSpeedServerId = value;
                  _speedDownloadMbps = null;
                  _speedUploadMbps = null;
                  _speedLiveMbps = 0;
                            _speedError = null;
                });
              },
            ),
            child: _SpeedTestPanel(
              proxyName: currentProxyName,
              server: _selectedSpeedServer,
              serverLoading: _speedServersLoading,
              testing: _speedTesting,
              phase: _speedPhase,
              liveMbps: _speedLiveMbps,
              downloadMbps: _speedDownloadMbps,
              uploadMbps: _speedUploadMbps,
              error: _speedError,
              onStart: _selectedSpeedServer == null ||
                      _speedServersLoading ||
                      _speedTesting
                  ? null
                  : _runSpeedTest,
              onStop: _speedTesting ? _stopSpeedTest : null,
              text: (zh, en) => _text(context, zh, en),
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: _text(context, '网络延迟', 'Network latency'),
            icon: Icons.monitor_heart_rounded,
            tone: GlassTone.accent,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentProxyName != null &&
                    currentProxyName.isNotEmpty) ...[
                  _ProxyRoutePill(proxyName: currentProxyName),
                  const SizedBox(width: 4),
                ],
                _AverageDelayPill(values: _latencies.values),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: _text(context, '编辑检测目标', 'Edit targets'),
                  visualDensity: VisualDensity.compact,
                  onPressed: _editLatencyTargets,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                ),
                const SizedBox(width: 2),
                IconButton(
                  tooltip: _text(context, '重新测试', 'Retest'),
                  visualDensity: VisualDensity.compact,
                  onPressed: _testing ? null : _refreshLatency,
                  icon: _testing
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CommonCircleLoading(),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                ),
              ],
            ),
            child: Column(
              children: [
                for (final (index, target) in _targets.indexed) ...[
                  _LatencyRow(
                    label: target.label,
                    delay: _latencies[target.label],
                    loading: _testing && !_latencies.containsKey(target.label),
                  ),
                  if (index != _targets.length - 1)
                    const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IpSourceSelector extends StatelessWidget {
  const _IpSourceSelector({
    required this.selected,
    required this.autoValue,
    required this.sourceLabels,
    required this.labelOf,
    required this.onChanged,
  });

  final String selected;
  final String autoValue;
  final Map<String, String> sourceLabels;
  final String Function(String value) labelOf;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return PopupMenuButton<String>(
      initialValue: selected,
      tooltip: Localizations.localeOf(context).languageCode == 'zh'
          ? '选择 IP 来源'
          : 'Select IP source',
      onSelected: onChanged,
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: autoValue,
          child: _SourceMenuItem(
            label: labelOf(autoValue),
            selected: selected == autoValue,
          ),
        ),
        for (final entry in sourceLabels.entries)
          PopupMenuItem<String>(
            value: entry.key,
            child: _SourceMenuItem(
              label: entry.value,
              selected: selected == entry.key,
            ),
          ),
      ],
      child: Container(
        height: 34,
        constraints: const BoxConstraints(minWidth: 94),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: glass.fill.withValues(alpha: glass.isDark ? 0.78 : 0.88),
          borderRadius: AppRadius.all(9),
          border: Border.all(
            color: glass.separator.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              labelOf(selected),
              style: context.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: glass.secondaryLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceMenuItem extends StatelessWidget {
  const _SourceMenuItem({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        if (selected)
          Icon(
            Icons.check_rounded,
            size: 18,
            color: context.colorScheme.primary,
          ),
      ],
    );
  }
}

class _IpDetailData {
  const _IpDetailData({
    required this.country,
    required this.city,
    required this.asn,
    required this.organization,
  });

  factory _IpDetailData.fromRaw(Map<String, dynamic> raw) {
    String textOf(dynamic value) {
      if (value == null) return '';
      if (value is Map) {
        return (value['name'] ?? value['code'] ?? '').toString();
      }
      return value.toString();
    }

    final connection = raw['connection'] is Map
        ? Map<String, dynamic>.from(raw['connection'] as Map)
        : const <String, dynamic>{};
    final countryValue = raw['country'];
    final country = countryValue is Map
        ? textOf(countryValue['name'] ?? countryValue['code'])
        : textOf(countryValue);
    final asn = textOf(
      raw['asn'] ??
          connection['asn'] ??
          raw['as'] ??
          raw['asn_number'],
    );
    final organization = textOf(
      raw['org'] ??
          raw['organization'] ??
          connection['org'] ??
          connection['isp'] ??
          raw['isp'],
    );
    return _IpDetailData(
      country: country,
      city: textOf(raw['city']),
      asn: asn,
      organization: organization,
    );
  }

  final String country;
  final String city;
  final String asn;
  final String organization;
}

class _IpDetailGrid extends StatelessWidget {
  const _IpDetailGrid({
    required this.details,
    required this.sourceLabel,
  });

  final _IpDetailData details;
  final String sourceLabel;

  @override
  Widget build(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final items = <(String, String)>[
      (zh ? '国家 / 地区' : 'Country / region', details.country),
      (zh ? '城市' : 'City', details.city),
      ('ASN', details.asn),
      (zh ? '运营商 / 组织' : 'ISP / organization', details.organization),
      (zh ? '数据来源' : 'Source', sourceLabel),
    ].where((item) => item.$2.isNotEmpty).toList(growable: false);
    if (items.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 3 : 2;
        final width =
            (constraints.maxWidth - (columns - 1) * 8) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _IpDetailTile(label: item.$1, value: item.$2),
              ),
          ],
        );
      },
    );
  }
}

class _IpDetailTile extends StatelessWidget {
  const _IpDetailTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: glass.fill.withValues(alpha: glass.isDark ? 0.55 : 0.72),
        borderRadius: AppRadius.all(8),
        border: Border.all(color: glass.separator.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: glass.secondaryLabel,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LatencyTarget {
  const _LatencyTarget({required this.label, required this.url});

  final String label;
  final String url;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.tone,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final GlassTone tone;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final color = context.toneColor(tone);
    return GlassSurface(
      kind: GlassKind.tile,
      borderRadius: AppRadius.small,
      elevated: false,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: glass.isDark ? 0.16 : 0.10),
                    borderRadius: AppRadius.all(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _IpRow extends StatelessWidget {
  const _IpRow({required this.ipInfo, required this.loading, this.onCopy});

  final IpInfo? ipInfo;
  final bool loading;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: glass.fill.withValues(alpha: glass.isDark ? 0.65 : 0.80),
        borderRadius: AppRadius.all(9),
        border: Border.all(color: glass.separator.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Text(
            ipInfo == null ? 'IP' : ipInfo!.countryCode,
            style: context.textTheme.labelMedium?.copyWith(
              color: glass.secondaryLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loading && ipInfo == null ? '…' : ipInfo?.ip ?? 'Timeout',
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                fontFamily: FontFamily.jetBrainsMono.value,
                fontWeight: FontWeight.w600,
                color: ipInfo == null
                    ? glass.secondaryLabel
                    : context.colorScheme.primary,
              ),
            ),
          ),
          if (onCopy != null) ...[
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Copy',
              visualDensity: VisualDensity.compact,
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded, size: 17),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpeedTestServerSelector extends StatelessWidget {
  const _SpeedTestServerSelector({
    required this.servers,
    required this.selectedId,
    required this.loading,
    required this.enabled,
    required this.onChanged,
  });

  final List<SpeedTestServer> servers;
  final String? selectedId;
  final bool loading;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    if (loading) {
      return const SizedBox.square(
        dimension: 18,
        child: CommonCircleLoading(),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 310),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: servers.any((server) => server.id == selectedId)
              ? selectedId
              : null,
          isDense: true,
          isExpanded: true,
          hint: Text(zh ? '选择 Speedtest 节点' : 'Select Speedtest server'),
          items: [
            for (final server in servers)
              DropdownMenuItem<String>(
                value: server.id,
                child: Text(
                  server.latencyMs == null
                      ? server.label
                      : '${server.label} · ${server.latencyMs}ms',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: enabled && servers.isNotEmpty ? onChanged : null,
        ),
      ),
    );
  }
}

class _SpeedTestPanel extends StatelessWidget {
  const _SpeedTestPanel({
    required this.proxyName,
    required this.server,
    required this.serverLoading,
    required this.testing,
    required this.phase,
    required this.liveMbps,
    required this.downloadMbps,
    required this.uploadMbps,
    required this.error,
    required this.onStart,
    required this.onStop,
    required this.text,
  });

  final String? proxyName;
  final SpeedTestServer? server;
  final bool serverLoading;
  final bool testing;
  final SpeedTestPhase? phase;
  final double liveMbps;
  final double? downloadMbps;
  final double? uploadMbps;
  final String? error;
  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final String Function(String zh, String en) text;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final primary = context.colorScheme.primary;
    final teal = context.toneColor(GlassTone.teal);
    final shownDownloadMbps =
        testing && phase == SpeedTestPhase.download ? liveMbps : downloadMbps;
    final shownUploadMbps =
        testing && phase == SpeedTestPhase.upload ? liveMbps : uploadMbps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _SpeedRouteChip(
                    label: text('当前代理', 'Current proxy'),
                    value: proxyName ?? text('未选择', 'Not selected'),
                    icon: Icons.route_rounded,
                  ),
                  if (server != null)
                    _SpeedRouteChip(
                      label: text('测速节点', 'Test server'),
                      value: server!.label,
                      icon: Icons.dns_rounded,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (testing)
              FilledButton.tonalIcon(
                onPressed: onStop,
                icon: const Icon(Icons.stop_rounded, size: 18),
                label: Text(text('停止', 'Stop')),
              )
            else
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(text('开始测速', 'Start test')),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (serverLoading) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            text(
              '正在通过当前代理出口获取附近的 Speedtest 测速节点…',
              'Finding nearby Speedtest servers through the current proxy exit…',
            ),
            style: context.textTheme.bodySmall?.copyWith(
              color: glass.secondaryLabel,
            ),
          ),
        ] else if (server == null) ...[
          Text(
            text(
              '暂无可用的 Speedtest 测速节点。',
              'No Speedtest server is available.',
            ),
            style: context.textTheme.bodySmall?.copyWith(
              color: glass.secondaryLabel,
            ),
          ),
        ] else ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SpeedMetric(
                label: text('下载', 'Download'),
                value: shownDownloadMbps == null
                    ? '— Mbps'
                    : '${shownDownloadMbps.toStringAsFixed(1)} Mbps',
                icon: Icons.download_rounded,
                color: primary,
              ),
              _SpeedMetric(
                label: text('下载吞吐', 'Download throughput'),
                value: shownDownloadMbps == null
                    ? '— MB/s'
                    : '${(shownDownloadMbps / 8).toStringAsFixed(1)} MB/s',
                icon: Icons.data_usage_rounded,
                color: primary,
              ),
              _SpeedMetric(
                label: text('上传', 'Upload'),
                value: shownUploadMbps == null
                    ? '— Mbps'
                    : '${shownUploadMbps.toStringAsFixed(1)} Mbps',
                icon: Icons.upload_rounded,
                color: teal,
              ),
              _SpeedMetric(
                label: text('上传吞吐', 'Upload throughput'),
                value: shownUploadMbps == null
                    ? '— MB/s'
                    : '${(shownUploadMbps / 8).toStringAsFixed(1)} MB/s',
                icon: Icons.swap_vert_rounded,
                color: teal,
              ),
            ],
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(
            error!,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _SpeedRouteChip extends StatelessWidget {
  const _SpeedRouteChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: context.glass.fill,
        borderRadius: AppRadius.full,
        border: Border.all(
          color: context.glass.separator.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.glass.secondaryLabel),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '$label: $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedMetric extends StatelessWidget {
  const _SpeedMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.glass.isDark ? 0.12 : 0.08),
        borderRadius: AppRadius.all(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.glass.secondaryLabel,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProxyRoutePill extends StatelessWidget {
  const _ProxyRoutePill({required this.proxyName});

  final String proxyName;

  @override
  Widget build(BuildContext context) {
    final prefix = Localizations.localeOf(context).languageCode == 'zh'
        ? '经'
        : 'via';
    return GlassPill(
      color: context.colorScheme.primary,
      label: '$prefix $proxyName',
    );
  }
}

class _LatencyTargetsDialog extends StatefulWidget {
  const _LatencyTargetsDialog({required this.initial});

  final List<_LatencyTarget> initial;

  @override
  State<_LatencyTargetsDialog> createState() => _LatencyTargetsDialogState();
}

class _LatencyTargetsDialogState extends State<_LatencyTargetsDialog> {
  late final List<_LatencyTargetDraft> _items;

  @override
  void initState() {
    super.initState();
    _items = [
      for (final target in widget.initial)
        _LatencyTargetDraft(target.label, target.url),
    ];
    if (_items.isEmpty) {
      _items.add(_LatencyTargetDraft('', ''));
    }
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _add() {
    setState(() => _items.add(_LatencyTargetDraft('', '')));
  }

  void _remove(int index) {
    setState(() {
      final item = _items.removeAt(index);
      item.dispose();
      if (_items.isEmpty) {
        _items.add(_LatencyTargetDraft('', ''));
      }
    });
  }

  List<_LatencyTarget>? _buildResult() {
    final result = <_LatencyTarget>[];
    for (final item in _items) {
      final label = item.label.text.trim();
      final url = item.url.text.trim();
      if (label.isEmpty && url.isEmpty) continue;
      final uri = Uri.tryParse(url);
      if (label.isEmpty ||
          uri == null ||
          !(uri.scheme == 'http' || uri.scheme == 'https') ||
          uri.host.isEmpty) {
        return null;
      }
      result.add(_LatencyTarget(label: label, url: url));
    }
    return result.isEmpty ? null : result;
  }

  @override
  Widget build(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    return CommonDialog(
      title: zh ? '编辑延迟检测目标' : 'Edit latency targets',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.appLocalizations.cancel),
        ),
        FilledButton(
          onPressed: () {
            final result = _buildResult();
            if (result == null) {
              context.showNotifier(
                zh
                    ? '请填写名称和有效的 HTTP/HTTPS 地址'
                    : 'Enter a name and a valid HTTP/HTTPS URL',
                level: MessageLevel.warning,
              );
              return;
            }
            Navigator.of(context).pop(result);
          },
          child: Text(context.appLocalizations.confirm),
        ),
      ],
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, item) in _items.indexed) ...[
              Row(
                children: [
                  SizedBox(
                    width: 108,
                    child: TextField(
                      controller: item.label,
                      decoration: InputDecoration(
                        labelText: zh ? '名称' : 'Name',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: item.url,
                      decoration: const InputDecoration(
                        labelText: 'URL',
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.appLocalizations.remove,
                    onPressed: () => _remove(index),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              if (index != _items.length - 1) const SizedBox(height: 8),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add_rounded),
                label: Text(zh ? '添加目标' : 'Add target'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LatencyTargetDraft {
  _LatencyTargetDraft(String labelValue, String urlValue)
      : label = TextEditingController(text: labelValue),
        url = TextEditingController(text: urlValue);

  final TextEditingController label;
  final TextEditingController url;

  void dispose() {
    label.dispose();
    url.dispose();
  }
}

class _LatencyRow extends StatelessWidget {
  const _LatencyRow({
    required this.label,
    required this.delay,
    required this.loading,
  });

  final String label;
  final int? delay;
  final bool loading;

  Color _colorOf(BuildContext context) {
    final value = delay;
    if (value == null) return context.glass.secondaryLabel;
    if (value <= 100) return context.toneColor(GlassTone.success);
    if (value <= 300) return context.toneColor(GlassTone.warning);
    return context.toneColor(GlassTone.danger);
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorOf(context);
    final progress = delay == null
        ? 0.0
        : (delay! / 800).clamp(0.04, 1.0).toDouble();
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadius.full,
            child: LinearProgressIndicator(
              value: loading ? null : progress,
              minHeight: 7,
              color: color,
              backgroundColor: context.glass.fill,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 66,
          child: Text(
            loading ? '…' : delay == null ? 'Timeout' : '${delay}ms',
            textAlign: TextAlign.right,
            style: context.textTheme.labelMedium?.copyWith(
              color: color,
              fontFamily: FontFamily.jetBrainsMono.value,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AverageDelayPill extends StatelessWidget {
  const _AverageDelayPill({required this.values});

  final Iterable<int?> values;

  @override
  Widget build(BuildContext context) {
    final valid = values.whereType<int>().toList();
    if (valid.isEmpty) return const SizedBox.shrink();
    final average = valid.reduce((a, b) => a + b) ~/ valid.length;
    final color = average <= 100
        ? context.toneColor(GlassTone.success)
        : average <= 300
        ? context.toneColor(GlassTone.warning)
        : context.toneColor(GlassTone.danger);
    final prefix = Localizations.localeOf(context).languageCode == 'zh'
        ? '平均'
        : 'Avg';
    return GlassPill(color: color, label: '$prefix: ${average}ms');
  }
}
