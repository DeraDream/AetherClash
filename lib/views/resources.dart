import 'dart:async';
import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/pages/editor.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/core.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' hide context;

class ResourcesView extends ConsumerWidget {
  const ResourcesView({super.key});

  Future<void> _updateInterval(
    BuildContext context,
    WidgetRef ref,
    int updateInterval,
  ) async {
    final appLocalizations = context.appLocalizations;
    final value = await dialogs.showCommonDialog<String>(
      child: InputDialog(
        title: appLocalizations.geoAutoUpdateInterval,
        value: updateInterval.toString(),
        suffixText: appLocalizations.hours,
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return appLocalizations.emptyTip(
              appLocalizations.geoAutoUpdateInterval,
            );
          }
          final interval = int.tryParse(value);
          if (interval == null) {
            return appLocalizations.numberTip(
              appLocalizations.geoAutoUpdateInterval,
            );
          }
          if (interval <= 0) {
            return appLocalizations.geoAutoUpdateIntervalTip;
          }
          return null;
        },
      ),
    );
    final interval = int.tryParse(value ?? '');
    if (interval == null || interval <= 0) {
      return;
    }
    ref
        .read(patchClashConfigProvider.notifier)
        .update((state) => state.copyWith(geoUpdateInterval: interval));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const geoResources = GeoResource.values;
    final appLocalizations = context.appLocalizations;
    final geoSetting = ref.watch(
      patchClashConfigProvider.select(
        (state) => (
          autoUpdate: state.geoAutoUpdate,
          updateInterval: state.geoUpdateInterval,
        ),
      ),
    );

    void updateAutoUpdate(bool value) {
      ref
          .read(patchClashConfigProvider.notifier)
          .update((state) => state.copyWith(geoAutoUpdate: value));
    }

    return CommonScaffold(
      title: context.appLocalizations.resources,
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ).copyWith(bottom: 16),
        children: [
          generateSectionV3(
            title: appLocalizations.geoOptions,
            items: [
              DecorationListItem(
                minVerticalPadding: 8,
                contentPadding: const EdgeInsets.only(left: 16, right: 8),
                title: Text(appLocalizations.geoAutoUpdate),
                onPressed: () {
                  updateAutoUpdate(!geoSetting.autoUpdate);
                },
                trailing: Switch(
                  value: geoSetting.autoUpdate,
                  onChanged: updateAutoUpdate,
                ),
              ),
              DecorationListItem(
                minVerticalPadding: 8,
                title: Text(appLocalizations.geoAutoUpdateInterval),
                onPressed: () {
                  _updateInterval(context, ref, geoSetting.updateInterval);
                },
                trailing: Text(
                  appLocalizations.hoursCount(geoSetting.updateInterval),
                  style: context.textTheme.bodyMedium?.toSoftBold,
                ),
              ),
              const _GeoDataModeItem(),
              const _GeoDataLoaderItem(),
            ],
          ),
          generateSectionV3(
            title: appLocalizations.geoResources,
            items: [
              for (final geoResource in geoResources)
                _GeoResourceListItem(geoResource),
            ],
          ),
          const SizedBox(height: 18),
          const _RuleProvidersPanel(),
        ],
      ),
    );
  }
}

class _GeoResourceListItem extends ConsumerStatefulWidget {
  final GeoResource type;

  const _GeoResourceListItem(this.type);

  @override
  ConsumerState<_GeoResourceListItem> createState() =>
      _GeoResourceListItemState();
}

class _GeoResourceListItemState extends ConsumerState<_GeoResourceListItem> {
  late Future<FileInfo?> _fileInfoFuture;

  String get fileName {
    return switch (widget.type) {
      GeoResource.MMDB => MMDB,
      GeoResource.ASN => ASN,
      GeoResource.GEOIP => GEOIP,
      GeoResource.GEOSITE => GEOSITE,
    };
  }

  @override
  void initState() {
    super.initState();
    _fileInfoFuture = _getGeoFileInfo(fileName);
  }

