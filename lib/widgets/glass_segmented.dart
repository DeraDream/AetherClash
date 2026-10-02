import 'package:fl_clash/common/common.dart';
import 'package:material_ui/material_ui.dart';

/// A recessed track with a lifted thumb that slides to the chosen segment.
class GlassSegmented<T> extends StatelessWidget {
  const GlassSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.iconOf,
    this.height = 40,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final IconData Function(T value)? iconOf;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final compact = MediaQuery.sizeOf(context).width >= 600;
    final shape = compact ? AppShape.extraSmall : AppShape.full;
    final index = values.indexOf(selected);
    final count = values.length;
    final duration = context.motionDuration(Durations.medium2);
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: ShapeDecoration(color: glass.fill, shape: shape),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (index >= 0)
                AnimatedAlign(
                  duration: duration,
                  curve: Easing.emphasizedDecelerate,
                  alignment: Alignment(
                    count == 1 ? 0 : -1 + 2 * index / (count - 1),
                    0,
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 1 / count,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: glass.thumb,
                        shape: shape,
                        shadows: compact
                            ? const []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: glass.isDark ? 0.3 : 0.12,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                    ),
                  ),
                ),
              Material(
                type: MaterialType.transparency,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final value in values)
                      Expanded(
                        child: _Segment(
                          label: labelOf(value),
                          icon: iconOf?.call(value),
                          selected: value == selected,
                          borderRadius: compact
                              ? AppRadius.extraSmall
                              : AppRadius.full,
                          onTap: () {
                            if (value != selected) {
                              onChanged(value);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.borderRadius,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = context.colorScheme.onSurface;
    final icon = this.icon;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        customBorder: AppShape.of(borderRadius),
        overlayColor: WidgetStatePropertyAll(
          color.withValues(alpha: selected ? 0 : 0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
