import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/mkcloud_firewall.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _maxContentWidth = 1240.0;
const _referencePage = Color(0xFFF5F6F8);
const _referenceCard = Colors.white;
const _referenceInk = Color(0xFF14213A);
const _referenceMuted = Color(0xFF7B8AA5);
const _referenceBlue = Color(0xFF2F6DF6);
const _referencePurple = Color(0xFF8757F5);
const _referenceGreen = Color(0xFF21C66A);
const _referenceCell = Color(0xFFF0F2F6);

String _provinceLabel(MkcloudResult result, String? value) {
  if (value == null || value.isEmpty) return '-';
  const chineseNames = {
    'anhui': '安徽',
    'beijing': '北京',
    'chongqing': '重庆',
    'fujian': '福建',
    'gansu': '甘肃',
    'guangdong': '广东',
    'guangxi': '广西',
    'guizhou': '贵州',
    'hainan': '海南',
    'hebei': '河北',
    'heilongjiang': '黑龙江',
    'henan': '河南',
    'hubei': '湖北',
    'hunan': '湖南',
    'jiangsu': '江苏',
    'jiangxi': '江西',
    'jilin': '吉林',
    'liaoning': '辽宁',
    'neimenggu': '内蒙古',
    'ningxia': '宁夏',
    'qinghai': '青海',
    'shaanxi': '陕西',
    'shandong': '山东',
    'shanghai': '上海',
    'shanxi': '山西',
    'sichuan': '四川',
    'tianjin': '天津',
    'xinjiang': '新疆',
    'yunnan': '云南',
    'zhejiang': '浙江',
    'xizang': '西藏',
    'taiwan': '台湾',
    'hongkong': '香港',
    'macau': '澳门',
  };
  final chineseName = chineseNames[value.toLowerCase()];
  if (chineseName != null) return chineseName;
  for (final province in result.provinces) {
    if (province.value == value) return province.label;
  }
  return value;
}

class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: const BoxDecoration(
      color: _referenceCard,
      borderRadius: AppRadius.medium,
      boxShadow: [
        BoxShadow(
          color: Color(0x120F172A),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(color: _referenceInk),
      child: child,
    ),
  );
}

