import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProxyCard extends ConsumerWidget {
  final String groupName;
  final Proxy proxy;
  final GroupType groupType;
  final ProxyCardType type;
  final String? testUrl;
  final bool compact;

  const ProxyCard({
    super.key,
    required this.groupName,
    required this.testUrl,
    required this.proxy,
    required this.groupType,
    required this.type,
    this.compact = false,
  });

  Measure get measure => globalState.measure;

  void _handleTestCurrentDelay(WidgetRef ref) {
    ref.read(proxiesActionProvider.notifier).proxyDelayTest(proxy, testUrl);
  }

  Widget _buildDelayText() {
    return SizedBox(
      height: measure.labelSmallHeight,
      child: Consumer(
        builder: (context, ref, _) {
          final delay = ref.watch(
            delayProvider(proxyName: proxy.name, testUrl: testUrl),
          );
          final pending = ref.watch(
            delayTestPendingProvider(proxyName: proxy.name, testUrl: testUrl),
          );
          return FadeBox(
            alignment: type == ProxyCardType.expand
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: pending || delay == null
                ? SizedBox(
                    height: measure.labelSmallHeight,
                    width: measure.labelSmallHeight,
                    child: pending
                        ? const CommonCircleLoading()
                        : IconButton(
                            tooltip: context.appLocalizations.delayTest,
                            icon: const Icon(Icons.bolt),
                            iconSize: globalState.measure.labelSmallHeight,
                            padding: EdgeInsets.zero,
                            onPressed: () => _handleTestCurrentDelay(ref),
                          ),
                  )
                : GestureDetector(
                    onTap: () => _handleTestCurrentDelay(ref),
                    child: Text(
                      delay > 0 ? '$delay ms' : 'Timeout',
                      maxLines: 1,
                      style: context.textTheme.labelSmall?.copyWith(
                        overflow: TextOverflow.ellipsis,
                        color: getDelayColor(delay),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildProxyNameText(BuildContext context) {
    final lines = type == ProxyCardType.min || compact ? 1 : 2;
    return SizedBox(
      height: measure.bodyMediumHeight * lines,
      child: EmojiText(
        proxy.name,
        maxLines: lines,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.bodyMedium?.copyWith(
          fontWeight: compact ? FontWeight.w500 : null,
        ),
      ),
    );
  }

  Future<void> _changeProxy(WidgetRef ref) async {
    final isComputedSelected = groupType.isComputedSelected;
    final isSelector = groupType == GroupType.Selector;
    if (isComputedSelected || isSelector) {
      final currentProxyName = ref.read(proxyNameProvider(groupName));
      final nextProxyName = switch (isComputedSelected) {
        true => currentProxyName == proxy.name ? '' : proxy.name,
        false => proxy.name,
      };
      ref
          .read(proxiesActionProvider.notifier)
          .changeProxyDebounce(groupName, nextProxyName);
      return;
    }
    dialogs.showNotifier(
      currentAppLocalizations.notSelectedTip,
      level: MessageLevel.warning,
    );
  }

  Widget _buildCompactCard(BuildContext context, WidgetRef ref) {
    final selectedProxyName = ref.watch(selectedProxyNameProvider(groupName));
    final selected = selectedProxyName == proxy.name;
    final colorScheme = context.colorScheme;
    final glass = context.glass;
    return ClipRRect(
      borderRadius: AppRadius.all(7),
      child: Material(
        color: selected
            ? Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.16),
                glass.card,
              )
            : glass.card,
        child: InkWell(
          onTap: () {
            _changeProxy(ref);
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EmojiText(
                            proxy.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: selected
                                  ? colorScheme.primary.withValues(alpha: 0.08)
                                  : glass.fill,
                              borderRadius: AppRadius.all(4),
                              border: Border.all(color: glass.separator),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              child: Text(
                                proxy.type,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: glass.secondaryLabel,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildDelayText(),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: ColoredBox(
                    color: colorScheme.primary,
                    child: const SizedBox(width: 3),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (compact) {
      return _buildCompactCard(context, ref);
    }
    final measure = globalState.measure;
    final delayText = _buildDelayText();
    final proxyNameText = _buildProxyNameText(context);
    return Stack(
      children: [
        Consumer(
          builder: (_, ref, child) {
            final selectedProxyName = ref.watch(
              selectedProxyNameProvider(groupName),
            );
            return CommonCard(
              key: key,
              onPressed: () {
                _changeProxy(ref);
              },
              isSelected: selectedProxyName == proxy.name,
              radius: compact ? AppCorner.small : null,
              child: child!,
            );
          },
          child: Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                proxyNameText,
                SizedBox(height: compact ? 6 : 8),
                if (type == ProxyCardType.expand) ...[
                  SizedBox(
                    height: measure.bodySmallHeight,
                    child: _ProxyDesc(proxy: proxy),
                  ),
                  SizedBox(height: compact ? 4 : 6),
                  delayText,
                ] else
                  SizedBox(
                    height: measure.bodySmallHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          flex: 1,
                          child: TooltipText(
                            text: Text(
                              proxy.type,
                              maxLines: 1,
                              style: context.textTheme.bodySmall?.copyWith(
                                overflow: TextOverflow.ellipsis,
                                color: context
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.opacity80,
                              ),
                            ),
                          ),
                        ),
                        delayText,
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (groupType.isComputedSelected)
          Positioned(
            top: 0,
            right: 0,
            child: _ProxyComputedMark(groupName: groupName, proxy: proxy),
          ),
      ],
    );
  }
}

class _ProxyDesc extends ConsumerWidget {
  final Proxy proxy;

  const _ProxyDesc({required this.proxy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desc = ref.watch(proxyDescProvider(proxy));
    return EmojiText(
      desc,
      overflow: TextOverflow.ellipsis,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.textTheme.bodySmall?.color?.opacity80,
      ),
    );
  }
}

class _ProxyComputedMark extends ConsumerWidget {
  final String groupName;
  final Proxy proxy;

  const _ProxyComputedMark({required this.groupName, required this.proxy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proxyName = ref.watch(proxyNameProvider(groupName));
    if (proxyName != proxy.name) {
      return const SizedBox();
    }
    return Container(
      alignment: Alignment.topRight,
      margin: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
        child: const SelectIcon(),
      ),
    );
  }
}
