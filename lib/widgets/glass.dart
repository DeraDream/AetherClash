import 'dart:ui' as ui;

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:material_ui/material_ui.dart';

class AppFloor extends StatelessWidget {
  const AppFloor({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: context.glass.background, child: child);
  }
}

/// [tile] is an opaque content cell; [panel] is a floating glass panel over
/// the floor; [chrome] is glass that content scrolls beneath, so it blurs.
enum GlassKind { panel, tile, chrome }

ui.ImageFilter _liquidFilter(double sigma) {
  const s = GlassStyle.saturation;
  const r = 0.2126 * (1 - s);
  const g = 0.7152 * (1 - s);
  const b = 0.0722 * (1 - s);
  return ui.ImageFilter.compose(
    outer: const ui.ColorFilter.matrix([
      r + s, g, b, 0, 0, //
      r, g + s, b, 0, 0, //
      r, g, b + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ]),
    inner: ui.ImageFilter.blur(
      sigmaX: sigma,
      sigmaY: sigma,
      tileMode: TileMode.mirror,
    ),
  );
}

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    this.kind = GlassKind.tile,
    this.borderRadius,
    this.padding = EdgeInsets.zero,
    this.selected = false,
    this.color,
    this.rimColor,
    this.elevated,
    this.blur,
    this.clip = true,
    this.circle = false,
    this.plain = false,
    required this.child,
  });

  final GlassKind kind;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final bool selected;
  final Color? color;
  final Color? rimColor;
  final bool? elevated;
  final bool? blur;
  final bool clip;
  final bool circle;

  /// Only clips and hosts ink, drawing nothing of its own.
  final bool plain;
  final Widget child;

  static BorderRadius radiusOf(GlassKind kind) => switch (kind) {
    GlassKind.panel => AppRadius.medium,
    GlassKind.tile => AppRadius.small,
    GlassKind.chrome => AppRadius.large,
  };

  static OutlinedBorder shapeOf({
    required GlassKind kind,
    BorderRadius? borderRadius,
    bool circle = false,
  }) => circle
      ? const CircleBorder()
      : RoundedSuperellipseBorder(borderRadius: borderRadius ?? radiusOf(kind));

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final shape = shapeOf(
      kind: kind,
      borderRadius: borderRadius,
      circle: circle,
    );
    final padded = Padding(padding: padding, child: child);
    if (plain) {
      return ClipPath.shape(shape: shape, child: padded);
    }
    final isGlass = kind != GlassKind.tile;
    final accent = context.colorScheme.primary;
    final base = color ?? (isGlass ? glass.glass : glass.card);
    final fill = selected
        ? Color.alphaBlend(
            accent.withValues(alpha: glass.isDark ? 0.2 : 0.1),
            base,
          )
        : base;
    final rim =
        rimColor ??
        (selected ? accent.withValues(alpha: 0.7) : null) ??
        (isGlass ? null : Colors.transparent);
    Widget content = CustomPaint(
      painter: _FillPainter(shape: shape, fill: fill),
      foregroundPainter: rim == Colors.transparent
          ? null
          : _SpecularRimPainter(
              shape: shape,
              light: rim ?? glass.rimLight,
              shade: rim ?? glass.rimShade,
              width: selected ? 1.5 : 1,
            ),
      child: padded,
    );
    if (blur ?? kind == GlassKind.chrome) {
      content = BackdropFilter(
        filter: _liquidFilter(glass.blurSigma),
        child: content,
      );
    }
    if (clip || (blur ?? kind == GlassKind.chrome)) {
      content = ClipPath.shape(shape: shape, child: content);
    }
    if (!(elevated ?? isGlass)) {
      return content;
    }
    return CustomPaint(
      painter: _OuterShadowPainter(shape: shape, color: glass.shadow),
      child: content,
    );
  }
}

class _FillPainter extends CustomPainter {
  const _FillPainter({required this.shape, required this.fill});

