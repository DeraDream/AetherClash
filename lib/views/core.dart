import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/desktop/core_manifest.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/runtime_config.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class CoreView extends ConsumerWidget {
  const CoreView({super.key});

  String _statusLabel(BuildContext context, CoreStatus status) {
    final appLocalizations = context.appLocalizations;
    return switch (status) {
      CoreStatus.connecting => appLocalizations.connecting,
      CoreStatus.connected => appLocalizations.connected,
      CoreStatus.disconnected => appLocalizations.disconnected,
    };
  }

  GlassTone _statusTone(CoreStatus status) {
    return switch (status) {
      CoreStatus.connecting => GlassTone.accent,
      CoreStatus.connected => GlassTone.success,
      CoreStatus.disconnected => GlassTone.danger,
    };
  }

  IconData _statusIcon(CoreStatus status) {
    return switch (status) {
      CoreStatus.connecting => Icons.sync_rounded,
      CoreStatus.connected => Icons.check_circle_outline_rounded,
      CoreStatus.disconnected => Icons.power_settings_new_rounded,
    };
  }

  Future<void> _handleCoreAction(
    BuildContext context,
    WidgetRef ref,
    CoreStatus status,
  ) async {
    if (status == CoreStatus.connecting) {
      return;
    }
    final appLocalizations = context.appLocalizations;
    final isConnected = status == CoreStatus.connected;
    final confirmed = await dialogs.showMessage(
      message: TextSpan(
        text: isConnected
            ? appLocalizations.forceRestartCoreTip
            : appLocalizations.restartCoreTip,
      ),
    );
    if (confirmed != true) {
      return;
    }
    await globalState.safeRun<void>(
      () async {
        final action = ref.read(coreActionProvider.notifier);
        if (isConnected) {
          await action.restartCore();
        } else {
          await action.startCore();
        }
      },
      title: appLocalizations.core,
      silence: false,
    );
  }

  Future<void> _checkUpdate(BuildContext context, WidgetRef ref) async {
    final data = await globalState.safeRun<Map<String, dynamic>?>(
      request.checkForUpdate,
      title: context.appLocalizations.checkUpdate,
    );
    unawaited(
      ref
          .read(commonActionProvider.notifier)
          .checkUpdateResultHandle(data: data, isUser: true),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final status = ref.watch(coreStatusProvider);
    final toneColor = context.toneColor(_statusTone(status));
    final bottom = BottomInsetScope.of(context);

    return CommonScaffold(
      title: appLocalizations.core,
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + bottom),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassSurface(
                    borderRadius: AppRadius.small,
                    elevated: false,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: toneColor.withValues(alpha: 0.12),
                              borderRadius: AppRadius.all(12),
                            ),
                            child: SizedBox.square(
                              dimension: 48,
                              child: Icon(
                                _statusIcon(status),
                                size: 25,
                                color: toneColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Po0ClashCore',
                                  style: context.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${appLocalizations.coreStatus}: '
                                  '${_statusLabel(context, status)}',
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: status == CoreStatus.connecting
                                ? null
                                : () => _handleCoreAction(context, ref, status),
                            icon: Icon(
                              status == CoreStatus.connected
                                  ? Icons.restart_alt_rounded
                                  : Icons.play_arrow_rounded,
                              size: 18,
                            ),
                            label: Text(
                              status == CoreStatus.connected
                                  ? appLocalizations.restart
                                  : appLocalizations.start,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GlassSurface(
                    borderRadius: AppRadius.small,
                    elevated: false,
                    child: Column(
                      children: [
                        _CoreInfoRow(
                          icon: Icons.layers_outlined,
                          title: appLocalizations.core,
                          subtitle:
                              '${appLocalizations.source}: '
                              '$appName ${globalState.packageInfo.version}',
                          trailing: Text(
                            globalState.packageInfo.version,
                            style: context.textTheme.labelLarge?.copyWith(
                              color: context.colorScheme.primary,
                            ),
                          ),
                        ),
                        const Divider(height: 0.5, indent: 58),
                        _CoreInfoRow(
                          icon: Icons.folder_outlined,
                          title: appLocalizations.file,
                          subtitle: appPath.corePath,
                        ),
                        const Divider(height: 0.5, indent: 58),
                        const _CoreFingerprintRow(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  GlassSurface(
                    borderRadius: AppRadius.small,
                    elevated: false,
                    child: Column(
                      children: [
                        _CoreActionRow(
                          icon: Icons.restart_alt_rounded,
                          title: appLocalizations.restart,
                          subtitle: appLocalizations.coreStatus,
                          onTap: status == CoreStatus.connecting
                              ? null
                              : () => _handleCoreAction(context, ref, status),
                        ),
                        const Divider(height: 0.5, indent: 58),
                        _CoreActionRow(
                          icon: Icons.code_rounded,
                          title:
                              Localizations.localeOf(context).languageCode ==
                                  'zh'
                              ? '运行时配置'
                              : 'Runtime config',
                          subtitle:
                              Localizations.localeOf(context).languageCode ==
                                  'zh'
                              ? '查看最终送入 mihomo 的 YAML 配置'
                              : 'View the final YAML passed to mihomo',
                          onTap: () => BaseNavigator.push(
                            context,
                            const RuntimeConfigView(),
                          ),
                        ),
                        const Divider(height: 0.5, indent: 58),
                        _CoreActionRow(
                          icon: Icons.system_update_alt_rounded,
                          title: appLocalizations.checkUpdate,
                          subtitle: '${appLocalizations.source}: $appName',
                          onTap: () => _checkUpdate(context, ref),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoreInfoRow extends StatelessWidget {
  const _CoreInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.glass.secondaryLabel),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class _CoreFingerprintRow extends StatelessWidget {
  const _CoreFingerprintRow();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: CoreManifest.readCoreSha256(),
      builder: (context, snapshot) {
        return _CoreInfoRow(
          icon: Icons.fingerprint_rounded,
          title: 'SHA-256',
          subtitle: snapshot.data ?? '-',
        );
      },
    );
  }
}

class _CoreActionRow extends StatelessWidget {
  const _CoreActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.glass.secondaryLabel,
            ),
          ],
        ),
      ),
    );
  }
}
