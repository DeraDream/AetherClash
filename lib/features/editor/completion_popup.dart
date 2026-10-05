import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

class EditorCompletionPopup extends StatefulWidget
    implements PreferredSizeWidget {
  const EditorCompletionPopup({
    super.key,
    required this.notifier,
    required this.onSelected,
  });

  final ValueNotifier<CodeAutocompleteEditingValue> notifier;
  final ValueChanged<CodeAutocompleteResult> onSelected;

  static const double _itemHeight = 36;
  static const double _width = 340;

  @override
  Size get preferredSize => Size(
    _width,
    math.min(notifier.value.prompts.length, 8) * _itemHeight + 8,
  );

  @override
  State<EditorCompletionPopup> createState() => _EditorCompletionPopupState();
}

class _EditorCompletionPopupState extends State<EditorCompletionPopup> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_handleChanged);
  }

  @override
  void didUpdateWidget(covariant EditorCompletionPopup oldWidget) {
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
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final index = widget.notifier.value.index;
      final top = index * EditorCompletionPopup._itemHeight;
      final bottom = top + EditorCompletionPopup._itemHeight;
      final position = _scrollController.position;
      var target = position.pixels;
      if (top < position.pixels) {
        target = top;
      } else if (bottom > position.pixels + position.viewportDimension) {
        target = bottom - position.viewportDimension;
      }
      if (target != position.pixels) {
        _scrollController.jumpTo(
          target.clamp(position.minScrollExtent, position.maxScrollExtent),
        );
      }
    });
  }

  String _detail(CodePrompt prompt) {
    if (prompt is CodeFieldPrompt) return prompt.type;
    if (prompt is CodeFunctionPrompt) return prompt.type;
    return '';
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
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(4),
        itemExtent: EditorCompletionPopup._itemHeight,
        itemCount: value.prompts.length,
        itemBuilder: (context, index) {
          final prompt = value.prompts[index];
          final selected = index == value.index;
          final detail = _detail(prompt);
          return InkWell(
            borderRadius: BorderRadius.circular(7),
            onTap: () => widget.onSelected(
              value.copyWith(index: index).autocomplete,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: selected ? colorScheme.secondaryContainer : null,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      prompt.word,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (detail.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
    );
  }
}
