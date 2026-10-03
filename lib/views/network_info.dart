import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
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

  static const _targets = <_LatencyTarget>[
    _LatencyTarget(
      label: 'Google',
      url: 'https://www.google.com/generate_204',
    ),
    _LatencyTarget(
      label: 'Cloudflare',
      url: 'https://cp.cloudflare.com/generate_204',
    ),
    _LatencyTarget(label: 'GitHub', url: 'https://github.com'),
  ];

  final Map<String, int?> _latencies = {};
  String _selectedIpSource = _autoSource;
  IpInfo? _sourceIpInfo;
  bool _sourceIpLoading = false;
  bool _testing = false;
  int _ipCheckVersion = 0;
  int _testVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(networkDetectionProvider.notifier).startCheck();
      unawaited(_refreshLatency());
    });
  }

  Future<void> _refreshIp() async {
    if (_selectedIpSource == _autoSource) {
      ref.read(networkDetectionProvider.notifier).startCheck();
      return;
    }

    final version = ++_ipCheckVersion;
    setState(() => _sourceIpLoading = true);
    final result = await request.checkIp(sourceUrl: _selectedIpSource);
    if (!mounted || version != _ipCheckVersion) return;
    setState(() {
      _sourceIpInfo = result.data;
      _sourceIpLoading = false;
    });
  }

  void _selectIpSource(String value) {
    if (value == _selectedIpSource) return;
    setState(() {
      _selectedIpSource = value;
      _sourceIpInfo = null;
      _sourceIpLoading = value != _autoSource;
    });
    unawaited(_refreshIp());
  }

  Future<void> _refreshLatency() async {
    final version = ++_testVersion;
    if (mounted) {
      setState(() => _testing = true);
    }
    final results = await Future.wait(
      _targets.map((target) async {
        final delay = await request.probeLatency(target.url);
        return (target.label, delay);
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

  _RouteSummary _routeSummary(WidgetRef ref) {
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    if (mode == Mode.direct) {
      return const _RouteSummary(label: 'DIRECT', direct: true);
    }

    final groups = ref.watch(currentGroupsStateProvider).value;
    final preferred = ref.watch(
      currentProfileProvider.select((state) => state?.currentGroupName),
    );
    Group? group;
    if (preferred != null) {
      for (final item in groups) {
        if (item.name == preferred) {
          group = item;
          break;
        }
      }
    }
    group ??= groups.isEmpty ? null : groups.first;
    if (group == null) {
      return _RouteSummary(label: mode.label, direct: false);
    }
    final selected = ref.watch(selectedProxyNameProvider(group.name));
    return _RouteSummary(
      label: selected == null || selected.isEmpty ? group.name : selected,
      direct: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detection = ref.watch(networkDetectionProvider);
    final localIp = ref.watch(localIpProvider);
    final route = _routeSummary(ref);
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
            child: _IpRow(
              ipInfo: publicIp,
              loading: ipLoading,
              onCopy: publicIp == null
                  ? null
                  : () => Clipboard.setData(ClipboardData(text: publicIp.ip)),
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: _text(context, '网络拓扑', 'Network topology'),
            icon: Icons.hub_rounded,
            tone: GlassTone.success,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final nodes = [
                  _TopologyData(
                    icon: Icons.devices_rounded,
                    title: _text(context, '本机', 'Device'),
                    subtitle: (localIp == null || localIp.isEmpty)
                        ? '—'
                        : localIp,
                  ),
                  const _TopologyData(
                    icon: Icons.route_rounded,
                    title: 'AetherClash',
                    subtitle: 'mihomo',
                  ),
                  _TopologyData(
                    icon: route.direct
                        ? Icons.arrow_forward_rounded
                        : Icons.cloud_queue_rounded,
                    title: route.label,
                    subtitle: route.direct
                        ? _text(context, '直连', 'Direct')
                        : _text(context, '当前出口', 'Current route'),
                  ),
                  _TopologyData(
                    icon: Icons.language_rounded,
                    title: publicIp?.ip ?? '—',
                    subtitle:
                        publicIp?.countryCode ?? _text(context, '公网', 'Internet'),
                  ),
                ];
                return constraints.maxWidth >= 720
                    ? _HorizontalTopology(nodes: nodes)
                    : _VerticalTopology(nodes: nodes);
              },
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
                _AverageDelayPill(values: _latencies.values),
                const SizedBox(width: 6),
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

class _LatencyTarget {
  const _LatencyTarget({required this.label, required this.url});

  final String label;
  final String url;
}

class _RouteSummary {
  const _RouteSummary({required this.label, required this.direct});

  final String label;
  final bool direct;
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

class _TopologyData {
  const _TopologyData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _HorizontalTopology extends StatelessWidget {
  const _HorizontalTopology({required this.nodes});

  final List<_TopologyData> nodes;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (index, node) in nodes.indexed) ...[
          Expanded(child: _TopologyNode(data: node)),
          if (index != nodes.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward_rounded, size: 18),
            ),
        ],
      ],
    );
  }
}

class _VerticalTopology extends StatelessWidget {
  const _VerticalTopology({required this.nodes});

  final List<_TopologyData> nodes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (index, node) in nodes.indexed) ...[
          _TopologyNode(data: node),
          if (index != nodes.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Icon(Icons.arrow_downward_rounded, size: 18),
            ),
        ],
      ],
    );
  }
}

class _TopologyNode extends StatelessWidget {
  const _TopologyNode({required this.data});

  final _TopologyData data;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: glass.fill.withValues(alpha: glass.isDark ? 0.62 : 0.78),
        borderRadius: AppRadius.all(10),
        border: Border.all(color: glass.separator.withValues(alpha: 0.50)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, size: 20, color: context.colorScheme.primary),
          const SizedBox(height: 5),
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: glass.secondaryLabel,
            ),
          ),
        ],
      ),
    );
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
