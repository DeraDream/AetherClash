import 'dart:async';
import 'dart:math';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'card.dart';
import 'common.dart';

typedef GroupNameProxiesMap = Map<String, List<Proxy>>;

const _enterStaggerLimit = 8;
const _enterStaggerStep = Duration(milliseconds: 20);
const _enterSlideBase = 32.0;
const _enterSlideStep = 8.0;
final _enterWindow = Durations.medium2 + _enterStaggerStep * _enterStaggerLimit;
const _desktopGroupHeaderHeight = 72.0;
const _desktopGroupToolbarHeight = 34.0;

class ProxiesListView extends ConsumerStatefulWidget {
  const ProxiesListView({super.key});

  @override
  ConsumerState<ProxiesListView> createState() => _ProxiesListViewState();
}

class _ProxiesListViewState extends ConsumerState<ProxiesListView> {
  final _controller = ScrollController();
  GroupOffsets _groupOffsets = GroupOffsets.empty;
  double containerHeight = 0;
  String? _enterGroupName;
  Timer? _enterTimer;

  @override
  void dispose() {
    _stopEnterAnimated();
    _controller.dispose();
    super.dispose();
  }

  void _startEnterAnimated(String groupName) {
    _enterTimer?.cancel();
    _enterGroupName = groupName;
    _enterTimer = Timer(_enterWindow, _stopEnterAnimated);
  }

  void _stopEnterAnimated() {
    _enterTimer?.cancel();
    _enterTimer = null;
    _enterGroupName = null;
  }

  void _handleChange(
    Set<String> currentUnfoldSet,
    String groupName, {
    required bool compact,
  }) {
    _autoScrollToGroup(groupName, compact: compact);
    final tempUnfoldSet = Set<String>.from(currentUnfoldSet);
    if (tempUnfoldSet.contains(groupName)) {
      tempUnfoldSet.remove(groupName);
      _stopEnterAnimated();
    } else {
      tempUnfoldSet.add(groupName);
      _startEnterAnimated(groupName);
    }
    ref
        .read(proxiesActionProvider.notifier)
        .updateCurrentUnfoldSet(tempUnfoldSet);
  }

  GroupOffsets _getGroupOffsets({
    required List<Group> groups,
    required int columns,
    required Set<String> currentUnfoldSet,
    required ProxyCardType cardType,
    required bool compact,
  }) {
    final offsets = <double>[];
    final rowExtent = getItemHeight(cardType, compact: compact) + 8;
    final headerHeight = compact ? _desktopGroupHeaderHeight : listHeaderHeight;
    var currentOffset = 0.0;
    for (final group in groups) {
      offsets.add(currentOffset);
      currentOffset += headerHeight + 8;
      if (currentUnfoldSet.contains(group.name)) {
        if (compact) {
          currentOffset += _desktopGroupToolbarHeight;
        }
        final rowCount = (group.all.length + columns - 1) ~/ columns;
        currentOffset += rowCount * rowExtent;
      }
    }
    return GroupOffsets(groups, offsets);
  }

  Widget _buildProxyRow({
    required Group group,
    required List<Proxy> proxies,
    required int rowIndex,
    required int columns,
    required ProxyCardType cardType,
    required bool compact,
  }) {
    final groupName = group.name;
    final enterAnimated = _enterGroupName == groupName;
    final children = proxies.indexed
        .map<Widget>((entry) {
          final (columnIndex, proxy) = entry;
          final card = SizedBox(
            height: getItemHeight(cardType, compact: compact),
            child: ProxyCard(
              testUrl: group.testUrl,
              type: cardType,
              groupType: group.type,
              key: ValueKey('$groupName.${proxy.name}'),
              proxy: proxy,
              groupName: groupName,
              compact: compact,
            ),
          );
          if (!enterAnimated) {
            return Flexible(child: card);
          }
          final stagger = min(
            rowIndex * columns + columnIndex,
            _enterStaggerLimit,
          );
          return Flexible(
            child: FadeSlideEnterBox(
              delay: _enterStaggerStep * stagger,
              distance: _enterSlideBase + _enterSlideStep * stagger,
              child: card,
            ),
          );
        })
        .fill(columns, filler: (_) => const Flexible(child: SizedBox()))
        .separated(const SizedBox(width: 8));
    return Padding(
      padding: EdgeInsets.only(
        left: compact ? 12 : 16,
        right: compact ? 12 : 16,
        bottom: 8,
      ),
      child: Row(children: children.toList()),
    );
  }

