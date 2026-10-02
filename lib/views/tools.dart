import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/about.dart';
import 'package:fl_clash/views/access.dart';
import 'package:fl_clash/views/activity.dart';
import 'package:fl_clash/views/application_setting.dart';
import 'package:fl_clash/views/backup_and_restore.dart';
import 'package:fl_clash/views/config/config.dart';
import 'package:fl_clash/views/hotkey.dart';
import 'package:fl_clash/views/resources.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' show dirname, join;

import 'config/advanced.dart';
import 'developer.dart';
import 'theme.dart';

/// Settings keep the app shell visible on desktop: sub-pages are pushed into
/// this local navigator instead of appearing as a narrow modal side sheet.
class ToolsView extends ConsumerWidget {
  const ToolsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = ref.watch(isMobileViewProvider);
    if (isMobile) {
      return const _ToolsBoard();
    }
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => const _ToolsBoard(),
      ),
    );
  }
}

class _ToolsBoard extends ConsumerWidget {
  const _ToolsBoard();

  static const _maxWidth = 860.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final developerMode = ref.watch(
      appSettingProvider.select((state) => state.developerMode),
    );
    final isMobile = ref.watch(isMobileViewProvider);
    final sections = <(String, List<Widget>)>[
      if (isMobile)
        (
          appLocalizations.activity,
          [
            _SettingTile(
              icon: Icons.insights_rounded,
              tone: GlassTone.pink,
              title: appLocalizations.activity,
              subtitle: appLocalizations.activityDesc,
              onTap: (context) =>
                  BaseNavigator.push(context, const ActivityView()),
            ),
          ],
        ),
      (
        appLocalizations.appearance,
        [
          _SettingTile.page(
            icon: Icons.palette_outlined,
            tone: GlassTone.indigo,
            title: appLocalizations.theme,
            subtitle: appLocalizations.themeDesc,
            page: const ThemeView(),
          ),
          const _LocaleTile(),
        ],
      ),
      (
        appLocalizations.networkAndCore,
        [
          _SettingTile.page(
            icon: Icons.tune_rounded,
            tone: GlassTone.accent,
            title: appLocalizations.basicConfig,
            subtitle: appLocalizations.basicConfigDesc,
            page: const ConfigView(),
          ),
          _SettingTile.page(
            icon: Icons.build_outlined,
            tone: GlassTone.neutral,
            title: appLocalizations.advancedConfig,
            subtitle: appLocalizations.advancedConfigDesc,
            page: const AdvancedConfigView(),
          ),
          if (system.isAndroid)
            _SettingTile.page(
              icon: Icons.apps_outlined,
              tone: GlassTone.success,
              title: appLocalizations.accessControl,
              subtitle: appLocalizations.accessControlDesc,
              page: const AccessView(),
            ),
          if (system.isWindows)
            _SettingTile(
              icon: Icons.lock_open_rounded,
              tone: GlassTone.warning,
              title: appLocalizations.loopback,
              subtitle: appLocalizations.loopbackDesc,
              onTap: (_) => windows?.runas(
                '"${join(dirname(Platform.resolvedExecutable), "EnableLoopback.exe")}"',
                '',
              ),
            ),
        ],
      ),
      (
        appLocalizations.system,
        [
          _SettingTile.page(
            icon: Icons.settings_outlined,
            tone: GlassTone.neutral,
            title: appLocalizations.application,
            subtitle: appLocalizations.applicationDesc,
            page: const ApplicationSettingView(),
          ),
          if (system.isDesktop)
            _SettingTile.page(
              icon: Icons.keyboard_outlined,
              tone: GlassTone.neutral,
              title: appLocalizations.hotkeyManagement,
              subtitle: appLocalizations.hotkeyManagementDesc,
              page: const HotKeyView(),
            ),
          _SettingTile.page(
            icon: Icons.cloud_sync_outlined,
            tone: GlassTone.teal,
            title: appLocalizations.backupAndRestore,
            subtitle: appLocalizations.backupAndRestoreDesc,
            page: const BackupAndRestore(),
          ),
          _SettingTile.page(
            icon: Icons.storage_outlined,
            tone: GlassTone.warning,
            title: appLocalizations.resources,
            subtitle: appLocalizations.resourcesDesc,
            page: const ResourcesView(),
          ),
        ],
      ),
      (
        appLocalizations.other,
        [
          const _DisclaimerTile(),
          if (developerMode)
            _SettingTile.page(
              icon: Icons.developer_board_outlined,
              tone: GlassTone.neutral,
              title: appLocalizations.developerMode,
              page: const DeveloperView(),
            ),
          _SettingTile.page(
            icon: Icons.info_outline_rounded,
            tone: GlassTone.accent,
            title: appLocalizations.about,
            subtitle: appName,
            page: const AboutView(),
          ),
        ],
      ),
    ];
    return CommonScaffold(
      title: appLocalizations.settings,
      body: ListView(
        key: toolsStoreKey,
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 20,
          0,
          isMobile ? 16 : 20,
          24 + BottomInsetScope.of(context),
        ),
        children: [
          for (final (title, tiles) in sections)
            if (tiles.isNotEmpty)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxWidth),
                  child: _TileSection(title: title, tiles: tiles),
                ),
              ),
        ],
      ),
    );
  }
}

