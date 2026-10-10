import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProxiesSettingsSidePanel extends StatelessWidget {
  const ProxiesSettingsSidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.appLocalizations.settings,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.appLocalizations.close,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: glass.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: glass.separator.withValues(alpha: 0.7)),
          const Expanded(child: ProxiesSetting()),
        ],
      ),
    );
  }
}

class ProxiesSetting extends StatelessWidget {
  const ProxiesSetting({super.key});

  IconData _getIconWithProxiesType(ProxiesType type) {
    return switch (type) {
      ProxiesType.tab => Icons.view_carousel_rounded,
      ProxiesType.list => Icons.view_list_rounded,
    };
  }

  IconData _getIconWithProxiesSortType(ProxiesSortType type) {
    return switch (type) {
      ProxiesSortType.none => Icons.sort_rounded,
      ProxiesSortType.delay => Icons.network_ping_rounded,
      ProxiesSortType.name => Icons.sort_by_alpha_rounded,
    };
  }

  String _getStringProxiesSortType(BuildContext context, ProxiesSortType type) {
    final appLocalizations = context.appLocalizations;
    return switch (type) {
      ProxiesSortType.none => appLocalizations.defaultText,
      ProxiesSortType.delay => appLocalizations.delay,
      ProxiesSortType.name => appLocalizations.name,
    };
  }

  String getTextForProxiesLayout(
    BuildContext context,
    ProxiesLayout proxiesLayout,
  ) {
    final appLocalizations = context.appLocalizations;
    return switch (proxiesLayout) {
      ProxiesLayout.tight => appLocalizations.tight,
      ProxiesLayout.standard => appLocalizations.standard,
      ProxiesLayout.loose => appLocalizations.loose,
    };
  }

  String _getTextWithProxiesIconStyle(
    BuildContext context,
    ProxiesIconStyle style,
  ) {
    final appLocalizations = context.appLocalizations;
    return switch (style) {
      ProxiesIconStyle.standard => appLocalizations.standard,
      ProxiesIconStyle.none => appLocalizations.none,
      ProxiesIconStyle.icon => appLocalizations.onlyIcon,
    };
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProxySettingSection(
            title: appLocalizations.style,
            child: Consumer(
              builder: (_, ref, _) {
                final selected = ref.watch(
                  proxiesStyleSettingProvider.select((state) => state.type),
                );
                return _SegmentedSetting<ProxiesType>(
                  values: ProxiesType.values,
                  selected: selected,
                  labelOf: (item) => item.label,
                  iconOf: _getIconWithProxiesType,
                  onChanged: (item) {
                    ref
                        .read(proxiesStyleSettingProvider.notifier)
                        .update((state) => state.copyWith(type: item));
                  },
                );
              },
            ),
          ),
          _ProxySettingSection(
            title: appLocalizations.sort,
            child: Consumer(
              builder: (_, ref, _) {
                final selected = ref.watch(
                  proxiesStyleSettingProvider.select((state) => state.sortType),
                );
                return _SegmentedSetting<ProxiesSortType>(
                  values: ProxiesSortType.values,
                  selected: selected,
                  labelOf: (item) => _getStringProxiesSortType(context, item),
                  iconOf: _getIconWithProxiesSortType,
                  onChanged: (item) {
                    ref
                        .read(proxiesStyleSettingProvider.notifier)
                        .update((state) => state.copyWith(sortType: item));
                  },
                );
              },
            ),
          ),
          _ProxySettingSection(
            title: appLocalizations.layout,
            child: Consumer(
              builder: (_, ref, _) {
                final selected = ref.watch(
                  proxiesStyleSettingProvider.select((state) => state.layout),
                );
                return _SegmentedSetting<ProxiesLayout>(
                  values: ProxiesLayout.values,
                  selected: selected,
                  labelOf: (item) => getTextForProxiesLayout(context, item),
                  onChanged: (item) {
                    ref
                        .read(proxiesStyleSettingProvider.notifier)
                        .update((state) => state.copyWith(layout: item));
                  },
                );
              },
            ),
          ),
          _ProxySettingSection(
            title: appLocalizations.size,
            child: Consumer(
              builder: (_, ref, _) {
                final selected = ref.watch(
                  proxiesStyleSettingProvider.select((state) => state.cardType),
                );
                return _SegmentedSetting<ProxyCardType>(
                  values: ProxyCardType.values,
                  selected: selected,
                  labelOf: (item) => item.label,
                  onChanged: (item) {
                    ref
                        .read(proxiesStyleSettingProvider.notifier)
                        .update((state) => state.copyWith(cardType: item));
                  },
                );
              },
            ),
          ),
          Consumer(
            builder: (_, ref, _) {
              final isList = ref.watch(
                proxiesStyleSettingProvider.select(
                  (state) => state.type == ProxiesType.list,
                ),
              );
              if (!isList) {
                return const SizedBox.shrink();
              }
              final selected = ref.watch(
                proxiesStyleSettingProvider.select((state) => state.iconStyle),
              );
              return _ProxySettingSection(
                title: appLocalizations.iconStyle,
                child: _SegmentedSetting<ProxiesIconStyle>(
                  values: ProxiesIconStyle.values,
                  selected: selected,
                  labelOf: (item) =>
                      _getTextWithProxiesIconStyle(context, item),
                  onChanged: (item) {
                    ref
                        .read(proxiesStyleSettingProvider.notifier)
                        .update((state) => state.copyWith(iconStyle: item));
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProxySettingSection extends StatelessWidget {
  const _ProxySettingSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 7),
            child: Text(
              title,
              style: context.textTheme.labelLarge?.copyWith(
                color: glass.secondaryLabel,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SegmentedSetting<T> extends StatelessWidget {
  const _SegmentedSetting({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.iconOf,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final IconData Function(T value)? iconOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: glass.fill.withValues(alpha: glass.isDark ? 0.72 : 0.82),
        borderRadius: AppRadius.all(10),
        border: Border.all(color: glass.separator.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            for (final value in values)
              Expanded(
                child: _SegmentedSettingItem(
                  label: labelOf(value),
                  icon: iconOf?.call(value),
                  selected: value == selected,
                  onTap: () => onChanged(value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedSettingItem extends StatelessWidget {
  const _SegmentedSettingItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final colorScheme = context.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.all(8),
        child: AnimatedContainer(
          duration: Durations.short3,
          curve: Curves.easeOutCubic,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    colorScheme.primary.withValues(
                      alpha: glass.isDark ? 0.16 : 0.10,
                    ),
                    glass.card,
                  )
                : Colors.transparent,
            borderRadius: AppRadius.all(8),
            border: selected
                ? Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.8),
                    width: 1,
                  )
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: glass.shadow.withValues(alpha: 0.12),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 17,
                  color: selected ? colorScheme.primary : glass.secondaryLabel,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? null : glass.secondaryLabel,
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