  Widget _buildGroup(
    BuildContext context, {
    required Group group,
    required Set<String> currentUnfoldSet,
    required int columns,
    required ProxyCardType cardType,
    required bool compact,
  }) {
    final groupName = group.name;
    final isExpand = currentUnfoldSet.contains(groupName);
    final rows = isExpand
        ? group.all.chunks(columns).toList()
        : const <List<Proxy>>[];
    return SliverMainAxisGroup(
      slivers: [
        PinnedHeaderSliver(
          child: ColoredBox(
            color: context.colorScheme.surface,
            child: Padding(
              padding: EdgeInsets.only(
                left: compact ? 12 : 16,
                right: compact ? 12 : 16,
                bottom: 8,
              ),
              child: SizedBox(
                height: compact ? _desktopGroupHeaderHeight : listHeaderHeight,
                child: ListHeader(
                  enterAnimated: false,
                  onScrollToSelected: (groupName) {
                    _scrollToGroupSelected(
                      groupName,
                      columns,
                      compact: compact,
                    );
                  },
                  key: ValueKey(groupName),
                  isExpand: isExpand,
                  group: group,
                  compact: compact,
                  onChange: (groupName) {
                    _handleChange(
                      currentUnfoldSet,
                      groupName,
                      compact: compact,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (isExpand && compact)
          SliverToBoxAdapter(
            child: SizedBox(
              height: _desktopGroupToolbarHeight,
              child: _DesktopGroupToolbar(
                group: group,
                onScrollToSelected: () {
                  _scrollToGroupSelected(groupName, columns, compact: compact);
                },
              ),
            ),
          ),
        if (isExpand)
          SliverFixedExtentList(
            itemExtent: getItemHeight(cardType, compact: compact) + 8,
            delegate: SliverChildBuilderDelegate(
              (_, index) => _buildProxyRow(
                group: group,
                proxies: rows[index],
                rowIndex: index,
                columns: columns,
                cardType: cardType,
                compact: compact,
              ),
              childCount: rows.length,
            ),
          ),
      ],
    );
  }

  double _getGroupOffset(String groupName) {
    if (!_controller.hasClients ||
        _controller.position.maxScrollExtent == 0 ||
        _groupOffsets.isEmpty) {
      return 0;
    }
    return _groupOffsets.offsetOf(groupName);
  }

  void _scrollToMakeVisibleWithPadding({
    required double containerHeight,
    required double pixels,
    required double start,
    required double end,
    double padding = 24,
  }) {
    final visibleStart = pixels;
    final visibleEnd = pixels + containerHeight;

    final isElementVisible = start >= visibleStart && end <= visibleEnd;
    if (isElementVisible) {
      return;
    }

    double targetScrollOffset;

    if (end <= visibleStart) {
      targetScrollOffset = start;
    } else if (start >= visibleEnd) {
      targetScrollOffset = end - containerHeight + padding;
    } else {
      final visibleTopPart = end - visibleStart;
      final visibleBottomPart = visibleEnd - start;
      if (visibleTopPart.abs() >= visibleBottomPart.abs()) {
        targetScrollOffset = end - containerHeight + padding;
      } else {
        targetScrollOffset = start;
      }
    }

    targetScrollOffset = targetScrollOffset.clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );

    _controller.jumpTo(targetScrollOffset);
  }

  void _autoScrollToGroup(String groupName, {required bool compact}) {
    final pixels = _controller.position.pixels;
    final offset = _getGroupOffset(groupName);
    _scrollToMakeVisibleWithPadding(
      containerHeight: containerHeight,
      pixels: pixels,
      start: offset,
      end: offset + (compact ? _desktopGroupHeaderHeight : listHeaderHeight),
    );
  }

  void _scrollToGroupSelected(
    String groupName,
    int columns, {
    required bool compact,
  }) {
    final currentInitOffset = _getGroupOffset(groupName);
    final proxies = _groupOffsets.groupOf(groupName)?.all;
    _jumpTo(
      currentInitOffset +
          8 +
          (compact ? _desktopGroupToolbarHeight : 0) +
          getScrollToSelectedOffset(
            ref: ref,
            groupName: groupName,
            proxies: proxies ?? [],
            columns: columns,
            compact: compact,
          ),
    );
  }

  void _jumpTo(double offset) {
    if (mounted && _controller.hasClients) {
      _controller.animateTo(
        offset.clamp(
          _controller.position.minScrollExtent,
          _controller.position.maxScrollExtent,
        ),
        duration: Durations.medium2,
        curve: Easing.standard,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return Consumer(
      builder: (_, ref, _) {
        final state = ref.watch(proxiesListStateProvider);
        ref.watch(themeSettingProvider.select((state) => state.textScale));
        final proxiesLayout = ref.watch(
          proxiesStyleSettingProvider.select((state) => state.layout),
        );
        return NullStatusSwitcher(
          isEmpty: state.groups.isEmpty,
          nullStatus: NullStatus(
            illustration: NullStatusIllustration.proxies,
            label: appLocalizations.nullTip(appLocalizations.proxies),
          ),
          child: LayoutBuilder(
            builder: (_, constraints) {
              final compact = !context.isMobileView;
              final columns = getProxiesColumns(
                max(constraints.maxWidth - (compact ? 24 : 32), 0),
                proxiesLayout,
              );
              _groupOffsets = _getGroupOffsets(
                groups: state.groups,
                currentUnfoldSet: state.currentUnfoldSet,
                columns: columns,
                cardType: state.proxyCardType,
                compact: compact,
              );
              containerHeight = max(constraints.maxHeight - 16, 0);
              return CommonScrollBar(
                controller: _controller,
                thumbVisibility: true,
                trackVisibility: true,
                child: Padding(
                  padding: EdgeInsets.only(top: compact ? 10 : 16),
                  child: ScrollConfiguration(
                    behavior: const HiddenBarScrollBehavior(),
                    child: CustomScrollView(
                      key: proxiesListStoreKey,
                      controller: _controller,
                      slivers: [
                        for (final group in state.groups)
                          _buildGroup(
                            context,
                            group: group,
                            currentUnfoldSet: state.currentUnfoldSet,
                            columns: columns,
                            cardType: state.proxyCardType,
                            compact: compact,
                          ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 16 + BottomInsetScope.of(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ListHeader extends ConsumerStatefulWidget {
  final Group group;

  final Function(String groupName) onChange;
  final Function(String groupName) onScrollToSelected;
  final bool isExpand;

  final bool enterAnimated;
  final bool compact;

  const ListHeader({
    super.key,
    this.enterAnimated = true,
    required this.group,
    required this.onChange,
    required this.onScrollToSelected,
    required this.isExpand,
    this.compact = false,
  });

  @override
  ConsumerState<ListHeader> createState() => _ListHeaderState();
}

class _ListHeaderState extends ConsumerState<ListHeader> {
  var isLock = false;

  String get icon => widget.group.icon;

  String get groupName => widget.group.name;

  String get groupType => widget.group.type.name;

  bool get isExpand => widget.isExpand;

  Future<void> _delayTest() async {
    if (isLock) return;
    isLock = true;
    try {
      await ref
          .read(proxiesActionProvider.notifier)
          .delayTest(widget.group.all, widget.group.testUrl);
    } finally {
      isLock = false;
    }
  }

  void _handleChange(String groupName) {
    widget.onChange(groupName);
  }

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      enterActionsOnRight: true,
      enterAnimated: widget.enterAnimated,
      key: widget.key,
      type: CommonCardType.filled,
      radius: widget.compact ? AppCorner.extraSmall : null,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 14 : 16,
          vertical: widget.compact ? 11 : 12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  _GroupIcon(src: icon, compact: widget.compact),
                  Flexible(
                    child: _GroupSummary(
                      groupName: groupName,
                      groupType: groupType,
                      compact: widget.compact,
                    ),
                  ),
                ],
              ),
            ),
            _GroupActions(
              isExpand: isExpand,
              groupType: groupType,
              count: widget.group.all.length,
              compact: widget.compact,
              onScrollToSelected: () {
                widget.onScrollToSelected(groupName);
              },
              onDelayTest: _delayTest,
              onToggle: () {
                _handleChange(groupName);
              },
            ),
          ],
        ),
      ),
      onPressed: () {
        _handleChange(groupName);
      },
    );
  }
}

class _DesktopGroupToolbar extends ConsumerWidget {
  const _DesktopGroupToolbar({
    required this.group,
    required this.onScrollToSelected,
  });

  final Group group;
  final VoidCallback onScrollToSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glass = context.glass;
    final primary = context.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: glass.fill,
          borderRadius: AppRadius.extraSmall,
        ),
        child: SizedBox(
          height: _desktopGroupToolbarHeight - 4,
          child: Row(
            children: [
              IconButton(
                tooltip: context.appLocalizations.scrollToSelected,
                visualDensity: VisualDensity.compact,
                onPressed: onScrollToSelected,
                iconSize: 18,
                color: primary,
                icon: const Icon(Icons.my_location_rounded),
              ),
              IconButton(
                tooltip: context.appLocalizations.delayTest,
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  ref
                      .read(proxiesActionProvider.notifier)
                      .delayTest(group.all, group.testUrl);
                },
                iconSize: 19,
                color: primary,
                icon: const Icon(Icons.network_ping_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupIcon extends ConsumerWidget {
  const _GroupIcon({required this.src, required this.compact});

  final String src;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconStyle = ref.watch(
      proxiesStyleSettingProvider.select((state) => state.iconStyle),
    );
    if (compact) {
      if (iconStyle == ProxiesIconStyle.none) {
        return const SizedBox(width: 2);
      }
      return Container(
        width: 30,
        margin: const EdgeInsets.only(right: 10),
        alignment: Alignment.center,
        child: IconTheme.merge(
          data: const IconThemeData(size: 21),
          child: CommonTargetIcon(src: src),
        ),
      );
    }
    return switch (iconStyle) {
      ProxiesIconStyle.standard => LayoutBuilder(
        builder: (_, constraints) {
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                height: constraints.maxHeight,
                width: constraints.maxWidth,
                alignment: Alignment.center,
                padding: EdgeInsets.all(6.ap),
                decoration: ShapeDecoration(
                  color: context.colorScheme.secondaryContainer,
                  shape: AppShape.medium,
                ),
                clipBehavior: Clip.antiAlias,
                child: IconTheme.merge(
                  data: IconThemeData(size: constraints.maxHeight - 12.ap),
                  child: CommonTargetIcon(src: src),
                ),
              ),
            ),
          );
        },
      ),
      ProxiesIconStyle.icon => Container(
        margin: const EdgeInsets.only(right: 8),
        child: LayoutBuilder(
          builder: (_, constraints) {
            return IconTheme.merge(
              data: IconThemeData(size: constraints.maxHeight - 8.ap),
              child: CommonTargetIcon(src: src),
            );
          },
        ),
      ),
      ProxiesIconStyle.none => Container(),
    };
  }
}

class _GroupSummary extends StatelessWidget {
  const _GroupSummary({
    required this.groupName,
    required this.groupType,
    required this.compact,
  });

  final String groupName;
  final String groupType;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmojiText(groupName, style: context.textTheme.titleMedium),
          const SizedBox(height: 4),
          Flexible(flex: 1, child: _SelectedProxyName(groupName: groupName)),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EmojiText(
          groupName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: AppRadius.all(4),
                border: Border.all(
                  color: context.colorScheme.primary.withValues(alpha: 0.45),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                child: Text(
                  groupType,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.primary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(child: _SelectedProxyName(groupName: groupName)),
          ],
        ),
      ],
    );
  }
}

class _SelectedProxyName extends ConsumerWidget {
  const _SelectedProxyName({required this.groupName});

  final String groupName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proxyName = ref
        .watch(selectedProxyNameProvider(groupName))
        .takeFirstValid([]);
    if (proxyName.isEmpty) {
      return const SizedBox.shrink();
    }
    return EmojiText(
      proxyName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.textTheme.labelSmall?.toLight,
    );
  }
}

class _GroupActions extends StatelessWidget {
  const _GroupActions({
    required this.isExpand,
    required this.groupType,
    required this.count,
    required this.compact,
    required this.onScrollToSelected,
    required this.onDelayTest,
    required this.onToggle,
  });

  static const _shrinkWrap = ButtonStyle(
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  final bool isExpand;
  final String groupType;
  final int count;
  final bool compact;
  final VoidCallback onScrollToSelected;
  final VoidCallback onDelayTest;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: AppRadius.all(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              child: Text(
                '$count',
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: isExpand
                ? context.appLocalizations.showLess
                : context.appLocalizations.showMore,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            iconSize: 20,
            style: _shrinkWrap,
            onPressed: onToggle,
            icon: Icon(
              isExpand
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        if (isExpand) ...[
          IconButton(
            tooltip: context.appLocalizations.scrollToSelected,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(2),
            onPressed: onScrollToSelected,
            style: _shrinkWrap,
            iconSize: 19,
            icon: const Icon(Icons.adjust),
          ),
          const SizedBox(width: 2),
          IconButton(
            tooltip: context.appLocalizations.delayTest,
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(2),
            onPressed: onDelayTest,
            style: _shrinkWrap,
            icon: const Icon(Icons.network_ping),
          ),
          const SizedBox(width: 6),
        ] else ...[
          Text(groupType, style: context.textTheme.labelMedium?.toLight),
          const SizedBox(width: 6),
        ],
        IconButton.filledTonal(
          tooltip: isExpand
              ? context.appLocalizations.showLess
              : context.appLocalizations.showMore,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(2),
          iconSize: 24,
          style: _shrinkWrap,
          onPressed: onToggle,
          icon: CommonExpandIcon(expand: isExpand),
        ),
      ],
    );
  }
}