  final ShapeBorder shape;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      shape.getOuterPath(Offset.zero & size),
      Paint()..color = fill,
    );
  }

  @override
  bool shouldRepaint(_FillPainter oldDelegate) =>
      shape != oldDelegate.shape || fill != oldDelegate.fill;
}

class _SpecularRimPainter extends CustomPainter {
  const _SpecularRimPainter({
    required this.shape,
    required this.light,
    required this.shade,
    required this.width,
  });

  final ShapeBorder shape;
  final Color light;
  final Color shade;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    canvas.drawPath(
      shape.getOuterPath(rect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            light,
            shade,
            shade,
            light.withValues(alpha: light.a * 0.6),
          ],
          stops: const [0, 0.35, 0.7, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SpecularRimPainter oldDelegate) =>
      shape != oldDelegate.shape ||
      light != oldDelegate.light ||
      shade != oldDelegate.shade ||
      width != oldDelegate.width;
}

/// A shadow clipped to the outside of the shape, so translucent glass is not
/// darkened by the shadow beneath it.
class _OuterShadowPainter extends CustomPainter {
  const _OuterShadowPainter({required this.shape, required this.color});

  static const _blur = 20.0;
  static const _offset = Offset(0, 6);

  final ShapeBorder shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getOuterPath(rect);
    canvas.save();
    canvas.clipPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(rect.inflate(_blur * 3))
        ..addPath(path, Offset.zero),
    );
    canvas.drawPath(
      path.shift(_offset),
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _blur / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterShadowPainter oldDelegate) =>
      shape != oldDelegate.shape || color != oldDelegate.color;
}

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.kind = GlassKind.tile,
    this.borderRadius,
    this.padding = EdgeInsets.zero,
    this.selected = false,
    this.color,
    this.rimColor,
    this.elevated,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
    this.circle = false,
    this.plain = false,
    required this.child,
  });

  final bool circle;
  final bool plain;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final GlassKind kind;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final bool selected;
  final Color? color;
  final Color? rimColor;
  final bool? elevated;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? tooltip;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final button = GlassSurface(
      kind: kind,
      borderRadius: borderRadius,
      circle: circle,
      plain: plain,
      selected: selected,
      color: color,
      rimColor: rimColor,
      elevated: elevated,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          onSecondaryTap: onSecondaryTap,
          focusNode: focusNode,
          autofocus: autofocus,
          customBorder: GlassSurface.shapeOf(
            kind: kind,
            borderRadius: borderRadius,
            circle: circle,
          ),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.onSurface.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.focused)) {
              return colorScheme.primary.withValues(alpha: 0.12);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.onSurface.withValues(alpha: 0.04);
            }
            return null;
          }),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    final tooltip = this.tooltip;
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

class GlassIconBadge extends StatelessWidget {
  const GlassIconBadge({
    super.key,
    required this.icon,
    this.color,
    this.size = 30,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: color ?? context.colorScheme.primary,
        shape: RoundedSuperellipseBorder(
          borderRadius: AppRadius.all(size * 0.28),
        ),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Icon(icon, size: size * 0.6, color: Colors.white),
      ),
    );
  }
}

class GlassSectionLabel extends StatelessWidget {
  const GlassSectionLabel(
    this.label, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 22, 12, 8),
  });

  final String label;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.glass.secondaryLabel,
                fontSize: 13,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A tinted capsule for short states: delays, results, counts.
class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.monospace = false,
  });

  final String label;
  final Color? color;
  final IconData? icon;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.colorScheme.primary;
    final icon = this.icon;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: accent.withValues(alpha: context.glass.isDark ? 0.22 : 0.12),
        shape: AppShape.full,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              maxLines: 1,
              style: context.textTheme.labelMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
                fontFamily: monospace ? FontFamily.jetBrainsMono.value : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 32,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: size * 0.56),
      style: IconButton.styleFrom(
        fixedSize: Size.square(size),
        minimumSize: Size.square(size),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        foregroundColor: color ?? context.glass.secondaryLabel,
      ),
    );
  }
}