class _ReferenceActionCard extends StatelessWidget {
  const _ReferenceActionCard({
    required this.child,
    required this.onTap,
    required this.padding,
  });
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => _ReferenceCard(
    padding: EdgeInsets.zero,
    child: InkWell(
      borderRadius: AppRadius.medium,
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class MkcloudFirewallView extends ConsumerWidget {
  const MkcloudFirewallView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = ref.watch(
      mkcloudFirewallProvider.select((state) => state.isRunning),
    );
    return ScaffoldTitleSlot(
      title: Row(
        children: [
          Text(
            context.appLocalizations.mkcloudFirewall,
            style: context.textTheme.headlineSmall?.copyWith(
              color: _referenceInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            context.appLocalizations.mkcloudProductService,
            style: context.textTheme.bodyMedium?.copyWith(
              color: _referenceMuted,
            ),
          ),
        ],
      ),
      child: BaseScaffold(
        title: context.appLocalizations.mkcloudFirewall,
        body: Stack(
          children: [
            ColoredBox(
              color: _referencePage,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  20,
                  24,
                  28 + BottomInsetScope.of(context),
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _maxContentWidth,
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Overview(),
                          SizedBox(height: 18),
                          _AutomationSettings(),
                          SizedBox(height: 22),
                          _ApiKeyTile(),
                          SizedBox(height: 22),
                          _Rules(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isRunning) const _MkcloudLoadingOverlay(),
          ],
        ),
      ),
    );
  }
}

class _MkcloudLoadingOverlay extends StatelessWidget {
  const _MkcloudLoadingOverlay();

  @override
  Widget build(BuildContext context) => const Positioned.fill(
    child: AbsorbPointer(
      child: ColoredBox(
        color: Color(0x140F172A),
        child: Center(
          child: _ReferenceCard(
            padding: EdgeInsets.all(16),
            child: SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Overview extends ConsumerWidget {
  const _Overview();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.appLocalizations;
    final setting = ref.watch(mkcloudFirewallSettingProvider);
    final state = ref.watch(mkcloudFirewallProvider);
    final result = state.result;
    final ready = setting.apiKey.isNotEmpty;
    final failed = result?.type == MkcloudResultType.error;
    final ipMode = result?.mode == 'ip';
    final provinceMode = result?.mode == 'province';
    final title = failed
        ? l10n.mkcloudStatusError
        : ipMode
        ? l10n.mkcloudIpActive
        : provinceMode
        ? l10n.mkcloudProvinceActive
        : !setting.enable
        ? l10n.mkcloudStatusOff
        : !ready
        ? l10n.mkcloudStatusNoKey
        : state.isRunning
        ? l10n.mkcloudRunning
        : l10n.mkcloudStatusWaiting;
    final subtitle = failed
        ? l10n.mkcloudStatusErrorDesc
        : provinceMode
        ? l10n.mkcloudCurrentProvince(_provinceLabel(result!, result.province))
        : ipMode
        ? l10n.mkcloudUsage(result?.count ?? 0, result?.limit ?? 10)
        : state.lastRunAt == null
        ? l10n.mkcloudNeverRun
        : l10n.mkcloudLastRun(state.lastRunAt!.toLocal().toString());
    final notifier = ref.read(mkcloudFirewallProvider.notifier);
    return _ReferenceCard(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final summary = Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0EAFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  failed
                      ? Icons.cloud_off_rounded
                      : ipMode
                      ? Icons.public_rounded
                      : Icons.map_rounded,
                  color: failed ? const Color(0xFFE54B4B) : _referencePurple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.headlineSmall?.copyWith(
                        color: _referenceInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: _referenceMuted,
                      ),
                    ),
                    if (setting.enable) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.mkcloudPollEvery(setting.pollSeconds),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: _referenceMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: ready && !state.isRunning
                    ? () => unawaited(notifier.query())
                    : null,
                icon: const Icon(Icons.travel_explore_rounded, size: 18),
                label: Text(l10n.mkcloudQueryStatus),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _referenceInk,
                  backgroundColor: _referenceCell,
                  side: BorderSide.none,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.small,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              if (result?.mode != null)
                OutlinedButton.icon(
                  onPressed: ready && !state.isRunning
                      ? () => ipMode
                            ? _showProvinceDialog(context, ref, result!)
                            : unawaited(notifier.switchToIp())
                      : null,
                  icon: Icon(
                    ipMode ? Icons.map_rounded : Icons.public_rounded,
                    size: 18,
                  ),
                  label: Text(
                    ipMode ? l10n.mkcloudSwitchProvince : l10n.mkcloudSwitchIp,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: _referencePurple,
                    side: BorderSide.none,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.small,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: ready && !state.isRunning
                    ? () => unawaited(notifier.whitelist())
                    : null,
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: Text(l10n.mkcloudWhitelistNow),
                style: FilledButton.styleFrom(
                  backgroundColor: _referenceBlue,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.small,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          );
          return constraints.maxWidth < 720
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [summary, const SizedBox(height: 16), actions],
                )
              : Row(
                  children: [
                    Expanded(child: summary),
                    const SizedBox(width: 16),
                    actions,
                  ],
                );
        },
      ),
    );
  }

  Future<void> _showProvinceDialog(
    BuildContext context,
    WidgetRef ref,
    MkcloudResult result,
  ) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => _ProvinceDialog(provinces: result.provinces),
    );
    if (selected != null) {
      if (!context.mounted) return;
      await ref.read(mkcloudFirewallProvider.notifier).setProvince(selected);
    }
  }
}

class _AutomationSettings extends ConsumerWidget {
  const _AutomationSettings();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.appLocalizations;
    final setting = ref.watch(mkcloudFirewallSettingProvider);
    final notifier = ref.read(mkcloudFirewallSettingProvider.notifier);
    final auto = _ReferenceActionCard(
      padding: const EdgeInsets.all(16),
      onTap: () => notifier.update((it) => it.copyWith(enable: !it.enable)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: _referenceGreen,
              borderRadius: AppRadius.small,
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.mkcloudAutoWhitelist,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: _referenceInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  l10n.mkcloudAutoWhitelistDesc,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: _referenceMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: setting.enable,
            activeThumbColor: Colors.white,
            activeTrackColor: _referenceGreen,
            onChanged: (value) =>
                notifier.update((it) => it.copyWith(enable: value)),
          ),
        ],
      ),
    );
    final interval = _ReferenceActionCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      onTap: () => _editInterval(context, ref, setting.pollSeconds),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: _referenceBlue,
              borderRadius: AppRadius.small,
            ),
            child: const Icon(Icons.timer_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.mkcloudPollInterval,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: _referenceInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  l10n.mkcloudPollEvery(setting.pollSeconds),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: _referenceMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.edit_rounded, size: 18),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (_, constraints) => constraints.maxWidth < 720
          ? Column(children: [auto, const SizedBox(height: 12), interval])
          : IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(child: auto),
                  const SizedBox(width: 12),
                  Expanded(child: interval),
                ],
              ),
            ),
    );
  }

  Future<void> _editInterval(
    BuildContext context,
    WidgetRef ref,
    int seconds,
  ) async {
    final l10n = context.appLocalizations;
    final value = await dialogs.showCommonDialog<String>(
      child: InputDialog(
        title: l10n.mkcloudPollInterval,
        value: '$seconds',
        suffixText: l10n.seconds,
        keyboardType: TextInputType.number,
        validator: (value) {
          final parsed = int.tryParse(value ?? '');
          return parsed != null &&
                  parsed >= mkcloudPollSecondsRange.min &&
                  parsed <= mkcloudPollSecondsRange.max
              ? null
              : l10n.mkcloudPollIntervalRange(
                  mkcloudPollSecondsRange.min,
                  mkcloudPollSecondsRange.max,
                );
        },
      ),
    );
    if (value != null) {
      ref
          .read(mkcloudFirewallSettingProvider.notifier)
          .update((it) => it.copyWith(pollSeconds: int.parse(value)));
    }
  }
}