  @override
  void didUpdateWidget(covariant _GeoResourceListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      _fileInfoFuture = _getGeoFileInfo(fileName);
    }
  }

  Future<void> _updateUrl(String url) async {
    final newUrl = await dialogs.showCommonDialog<String>(
      child: UpdateGeoUrlFormDialog(
        title: widget.type.name,
        url: url,
        defaultValue: defaultGeoXUrl[widget.type],
      ),
    );
    if (newUrl != null && newUrl != url && mounted) {
      try {
        ref
            .read(geoResourceActionProvider.notifier)
            .updateGeoResourceUrl(widget.type, newUrl);
      } catch (e) {
        unawaited(
          dialogs.showMessage(
            title: widget.type.name,
            message: TextSpan(text: e.toString()),
          ),
        );
      }
    }
  }

  Future<FileInfo?> _getGeoFileInfo(String fileName) async {
    final homePath = await appPath.homeDirPath;
    final file = File(join(homePath, fileName));
    return file.getFileInfo();
  }

  Future<void> _handleUpdateGeoDataItem() {
    return globalState.safeRun<void>(() async {
      await ref
          .read(geoResourceActionProvider.notifier)
          .updateGeoResource(widget.type);
    }, silence: false);
  }

  void _refreshFileInfo() {
    setState(() {
      _fileInfoFuture = _getGeoFileInfo(fileName);
    });
  }

  List<CommonPopupMenuItem> _menuItems(BuildContext context, String url) {
    final appLocalizations = context.appLocalizations;
    return [
      CommonPopupMenuItem(
        icon: Icons.edit_outlined,
        label: appLocalizations.edit,
        onPressed: () {
          _updateUrl(url);
        },
      ),
      CommonPopupMenuItem(
        icon: Icons.sync,
        label: appLocalizations.sync,
        onPressed: _handleUpdateGeoDataItem,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final updatingKey = widget.type.updatingKey;
    ref.listen(isUpdatingProvider(updatingKey), (previous, next) {
      if (previous == true && !next) {
        _refreshFileInfo();
      }
    });
    final isUpdating = ref.watch(isUpdatingProvider(updatingKey));
    final url = ref.watch(
      patchClashConfigProvider.select((state) => state.geoXUrl[widget.type]),
    );
    return FutureBuilder<FileInfo?>(
      future: _fileInfoFuture,
      builder: (context, snapshot) {
        final fileInfo = snapshot.data;
        return DecorationListItem(
          minVerticalPadding: 8,
          contentPadding: const EdgeInsets.only(left: 16, right: 0),
          title: Text(widget.type.name),
          subtitle: fileInfo == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 2),
                  child: Row(
                    spacing: 4,
                    children: [
                      MetaChip(label: fileInfo.size.traffic.show),
                      MetaChip(
                        label:
                            fileInfo.lastModified?.getLastUpdateTimeDesc(
                              context,
                            ) ??
                            context.appLocalizations.unknown,
                      ),
                    ],
                  ),
                ),
          trailing: url == null
              ? null
              : SizedBox.square(
                  dimension: kMinInteractiveDimension,
                  child: FadeThroughBox(
                    alignment: Alignment.center,
                    child: isUpdating
                        ? const SizedBox.square(
                            key: ValueKey('loading'),
                            dimension: kMinInteractiveDimension,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CommonCircleLoading(),
                            ),
                          )
                        : CommonPopupBox(
                            key: const ValueKey('menu'),
                            items: _menuItems(context, url),
                            targetBuilder: (open) {
                              return IconButton(
                                tooltip: context.appLocalizations.more,
                                onPressed: open,
                                icon: const Icon(Icons.more_vert),
                              );
                            },
                          ),
                  ),
                ),
        );
      },
    );
  }
}

class UpdateGeoUrlFormDialog extends StatelessWidget {
  final String title;
  final String url;
  final String? defaultValue;

  const UpdateGeoUrlFormDialog({
    super.key,
    required this.title,
    required this.url,
    this.defaultValue,
  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return InputDialog(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      title: title,
      value: url,
      resetValue: defaultValue,
      inputFormatters: TextInputLimits.limit(TextInputLimits.url),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return appLocalizations.emptyTip('').trim();
        }
        if (!value.isUrl) {
          return appLocalizations.urlTip('').trim();
        }
        return null;
      },
    );
  }
}


class _GeoDataModeItem extends ConsumerStatefulWidget {
  const _GeoDataModeItem();

