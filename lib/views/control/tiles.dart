import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/method.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/activity.dart';
import 'package:fl_clash/views/config/network.dart';
import 'package:fl_clash/views/po0_firewall.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _tilePadding = EdgeInsets.all(16);

class _TileHeader extends StatelessWidget {
  const _TileHeader({
    required this.icon,
    required this.label,
    this.color,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? context.glass.secondaryLabel),
        const SizedBox(width: 8),
        Expanded(
          child: EmojiText(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelLarge?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class OutboundModeSwitch extends ConsumerWidget {
  const OutboundModeSwitch({super.key, this.height = 44});

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    return GlassSegmented<Mode>(
      height: height,
      values: Mode.values,
      selected: mode,
      labelOf: (mode) => mode.label,
      selectedColor: context.colorScheme.primary,
      selectedForegroundColor: context.colorScheme.onPrimary,
      onChanged: (mode) {
        ref.read(setupActionProvider.notifier).changeMode(mode);
      },
    );
  }
}

/// The group the proxies page opens on, or the first one it lists.
Group? leadingGroupOf(WidgetRef ref) {
  final groups = ref.watch(currentGroupsStateProvider).value;
  final preferred = ref.watch(
    currentProfileProvider.select((state) => state?.currentGroupName),
  );
  return groups.firstWhereOrNull((group) => group.name == preferred) ??
      groups.firstOrNull;
}

class CurrentNodeCard extends ConsumerWidget {
  const CurrentNodeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final group = leadingGroupOf(ref);
    final selected = group == null
        ? null
        : ref.watch(selectedProxyNameProvider(group.name));
    final title = switch ((mode, selected)) {
      (Mode.direct, _) => appLocalizations.direct,
      (_, final String name) when name.isNotEmpty => name,
      _ => appLocalizations.noProxySelected,
    };
    return GlassButton(
      padding: _tilePadding,
      onTap: () =>
          ref.read(currentPageLabelProvider.notifier).toPage(PageLabel.proxies),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TileHeader(
            icon: Icons.hub_rounded,
            label: group == null || mode == Mode.direct
                ? appLocalizations.currentProxy
                : group.name,
            trailing: selected == null || mode == Mode.direct
                ? null
                : _DelayPill(proxyName: selected, testUrl: group?.testUrl),
          ),
          const SizedBox(height: 12),
          EmojiText(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _DelayPill extends ConsumerWidget {
  const _DelayPill({required this.proxyName, this.testUrl});

  final String proxyName;
  final String? testUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delay = ref.watch(
      delayProvider(proxyName: proxyName, testUrl: testUrl),
    );
    if (delay == null || delay == 0) {
      return const SizedBox.shrink();
    }
    final color = getDelayColor(delay) ?? context.colorScheme.onSurfaceVariant;
    return GlassPill(color: color, label: delay > 0 ? '$delay ms' : 'Timeout');
  }
}

class TrafficCard extends ConsumerWidget {
  const TrafficCard({super.key});

  void _openActivity(BuildContext context, WidgetRef ref) {
    if (context.isMobileView) {
      BaseNavigator.push(context, const ActivityView());
      return;
    }
    ref.read(currentPageLabelProvider.notifier).toPage(PageLabel.activity);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final traffics = ref.watch(trafficsProvider).list;
    final last = traffics.lastOrNull ?? const Traffic();
    final total = ref.watch(totalTrafficProvider);
    return RepaintBoundary(
      child: GlassButton(
        padding: _tilePadding,
        onTap: () => _openActivity(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TileHeader(
              icon: Icons.speed_rounded,
              label: appLocalizations.networkSpeed,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SpeedValue(
                    icon: Icons.north_rounded,
                    value: last.up,
                    color: colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _SpeedValue(
                    icon: Icons.south_rounded,
                    value: last.down,
                    color: context.toneColor(GlassTone.teal),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 56,
              child: LineChart(
                gradient: true,
                color: colorScheme.primary,
                points: [
                  const Point(0, 0),
                  const Point(1, 0),
                  for (final (index, traffic) in traffics.indexed)
                    Point(index + 2, traffic.speed.toDouble()),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${appLocalizations.trafficUsage}  ${total.desc}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedValue extends StatelessWidget {
  const _SpeedValue({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final num value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final show = value.traffic;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text.rich(
            TextSpan(
              text: show.value,
              style: context.textTheme.titleLarge?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              children: [
                TextSpan(
                  text: ' ${show.unit}/s',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class Po0StatusCard extends ConsumerWidget {
  const Po0StatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final setting = ref.watch(po0FirewallSettingProvider);
    final state = ref.watch(po0FirewallProvider);
    final overview = po0OverviewOf(
      appLocalizations,
      enabled: setting.enable,
      hasTokens: po0TokensOf(setting.tokenEntries).isNotEmpty,
      state: state,
    );
    final color = context.toneColor(overview.tone);
    final exitIp = state.results.map((it) => it.currentIp).nonNulls.firstOrNull;
    return GlassButton(
      padding: _tilePadding,
      onTap: () =>
          ref.read(currentPageLabelProvider.notifier).toPage(PageLabel.po0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TileHeader(
            icon: overview.icon,
            label: appLocalizations.po0Nav,
            color: color,
          ),
          const SizedBox(height: 12),
          Text(
            overview.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleMedium,
          ),
          if (exitIp != null) ...[
            const SizedBox(height: 4),
            Text(
              appLocalizations.po0Exit(exitIp),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CurrentProfileCard extends ConsumerWidget {
  const CurrentProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final profile = ref.watch(currentProfileProvider);
    return GlassButton(
      padding: _tilePadding,
      onTap: () => ref
          .read(currentPageLabelProvider.notifier)
          .toPage(PageLabel.profiles),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TileHeader(
            icon: Icons.layers_rounded,
            label: appLocalizations.profile,
          ),
          const SizedBox(height: 12),
          Text(
            profile?.realLabel ?? appLocalizations.nullProfileDesc,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleMedium,
          ),
          if (profile?.subscriptionInfo case final info?) ...[
            const SizedBox(height: 8),
            SubscriptionInfoView(subscriptionInfo: info),
          ],
        ],
      ),
    );
  }
}

const _toggleHeight = 48.0;

void _showOptions(BuildContext context, String title, List<Widget> items) {
  showSheet(
    context: context,
    builder: (_) => AdaptiveSheetScaffold(
      body: generateListView(generateSection(items: items)),
      title: title,
    ),
  );
}

class _QuickToggle extends StatelessWidget {
  const _QuickToggle({
    required this.label,
    required this.icon,
    required this.items,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final List<Widget> items;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return SizedBox(
      height: _toggleHeight,
      child: GlassButton(
        selected: selected,
        rimColor: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
        onTap: onTap,
        onLongPress: () => _showOptions(context, label, items),
        onSecondaryTap: () => _showOptions(context, label, items),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelLarge?.copyWith(
                  color: selected ? colorScheme.primary : null,
                ),
              ),
            ),
            if (!compact)
              GlassIconButton(
                tooltip: context.appLocalizations.options,
                icon: Icons.tune_rounded,
                onPressed: () => _showOptions(context, label, items),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _setDesktopTun(
  BuildContext context,
  WidgetRef ref,
  bool value,
) async {
  final current = ref.read(patchClashConfigProvider).tun.enable;
  if (value == current) return;
  if (value && !await confirmTunEnable(context)) {
    return;
  }
  ref
      .read(patchClashConfigProvider.notifier)
      .update((state) => state.copyWith.tun(enable: value));
}

void _setDesktopSystemProxy(WidgetRef ref, bool value) {
  final current = ref.read(networkSettingProvider).systemProxy;
  if (value == current) return;
  ref
      .read(networkSettingProvider.notifier)
      .update((state) => state.copyWith(systemProxy: value));
}

/// Routing controls with the detected exit beside them. Desktop TUN and the
/// system proxy are independent; Android uses the VPN switch.
class QuickToggles extends ConsumerWidget {
  const QuickToggles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (_, constraints) => _buildRow(
        context,
        ref,
        compact: constraints.maxWidth < _compactWidth,
      ),
    );
  }

  static const _compactWidth = 480.0;

  Widget _buildRow(
    BuildContext context,
    WidgetRef ref, {
    required bool compact,
  }) {
    final appLocalizations = context.appLocalizations;
    final toggles = <Widget>[
      if (system.isAndroid)
        _QuickToggle(
          compact: compact,
          label: 'VPN',
          icon: Icons.vpn_lock_rounded,
          items: const [VPNItem(), VpnSystemProxyItem(), TunStackItem()],
          selected: ref.watch(
            vpnSettingProvider.select((state) => state.enable),
          ),
          onTap: () => ref
              .read(vpnSettingProvider.notifier)
              .update((state) => state.copyWith(enable: !state.enable)),
        ),
      if (system.isDesktop) ...[
        _QuickToggle(
          compact: compact,
          label: appLocalizations.tun,
          icon: Icons.lan_rounded,
          items: [
            const TUNItem(),
            if (system.isMacOS) const AutoSetSystemDnsItem(),
            const TunStackItem(),
          ],
          selected: ref.watch(
            patchClashConfigProvider.select((state) => state.tun.enable),
          ),
          onTap: () => unawaited(
            _setDesktopTun(
              context,
              ref,
              !ref.read(patchClashConfigProvider).tun.enable,
            ),
          ),
        ),
        _QuickToggle(
          compact: compact,
          label: appLocalizations.systemProxy,
          icon: Icons.settings_ethernet_rounded,
          items: const [SystemProxyItem(), BypassDomainItem()],
          selected: ref.watch(
            networkSettingProvider.select((state) => state.systemProxy),
          ),
          onTap: () => _setDesktopSystemProxy(
            ref,
            !ref.read(networkSettingProvider).systemProxy,
          ),
        ),
      ],
      const IpDetectionChip(),
    ];
    return Row(
      children: [
        for (final (index, toggle) in toggles.indexed) ...[
          if (index > 0) const SizedBox(width: 10),
          Expanded(child: toggle),
        ],
      ],
    );
  }
}

/// Two independent desktop routing controls for the wide sidebar.
class DesktopRouteCards extends ConsumerWidget {
  const DesktopRouteCards({super.key});

  void _openNetwork(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    BaseNavigator.push(
      context,
      BaseScaffold(
        title: appLocalizations.network,
        body: const NetworkListView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final systemProxy = ref.watch(
      networkSettingProvider.select((state) => state.systemProxy),
    );
    final tun = ref.watch(
      patchClashConfigProvider.select((state) => state.tun.enable),
    );
    return Row(
      children: [
        Expanded(
          child: _DesktopRouteCard(
            icon: Icons.public_rounded,
            label: appLocalizations.systemProxy,
            value: systemProxy,
            onTap: () => _openNetwork(context),
            onChanged: (value) => _setDesktopSystemProxy(ref, value),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DesktopRouteCard(
            icon: Icons.lan_rounded,
            label: appLocalizations.tun,
            value: tun,
            onTap: () => _openNetwork(context),
            onChanged: (value) =>
                unawaited(_setDesktopTun(context, ref, value)),
          ),
        ),
      ],
    );
  }
}

class _DesktopRouteCard extends StatelessWidget {
  const _DesktopRouteCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final VoidCallback onTap;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final activeColor = context.colorScheme.primary;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.all(12),
        child: AnimatedContainer(
          duration: context.motionDuration(Durations.short4),
          height: 92,
          decoration: BoxDecoration(
            color: value
                ? activeColor.withValues(alpha: glass.isDark ? 0.88 : 0.92)
                : glass.fill.withValues(alpha: glass.isDark ? 0.72 : 0.86),
            borderRadius: AppRadius.all(12),
            border: Border.all(
              color: value
                  ? activeColor.withValues(alpha: 0.92)
                  : glass.separator.withValues(alpha: 0.55),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 30,
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 19,
                        color: value ? Colors.white : glass.secondaryLabel,
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 38,
                        height: 24,
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: Switch(
                            value: value,
                            onChanged: onChanged,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: value ? Colors.white : context.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _flagOf(String countryCode) {
  final code = countryCode.toUpperCase();
  if (code.length != 2) {
    return countryCode;
  }
  return String.fromCharCodes([
    code.codeUnitAt(0) - 0x41 + 0x1F1E6,
    code.codeUnitAt(1) - 0x41 + 0x1F1E6,
  ]);
}

/// The exit IP as seen from outside; a tap checks again, a long press
/// explains where the answer comes from.
class IpDetectionChip extends ConsumerWidget {
  const IpDetectionChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final detection = ref.watch(networkDetectionProvider);
    final ipInfo = detection.ipInfo;
    final valueStyle = context.textTheme.labelLarge?.copyWith(
      fontFamily: FontFamily.jetBrainsMono.value,
    );
    return SizedBox(
      height: _toggleHeight,
      child: GlassButton(
        tooltip: ipInfo == null
            ? appLocalizations.networkDetection
            : '${ipInfo.countryCode} · ${ipInfo.ip}',
        padding: const EdgeInsets.symmetric(horizontal: 12),
        onTap: () => ref.read(checkIpNumProvider.notifier).add(),
        onLongPress: () => dialogs.showMessage(
          title: appLocalizations.networkDetection,
          message: TextSpan(text: appLocalizations.detectionTip),
          cancelable: false,
        ),
        child: FadeThroughBox(
          alignment: Alignment.centerLeft,
          child: Row(
            key: ValueKey((ipInfo, detection.isLoading)),
            children: [
              if (ipInfo != null)
                Text(
                  _flagOf(ipInfo.countryCode),
                  style: context.textTheme.titleMedium?.copyWith(
                    fontFamily: FontFamily.twEmoji.value,
                  ),
                )
              else
                Icon(
                  Icons.public_rounded,
                  size: 20,
                  color: context.toneColor(GlassTone.success),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: ipInfo != null
                    ? Text(
                        ipInfo.ip,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: valueStyle,
                      )
                    : detection.isLoading
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox.square(
                          dimension: 16,
                          child: CommonCircleLoading(),
                        ),
                      )
                    : Text(
                        'Timeout',
                        style: valueStyle?.copyWith(
                          color: context.toneColor(GlassTone.danger),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final Widget value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                DefaultTextStyle.merge(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  child: value,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NetworkCard extends ConsumerWidget {
  const NetworkCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final localIp = ref.watch(localIpProvider);
    return _StatTile(
      icon: Icons.devices_rounded,
      color: context.toneColor(GlassTone.success),
      label: appLocalizations.intranetIP,
      value: Text(
        localIp == null
            ? '…'
            : localIp.isNotEmpty
            ? localIp
            : appLocalizations.noNetwork,
        style: TextStyle(fontFamily: FontFamily.jetBrainsMono.value),
      ),
    );
  }
}

class MemoryInfo extends ConsumerStatefulWidget {
  final Future<num> Function()? memoryReader;

  const MemoryInfo({super.key, @visibleForTesting this.memoryReader});

  @override
  ConsumerState<MemoryInfo> createState() => _MemoryInfoState();
}

class _MemoryInfoState extends ConsumerState<MemoryInfo>
    with WidgetsBindingObserver, ActivePollingMixin<MemoryInfo> {
  final _memoryStateNotifier = ValueNotifier<num>(0);

  CoreController get _core => ref.read(coreHandlerProvider);

  @override
  Duration get pollInterval => const Duration(seconds: 2);

  @override
  void dispose() {
    _memoryStateNotifier.dispose();
    super.dispose();
  }

  @override
  Future<void> poll(PollGuard isCurrent) async {
    final memory = await _readMemory();
    if (memory == null || !isCurrent()) {
      return;
    }
    _memoryStateNotifier.value = memory;
  }

  Future<num?> _readMemory() async {
    try {
      final memoryReader = widget.memoryReader;
      return memoryReader != null ? await memoryReader() : await _readTotal();
    } catch (error) {
      commonPrint.log(
        'updateMemory error: $error',
        logLevel: coreFailureLogLevel(error),
      );
      return null;
    }
  }

  Future<num> _readTotal() async {
    final rss = ProcessInfo.currentRss;
    final coreConnected = ref.read(coreStatusProvider) == CoreStatus.connected;
    if (system.isDesktop && coreConnected) {
      return await _core.getMemory() + rss;
    }
    return rss;
  }

  @override
  Widget build(BuildContext context) {
    return _StatTile(
      icon: Icons.memory_rounded,
      color: context.toneColor(GlassTone.warning),
      label: context.appLocalizations.memoryInfo,
      onTap: _core.requestGc,
      value: ValueListenableBuilder(
        valueListenable: _memoryStateNotifier,
        builder: (_, memory, _) => Text(memory.traffic.show),
      ),
    );
  }
}