class _ApiKeyTile extends ConsumerWidget {
  const _ApiKeyTile();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.appLocalizations;
    final apiKey = ref.watch(
      mkcloudFirewallSettingProvider.select((it) => it.apiKey),
    );
    Future<void> edit() async {
      final value = await dialogs.showCommonDialog<String>(
        child: InputDialog(
          title: l10n.mkcloudApiKey,
          value: apiKey,
          obscureText: true,
        ),
      );
      if (value != null) {
        ref
            .read(mkcloudFirewallSettingProvider.notifier)
            .update((it) => it.copyWith(apiKey: value.trim()));
      }
    }

    return _ReferenceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GlassIconBadge(icon: Icons.key_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.mkcloudApiKey,
                  style: context.textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: l10n.mkcloudChangeApiKey,
                onPressed: edit,
                icon: const Icon(Icons.edit_rounded),
                style: IconButton.styleFrom(
                  foregroundColor: _referenceBlue,
                  backgroundColor: const Color(0xFFE8F0FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.mkcloudApiEndpoint, style: context.textTheme.bodySmall),
          const SizedBox(height: 6),
          const _CodeCell(value: mkcloudApiUri),
          const SizedBox(height: 10),
          _CodeCell(
            value: apiKey.isEmpty
                ? l10n.mkcloudKeyEmpty
                : _maskedApiKey(apiKey),
            icon: Icons.key_rounded,
          ),
        ],
      ),
    );
  }
}

String _maskedApiKey(String value) => value.length <= 8
    ? '••••••••'
    : '${value.substring(0, 4)}••••${value.substring(value.length - 4)}';

class _CodeCell extends StatelessWidget {
  const _CodeCell({required this.value, this.icon});
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: const BoxDecoration(
      color: _referenceCell,
      borderRadius: AppRadius.small,
    ),
    child: Row(
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 10)],
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              color: _referenceInk,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    ),
  );
}

class _Rules extends ConsumerWidget {
  const _Rules();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.appLocalizations;
    final state = ref.watch(mkcloudFirewallProvider);
    final result = state.result;
    if (result == null || result.type == MkcloudResultType.error) {
      return const SizedBox.shrink();
    }
    if (result.mode == 'province') {
      final selectedProvince = state.selectedProvince ?? result.province;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RuleHeading(
            title: '${l10n.mkcloudProvinceRule}（${l10n.mkcloudProvinceActive}）',
          ),
          const SizedBox(height: 10),
          _ReferenceCard(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.mkcloudProvinceRule,
                  style: context.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.mkcloudCurrentProvince(
                    _provinceLabel(result, result.province),
                  ),
                ),
                const Divider(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final province in result.provinces)
                      _ProvinceChip(
                        label: province.label,
                        selected: province.value == selectedProvince,
                        applied: province.value == result.province,
                        enabled: !state.isRunning,
                        onTap: () => ref
                            .read(mkcloudFirewallProvider.notifier)
                            .selectProvince(province.value),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.mkcloudProvinceHint,
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (result.mode != 'ip') return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RuleHeading(title: l10n.mkcloudIpRule(result.count, result.limit)),
        const SizedBox(height: 10),
        _IpRules(result: result),
      ],
    );
  }
}