class _TileSection extends StatelessWidget {
  const _TileSection({required this.title, required this.tiles});

  static const _separatorIndent = 58.0;

  final String title;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSectionLabel(title),
        GlassSurface(
          borderRadius: AppRadius.small,
          elevated: false,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                for (final (index, tile) in tiles.indexed) ...[
                  if (index > 0)
                    const Divider(height: 0.5, indent: _separatorIndent),
                  tile,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.tone,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  _SettingTile.page({
    required this.icon,
    required this.tone,
    required this.title,
    this.subtitle,
    required Widget page,
  }) : onTap = ((context) {
         if (context.isMobileView) {
           showExtend(context, builder: (_) => page);
           return;
         }
         BaseNavigator.push(context, page);
       });

  final IconData icon;
  final GlassTone tone;
  final String title;
  final String? subtitle;
  final void Function(BuildContext context) onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final glass = context.glass;
    final desktop = MediaQuery.sizeOf(context).width >= 600;
    final toneColor = context.toneColor(tone);
    final leading = desktop
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: toneColor.withValues(alpha: 0.10),
              borderRadius: AppRadius.extraSmall,
            ),
            child: SizedBox.square(
              dimension: 34,
              child: Icon(icon, size: 19, color: toneColor),
            ),
          )
        : GlassIconBadge(icon: icon, color: toneColor);
    return InkWell(
      onTap: () => onTap(context),
      borderRadius: AppRadius.extraSmall,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          desktop ? 14 : 16,
          desktop ? 11 : 10,
          desktop ? 12 : 10,
          desktop ? 11 : 10,
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: desktop
                        ? context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )
                        : context.textTheme.bodyLarge,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: glass.secondaryLabel,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: desktop ? 20 : 24,
              color: glass.secondaryLabel.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocaleTile extends ConsumerWidget {
  const _LocaleTile();

  String _labelOf(BuildContext context, Locale? locale) {
    if (locale == null) return context.appLocalizations.defaultText;
    return locale.label;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final locale = getLocaleForString(
      ref.watch(appSettingProvider.select((state) => state.locale)),
    );
    return _SettingTile(
      icon: Icons.translate_rounded,
      tone: GlassTone.accent,
      title: appLocalizations.language,
      subtitle: _labelOf(context, locale),
      onTap: (context) async {
        final result = await dialogs.showCommonDialog<_LocaleChoice>(
          child: OptionsDialog<_LocaleChoice>(
            title: appLocalizations.language,
            options: [
              const _LocaleChoice(null),
              for (final locale in AppLocalizations.delegate.supportedLocales)
                _LocaleChoice(locale),
            ],
            textBuilder: (choice) => _labelOf(context, choice.locale),
            value: _LocaleChoice(locale),
          ),
        );
        if (result == null) {
          return;
        }
        ref
            .read(appSettingProvider.notifier)
            .update(
              (state) => state.copyWith(locale: result.locale?.toString()),
            );
      },
    );
  }
}

/// Wraps the optional locale so the dialog can tell "follow the system" apart
/// from being dismissed, which both arrive as null otherwise.
@immutable
class _LocaleChoice {
  const _LocaleChoice(this.locale);

  final Locale? locale;

  @override
  bool operator ==(Object other) =>
      other is _LocaleChoice && other.locale == locale;

  @override
  int get hashCode => locale.hashCode;
}

class _DisclaimerTile extends ConsumerWidget {
  const _DisclaimerTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SettingTile(
      icon: Icons.gavel_rounded,
      tone: GlassTone.neutral,
      title: context.appLocalizations.disclaimer,
      onTap: (_) async {
        final isDisclaimerAccepted = await dialogs.showDisclaimer();
        if (!isDisclaimerAccepted) {
          await ref.read(systemActionProvider.notifier).handleExit();
        }
      },
    );
  }
}