  @override
  ConsumerState<_GeoDataModeItem> createState() => _GeoDataModeItemState();
}

class _GeoDataModeItemState extends ConsumerState<_GeoDataModeItem> {
  bool? _datMode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    preferences.getGeoDataMode().then((value) {
      if (mounted) {
        setState(() => _datMode = value);
      }
    });
  }

  Future<void> _change(bool value) async {
    if (_saving || _datMode == value) return;
    setState(() => _saving = true);
    try {
      await preferences.saveGeoDataMode(value);
      if (mounted) {
        setState(() => _datMode = value);
      }
      await ref.read(setupActionProvider.notifier).applyProfile(force: true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = _datMode;
    return DecorationListItem(
      minVerticalPadding: 8,
      title: Text(
        Localizations.localeOf(context).languageCode == 'zh'
            ? 'GeoData 数据模式'
            : 'GeoData mode',
      ),
      subtitle: Text(
        Localizations.localeOf(context).languageCode == 'zh'
            ? 'DB 使用 MMDB；DAT 使用 geoip.dat'
            : 'DB uses MMDB; DAT uses geoip.dat',
      ),
      trailing: value == null
          ? const SizedBox.square(
              dimension: 24,
              child: CommonCircleLoading(),
            )
          : SizedBox(
              width: 128,
              child: GlassSegmented<bool>(
                height: 34,
                values: const [false, true],
                selected: value,
                labelOf: (item) => item ? 'DAT' : 'DB',
                onChanged: _saving ? (_) {} : _change,
              ),
            ),
    );
  }
}

class _GeoDataLoaderItem extends ConsumerWidget {
  const _GeoDataLoaderItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loader = ref.watch(
      patchClashConfigProvider.select((state) => state.geodataLoader),
    );
    return DecorationListItem(
      minVerticalPadding: 8,
      title: Text(
        Localizations.localeOf(context).languageCode == 'zh'
            ? 'GeoData 加载模式'
            : 'GeoData loader',
      ),
      trailing: DropdownButton<GeodataLoader>(
        value: loader,
        underline: const SizedBox.shrink(),
        items: const [
          DropdownMenuItem(
            value: GeodataLoader.memconservative,
            child: Text('Memconservative'),
          ),
          DropdownMenuItem(
            value: GeodataLoader.standard,
            child: Text('Standard'),
          ),
        ],
        onChanged: (value) {
          if (value == null || value == loader) return;
          ref
              .read(patchClashConfigProvider.notifier)
              .update((state) => state.copyWith(geodataLoader: value));
          ref.read(setupActionProvider.notifier).applyProfile(force: true);
        },
      ),
    );
  }
}

class _RuleProvidersPanel extends ConsumerStatefulWidget {
  const _RuleProvidersPanel();

  @override
  ConsumerState<_RuleProvidersPanel> createState() =>
      _RuleProvidersPanelState();
}

class _RuleProvidersPanelState extends ConsumerState<_RuleProvidersPanel> {
  final _searchController = TextEditingController();
  Map<String, Map<String, dynamic>> _configs = const {};
  bool _loading = true;
  bool _updatingAll = false;