class _ProvinceChip extends StatelessWidget {
  const _ProvinceChip({
    required this.label,
    required this.selected,
    required this.applied,
    required this.enabled,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final bool applied;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFFEFE8FF) : _referenceCell,
    borderRadius: AppRadius.small,
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: AppRadius.small,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (applied) ...[
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: _referencePurple,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? _referencePurple : _referenceMuted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RuleHeading extends StatelessWidget {
  const _RuleHeading({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: context.textTheme.titleMedium?.copyWith(
      color: _referenceMuted,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _IpRules extends ConsumerStatefulWidget {
  const _IpRules({required this.result});
  final MkcloudResult result;

  @override
  ConsumerState<_IpRules> createState() => _IpRulesState();
}

class _IpRulesState extends ConsumerState<_IpRules> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addIp() {
    final value = _controller.text.trim();
    if (!isIpv4(value)) return;
    _controller.clear();
    unawaited(ref.read(mkcloudFirewallProvider.notifier).addIp(value));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.appLocalizations;
    final state = ref.watch(mkcloudFirewallProvider);
    final result = widget.result;
    final usage = result.limit == 0 ? 0.0 : result.count / result.limit;
    final disabled = state.isRunning;
    return _ReferenceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.mkcloudIpRule(result.count, result.limit),
            style: context.textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final input = TextField(
                controller: _controller,
                enabled: !disabled,
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _addIp(),
                decoration: InputDecoration(
                  hintText: l10n.mkcloudIpHint,
                  prefixIcon: const Icon(Icons.language_rounded),
                  filled: true,
                  fillColor: _referenceCell,
                  border: AppShape.input,
                  enabledBorder: AppShape.input,
                  focusedBorder: AppShape.input,
                ),
              );
              final actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: disabled ? null : _addIp,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.mkcloudAddIp),
                    style: FilledButton.styleFrom(
                      backgroundColor: _referenceBlue,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.small,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: disabled
                        ? null
                        : () => unawaited(
                            ref
                                .read(mkcloudFirewallProvider.notifier)
                                .switchToIp(),
                          ),
                    icon: const Icon(Icons.public_rounded, size: 18),
                    label: Text(l10n.mkcloudAddCurrentExit),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _referenceInk,
                      backgroundColor: _referenceCell,
                      side: BorderSide.none,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.small,
                      ),
                    ),
                  ),
                ],
              );
              return constraints.maxWidth < 640
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [input, const SizedBox(height: 10), actions],
                    )
                  : Row(
                      children: [
                        Expanded(child: input),
                        const SizedBox(width: 10),
                        actions,
                      ],
                    );
            },
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: usage.clamp(0, 1),
            color: _referenceGreen,
            backgroundColor: _referenceCell,
            borderRadius: AppRadius.full,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.mkcloudUsage(result.count, result.limit),
                style: context.textTheme.bodySmall,
              ),
            ),
          ),
          const Divider(height: 24),
          _IpTableHeader(),
          for (final (index, entry) in result.entries.indexed) ...[
            const Divider(height: 1),
            _IpTableRow(index: index + 1, entry: entry),
          ],
        ],
      ),
    );
  }
}

class _IpTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.appLocalizations;
    return Row(
      children: [
        const SizedBox(width: 32, child: Text('#')),
        Expanded(
          flex: 3,
          child: Text(
            l10n.mkcloudIpAddress,
            style: context.textTheme.labelMedium,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            l10n.mkcloudAddedAt,
            style: context.textTheme.labelMedium,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(l10n.mkcloudSource, style: context.textTheme.labelMedium),
        ),
        const SizedBox(width: 40),
      ],
    );
  }
}

class _IpTableRow extends ConsumerWidget {
  const _IpTableRow({required this.index, required this.entry});
  final int index;
  final MkcloudWhitelistEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox(
          width: 32,
          child: Text('$index', style: context.textTheme.bodySmall),
        ),
        Expanded(flex: 3, child: Text(entry.cidr)),
        Expanded(
          flex: 3,
          child: Text(
            entry.createdAt?.toLocal().toString() ??
                context.appLocalizations.mkcloudLegacyEntry,
            style: context.textTheme.bodySmall,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            context.appLocalizations.mkcloudLocal,
            style: context.textTheme.bodySmall,
          ),
        ),
        SizedBox(
          width: 40,
          child: IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 19),
            onPressed: () => unawaited(
              ref.read(mkcloudFirewallProvider.notifier).deleteIp(entry.cidr),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProvinceDialog extends StatefulWidget {
  const _ProvinceDialog({required this.provinces});
  final List<MkcloudProvince> provinces;
  @override
  State<_ProvinceDialog> createState() => _ProvinceDialogState();
}

class _ProvinceDialogState extends State<_ProvinceDialog> {
  String? selected;
  @override
  Widget build(BuildContext context) {
    final l10n = context.appLocalizations;
    return AlertDialog(
      title: Text(l10n.mkcloudSelectProvince),
      content: SizedBox(
        width: 440,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final province in widget.provinces)
              ChoiceChip(
                label: Text(province.label),
                selected: selected == province.value,
                onSelected: (_) => setState(() => selected = province.value),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: selected == null
              ? null
              : () => Navigator.pop(context, selected),
          child: Text(l10n.mkcloudSetProvince),
        ),
      ],
    );
  }
}
