import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

import 're_editor_completion.dart';

class MihomoAutocompletePopup extends StatefulWidget
    implements PreferredSizeWidget {
  static const double itemHeight = 36;
  final ValueNotifier<CodeAutocompleteEditingValue> notifier;
  final ValueChanged<CodeAutocompleteResult> onSelected;

  const MihomoAutocompletePopup({
    super.key,
    required this.notifier,
    required this.onSelected,
  });

  @override
  Size get preferredSize => Size(
    360,
    math.min(itemHeight * notifier.value.prompts.length + 12, 240),
  );

  @override
  State<MihomoAutocompletePopup> createState() =>
      _MihomoAutocompletePopupState();
}

class _MihomoAutocompletePopupState extends State<MihomoAutocompletePopup> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_handleChanged);
  }

  @override
  void didUpdateWidget(covariant MihomoAutocompletePopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(_handleChanged);
      widget.notifier.addListener(_handleChanged);
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_handleChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final index = widget.notifier.value.index;
      final top = index * MihomoAutocompletePopup.itemHeight;
      final bottom = top + MihomoAutocompletePopup.itemHeight;
      final position = _scrollController.position;
      if (top < position.pixels) {
        position.jumpTo(top);
      } else if (bottom > position.pixels + position.viewportDimension) {
        position.jumpTo(bottom - position.viewportDimension);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.notifier.value;
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 8,
      color: colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: widget.preferredSize.width,
        height: widget.preferredSize.height,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemExtent: MihomoAutocompletePopup.itemHeight,
          itemCount: value.prompts.length,
          itemBuilder: (context, index) {
            final prompt = value.prompts[index];
            final selected = index == value.index;
            final detail = prompt is MihomoCodePrompt ? prompt.detail : '';
            return InkWell(
              canRequestFocus: false,
              onTap: () => widget.onSelected(
                value.copyWith(index: index).autocomplete,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: selected ? colorScheme.secondaryContainer : null,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        prompt.word,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? colorScheme.onSecondaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 12,
                            color: selected
                                ? colorScheme.onSecondaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