  String _text(String zh, String en) {
    return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(currentProfileIdProvider, (previous, next) {
      if (previous != next) {
        _reload();
      }
    });
    ref.listenManual(initProvider, (previous, next) {
      if (previous != next) {
        _reload();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (!mounted) return;
    if (!ref.read(initProvider)) {
      setState(() {
        _loading = false;
        _configs = const {};
      });
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(providersProvider.notifier).syncProviders();
      final profileId = ref.read(currentProfileIdProvider);
      Map<String, Map<String, dynamic>> configs = const {};
      if (profileId != null) {
        final raw = await ref.read(coreHandlerProvider).getConfig(profileId);
        final providers = raw['rule-providers'];
        if (providers is Map) {
          configs = {
            for (final entry in providers.entries)
              if (entry.value is Map)
                entry.key.toString(): Map<String, dynamic>.from(
                  entry.value as Map,
                ),
          };
        }
      }
      if (mounted) {
        setState(() => _configs = configs);
      }
    } catch (error) {
      if (mounted) {
        context.showNotifier(
          userFacingErrorMessage(error, context.appLocalizations),
          level: MessageLevel.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<ExternalProvider> _filteredProviders(List<ExternalProvider> all) {
    final query = _searchController.text.trim().toLowerCase();
    return all.where((provider) {
      if (provider.type != 'Rule') return false;
      if (query.isEmpty) return true;
      final config = _configs[provider.name] ?? const <String, dynamic>{};
      final text = [
        provider.name,
        provider.vehicleType,
        config['behavior'],
        config['format'],
        config['url'],
        config['path'],
      ].whereType<Object>().join(' ').toLowerCase();
      return text.contains(query);
    }).toList();
  }

  Future<void> _updateOne(ExternalProvider provider) async {
    await globalState.safeRun<void>(() async {
      final message = await ref
          .read(proxiesActionProvider.notifier)
          .updateProvider(provider, showLoading: true);
      if (message.isNotEmpty) throw MessageException(message);
    }, silence: false);
    await _reload();
  }

  Future<void> _updateAll(List<ExternalProvider> providers) async {
    if (_updatingAll) return;
    setState(() => _updatingAll = true);
    final messages = <UpdatingMessage>[];
    try {
      for (final provider in providers) {
        if (provider.vehicleType != 'HTTP') continue;
        try {
          final message = await ref
              .read(proxiesActionProvider.notifier)
              .updateProvider(provider, showLoading: true);
          if (message.isNotEmpty) {
            messages.add(
              UpdatingMessage(label: provider.name, message: message),
            );
          }
        } catch (error) {
          messages.add(
            UpdatingMessage(
              label: provider.name,
              message: userFacingErrorMessage(
                error,
                context.appLocalizations,
              ),
            ),
          );
        }
      }
      await _reload();
      if (messages.isNotEmpty) {
        unawaited(dialogs.showAllUpdatingMessagesDialog(messages));
      }
    } finally {
      if (mounted) {
        setState(() => _updatingAll = false);
      }
    }
  }

  Future<void> _openEditor(ExternalProvider provider) async {
    ExternalProviderContent content;
    try {
      content = await ref
          .read(coreHandlerProvider)
          .getExternalProviderContent(provider.name);
    } catch (error) {
      if (mounted) {
        context.showNotifier(
          userFacingErrorMessage(error, context.appLocalizations),
          level: MessageLevel.error,
        );
      }
      return;
    }
    if (!mounted) return;

    final isRemote = provider.vehicleType == 'HTTP';
    final readOnly = !content.editable;
    final format = content.format.toLowerCase();
    final titleSuffix = switch (format) {
      'mrs' => 'MRS',
      'inline' => 'INLINE',
      'text' => 'TEXT',
      _ => 'YAML',
    };

    BaseNavigator.push(
      context,
      EditorPage(
        title: '${provider.name} · $titleSuffix',
        content: content.data,
        languages: format == 'text' || format == 'mrs'
            ? const []
            : const [Language.yaml],
        actions: [
          if (readOnly)
            IconButton(
              tooltip: _text(
                format == 'mrs'
                    ? 'MRS 已解析为文本，仅供查看'
                    : '内联规则来自当前配置，仅供查看',
                format == 'mrs'
                    ? 'MRS is decoded to text and is read-only'
                    : 'Inline rules come from the current profile and are read-only',
              ),
              onPressed: () {
                context.showNotifier(
                  _text(
                    format == 'mrs'
                        ? 'MRS 为二进制格式，这里显示解析后的规则内容。'
                        : '内联规则属于当前配置，请在配置文件中修改。',
                    format == 'mrs'
                        ? 'MRS is binary; this view shows its decoded rules.'
                        : 'Inline rules belong to the current profile; edit them in the profile config.',
                  ),
                );
              },
              icon: const Icon(Icons.lock_outline_rounded),
            ),
          if (isRemote && !readOnly)
            IconButton(
              tooltip: _text(
                '远程规则集：下次更新会覆盖本地修改',
                'Remote rule-set: the next update overwrites local edits',
              ),
              onPressed: () {
                context.showNotifier(
                  _text(
                    '这是远程规则集，本地修改会在下次更新时被覆盖。',
                    'This is a remote rule-set. Local edits will be overwritten by the next update.',
                  ),
                  level: MessageLevel.warning,
                );
              },
              icon: const Icon(Icons.cloud_sync_outlined),
            ),
        ],
        onSave: readOnly
            ? null
            : (editorContext, _, nextContent) async {
                await globalState.safeRun<void>(() async {
                  final message = await ref
                      .read(proxiesActionProvider.notifier)
                      .sideLoadExternalProvider(
                        provider,
                        nextContent,
                        showLoading: true,
                      );
                  if (message.isNotEmpty) {
                    throw MessageException(message);
                  }
                }, silence: false);
                if (editorContext.mounted) {
                  editorContext.showNotifier(
                    _text(
                      isRemote
                          ? '已保存到本地缓存；下次远程更新会覆盖'
                          : '规则集已保存',
                      isRemote
                          ? 'Saved to local cache; the next remote update will overwrite it'
                          : 'Rule-set saved',
                    ),
                    level: MessageLevel.success,
                  );
                }
                await _reload();
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(providersProvider);
    final providers = _filteredProviders(all);
    final allRules = all.where((item) => item.type == 'Rule').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _text('规则集合', 'Rule providers'),
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _updatingAll || allRules.isEmpty
                    ? null
                    : () => _updateAll(allRules),
                icon: _updatingAll
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CommonCircleLoading(),
                      )
                    : const Icon(Icons.sync_rounded, size: 18),
                label: Text(_text('更新全部', 'Update all')),
              ),
            ],
          ),
        ),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          inputFormatters: TextInputLimits.limit(TextInputLimits.search),
          decoration: InputDecoration(
            hintText: _text('搜索规则集合', 'Search rule providers'),
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CommonCircleLoading()),
          )
        else if (providers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                _searchController.text.isEmpty
                    ? _text('当前配置没有规则集合', 'No rule providers in the current profile')
                    : _text('没有匹配的规则集合', 'No matching rule providers'),
              ),
            ),
          )
        else
          GlassSurface(
            borderRadius: AppRadius.small,
            elevated: false,
            child: Column(
              children: [
                for (final (index, provider) in providers.indexed) ...[
                  if (index > 0)
                    Divider(
                      height: 0.5,
                      indent: 14,
                      endIndent: 14,
                      color: context.glass.separator.withValues(alpha: 0.45),
                    ),
                  _RuleProviderResourceItem(
                    provider: provider,
                    config: _configs[provider.name] ?? const {},
                    onEdit: () => _openEditor(provider),
                    onRefresh: provider.vehicleType == 'HTTP'
                        ? () => _updateOne(provider)
                        : null,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _RuleProviderResourceItem extends ConsumerWidget {
  const _RuleProviderResourceItem({
    required this.provider,
    required this.config,
    required this.onEdit,
    required this.onRefresh,
  });

  final ExternalProvider provider;
  final Map<String, dynamic> config;
  final VoidCallback onEdit;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updating = ref.watch(isUpdatingProvider(provider.updatingKey));
    final behavior = config['behavior']?.toString().toUpperCase();
    final format = config['format']?.toString().toUpperCase();
    final url = config['url']?.toString();
    final metadata = <Widget>[
      MetaChip(label: provider.vehicleType),
      if (behavior?.isNotEmpty == true) MetaChip(label: behavior!),
      if (format?.isNotEmpty == true) MetaChip(label: format!),
      if (provider.count > 0)
        MetaChip(label: context.appLocalizations.rulesCount(provider.count)),
      if (provider.updateAt.microsecondsSinceEpoch > 0)
        MetaChip(label: provider.updateAt.getLastUpdateTimeDesc(context)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(spacing: 5, runSpacing: 5, children: metadata),
                if (url?.isNotEmpty == true) ...[
                  const SizedBox(height: 5),
                  Text(
                    url!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.glass.secondaryLabel,
                      fontFamily: FontFamily.jetBrainsMono.value,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: Localizations.localeOf(context).languageCode == 'zh'
                ? '查看 / 编辑'
                : 'View / edit',
            onPressed: onEdit,
            icon: const Icon(Icons.description_outlined),
          ),
          if (updating)
            const SizedBox.square(
              dimension: 40,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: CommonCircleLoading(),
              ),
            )
          else
            IconButton(
              tooltip: context.appLocalizations.sync,
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
    );
  }
}
