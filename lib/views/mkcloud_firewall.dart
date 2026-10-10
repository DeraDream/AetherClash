import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/mkcloud_firewall.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _maxContentWidth = 920.0;

class MkcloudFirewallView extends StatelessWidget {
  const MkcloudFirewallView({super.key});

  @override
  Widget build(BuildContext context) => BaseScaffold(
    title: context.appLocalizations.mkcloudFirewall,
    body: ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        24 + BottomInsetScope.of(context),
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Overview(),
                SizedBox(height: 12),
                _AutomationSettings(),
                SizedBox(height: 12),
                _ApiKeyTile(),
                SizedBox(height: 12),
                _Rules(),
                SizedBox(height: 12),
                _DirectTip(),
              ],
            ),
          ),
        ),
      ],
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
    final ipMode = result?.mode == 'ip';
    final provinceMode = result?.mode == 'province';
    final title = ipMode
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
    final subtitle = provinceMode
        ? l10n.mkcloudCurrentProvince(result?.province ?? '-')
        : ipMode
        ? l10n.mkcloudUsage(result?.count ?? 0, result?.limit ?? 10)
        : state.lastRunAt == null
        ? l10n.mkcloudNeverRun
        : l10n.mkcloudLastRun(state.lastRunAt!.toLocal().toString());
    final notifier = ref.read(mkcloudFirewallProvider.notifier);
    return GlassSurface(
      borderRadius: AppRadius.large,
      padding: const EdgeInsets.all(20),
      child: Wrap(
        runSpacing: 16,
        spacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          GlassIconBadge(
            icon: ipMode ? Icons.public_rounded : Icons.map_rounded,
          ),
          SizedBox(
            width: 380,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(subtitle, style: context.textTheme.bodyMedium),
                if (setting.enable) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.mkcloudPollEvery(setting.pollSeconds),
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: ready && !state.isRunning
                    ? () => unawaited(notifier.query())
                    : null,
                icon: const Icon(Icons.travel_explore_rounded),
                label: Text(l10n.mkcloudQueryStatus),
              ),
              if (result?.mode != null)
                OutlinedButton.icon(
                  onPressed: ready && !state.isRunning
                      ? () => ipMode
                            ? _showProvinceDialog(context, ref, result!)
                            : unawaited(notifier.switchToIp())
                      : null,
                  icon: Icon(ipMode ? Icons.map_rounded : Icons.public_rounded),
                  label: Text(
                    ipMode ? l10n.mkcloudSwitchProvince : l10n.mkcloudSwitchIp,
                  ),
                ),
              FilledButton.icon(
                onPressed: ready && !state.isRunning
                    ? () => unawaited(notifier.whitelist())
                    : null,
                icon: const Icon(Icons.bolt_rounded),
                label: Text(l10n.mkcloudWhitelistNow),
              ),
            ],
          ),
        ],
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
    if (selected != null)
      unawaited(
        ref.read(mkcloudFirewallProvider.notifier).setProvince(selected),
      );
  }
}

class _AutomationSettings extends ConsumerWidget {
  const _AutomationSettings();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.appLocalizations;
    final setting = ref.watch(mkcloudFirewallSettingProvider);
    final notifier = ref.read(mkcloudFirewallSettingProvider.notifier);
    return Column(
      children: [
        GlassButton(
          padding: const EdgeInsets.all(16),
          onTap: () => notifier.update((it) => it.copyWith(enable: !it.enable)),
          child: Row(
            children: [
              const GlassIconBadge(icon: Icons.autorenew_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.mkcloudAutoWhitelist,
                      style: context.textTheme.titleSmall,
                    ),
                    Text(
                      l10n.mkcloudAutoWhitelistDesc,
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(
                value: setting.enable,
                onChanged: (value) =>
                    notifier.update((it) => it.copyWith(enable: value)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GlassButton(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          onTap: () => _editInterval(context, ref, setting.pollSeconds),
          child: Row(
            children: [
              const GlassIconBadge(icon: Icons.timer_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.mkcloudPollInterval,
                      style: context.textTheme.titleSmall,
                    ),
                    Text(
                      l10n.mkcloudPollEvery(setting.pollSeconds),
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_rounded, size: 18),
            ],
          ),
        ),
      ],
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
    if (value != null)
      ref
          .read(mkcloudFirewallSettingProvider.notifier)
          .update((it) => it.copyWith(pollSeconds: int.parse(value)));
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
    return GlassButton(
      padding: const EdgeInsets.all(16),
      onTap: () async {
        final value = await dialogs.showCommonDialog<String>(
          child: InputDialog(
            title: l10n.mkcloudApiKey,
            value: apiKey,
            obscureText: true,
          ),
        );
        if (value != null)
          ref
              .read(mkcloudFirewallSettingProvider.notifier)
              .update((it) => it.copyWith(apiKey: value.trim()));
      },
      child: Row(
        children: [
          const GlassIconBadge(icon: Icons.key_rounded),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.mkcloudApiKey, style: context.textTheme.titleSmall),
                Text(
                  apiKey.isEmpty
                      ? l10n.mkcloudKeyEmpty
                      : l10n.mkcloudKeyConfigured,
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.edit_rounded),
        ],
      ),
    );
  }
}

class _Rules extends ConsumerWidget {
  const _Rules();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.appLocalizations;
    final state = ref.watch(mkcloudFirewallProvider);
    final result = state.result;
    if (result == null || result.type == MkcloudResultType.error)
      return const SizedBox.shrink();
    if (result.mode == 'province')
      return GlassSurface(
        borderRadius: AppRadius.medium,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.mkcloudProvinceRule,
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.mkcloudCurrentProvince(result.province ?? '-')),
            const SizedBox(height: 8),
            Text(l10n.mkcloudProvinceHint, style: context.textTheme.bodySmall),
          ],
        ),
      );
    if (result.mode != 'ip') return const SizedBox.shrink();
    return GlassSurface(
      borderRadius: AppRadius.medium,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.mkcloudIpRule(result.count, result.limit),
            style: context.textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          for (final entry in result.entries) _IpRow(entry: entry),
          const Divider(),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: state.isRunning ? null : () => _addIp(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.mkcloudAddIp),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addIp(BuildContext context, WidgetRef ref) async {
    final l10n = context.appLocalizations;
    final ip = await dialogs.showCommonDialog<String>(
      child: InputDialog(
        title: l10n.mkcloudAddIp,
        value: '',
        hintText: l10n.mkcloudIpHint,
        keyboardType: TextInputType.number,
        validator: (value) =>
            isIpv4(value ?? '') ? null : l10n.mkcloudInvalidIp,
      ),
    );
    if (ip != null)
      unawaited(ref.read(mkcloudFirewallProvider.notifier).addIp(ip));
  }
}

class _IpRow extends ConsumerWidget {
  const _IpRow({required this.entry});
  final MkcloudWhitelistEntry entry;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.cidr),
            Text(
              entry.createdAt?.toLocal().toString() ??
                  context.appLocalizations.mkcloudLegacyEntry,
              style: context.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      IconButton(
        icon: const Icon(Icons.delete_outline_rounded),
        onPressed: () => unawaited(
          ref.read(mkcloudFirewallProvider.notifier).deleteIp(entry.cidr),
        ),
      ),
    ],
  );
}

class _DirectTip extends StatelessWidget {
  const _DirectTip();
  @override
  Widget build(BuildContext context) => GlassSurface(
    borderRadius: AppRadius.medium,
    padding: const EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            context.appLocalizations.mkcloudDirectTip,
            style: context.textTheme.bodySmall,
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
