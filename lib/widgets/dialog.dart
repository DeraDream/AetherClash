import 'dart:math';

import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/common/shape.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommonDialog extends ConsumerWidget {
  final String title;
  final Widget? child;
  final List<Widget>? actions;
  final EdgeInsets? padding;
  final bool overrideScroll;
  final Color? backgroundColor;

  const CommonDialog({
    super.key,
    required this.title,
    this.actions,
    this.child,
    this.padding,
    this.overrideScroll = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, ref) {
    final size = ref.watch(viewSizeProvider);
    final desktop = size.width >= 600;
    final colorScheme = Theme.of(context).colorScheme;
    final effectivePadding =
        padding ??
        (desktop
            ? const EdgeInsets.fromLTRB(14, 6, 14, 14)
            : null);
    return AlertDialog(
      title: Text(
        title,
        style: desktop
            ? context.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              )
            : null,
      ),
      titlePadding: desktop
          ? const EdgeInsets.fromLTRB(22, 20, 22, 8)
          : null,
      actions: actions,
      actionsPadding: desktop
          ? const EdgeInsets.fromLTRB(14, 0, 14, 14)
          : null,
      contentPadding: effectivePadding,
      insetPadding: desktop
          ? const EdgeInsets.symmetric(horizontal: 24, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      backgroundColor:
          backgroundColor ?? (desktop ? colorScheme.surface : null),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: desktop
          ? RoundedRectangleBorder(
              borderRadius: AppRadius.small,
              side: BorderSide(color: context.glass.separator),
            )
          : null,
      content: Container(
        constraints: BoxConstraints(
          maxHeight: min(size.height - 56, desktop ? 560 : 500),
          maxWidth: desktop ? 380 : 300,
        ),
        width: min(size.width - 48, desktop ? 380 : 300),
        child: !overrideScroll ? SingleChildScrollView(child: child) : child,
      ),
    );
  }
}

class CommonModal extends ConsumerWidget {
  final Widget? child;

  const CommonModal({super.key, this.child});

  @override
  Widget build(BuildContext context, ref) {
    final size = ref.watch(viewSizeProvider);
    return Center(
      child: Container(
        width: size.width * 0.85,
        height: size.height * 0.85,
        decoration: const ShapeDecoration(shape: AppShape.extraLarge),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
