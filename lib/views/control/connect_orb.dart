import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The one control that starts and stops the proxy: a round glass button
/// that fills with the accent while running, labelled underneath.
class ConnectOrb extends ConsumerWidget {
  const ConnectOrb({super.key, this.size = 112});

  final double size;

  void _handleTap(WidgetRef ref, bool hasProfile) {
    if (!hasProfile) {
      ref.read(currentPageLabelProvider.notifier).toPage(PageLabel.profiles);
      return;
    }
    ref.read(commonActionProvider.notifier).toggleRunning();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasProfile = ref.watch(
      profilesProvider.select((state) => state.isNotEmpty),
    );
    final isStart = ref.watch(isStartProvider);
    final suspend = ref.watch(suspendProvider);
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final glass = context.glass;
    final active = isStart && !suspend;
    final label = !hasProfile
        ? appLocalizations.addProfile
        : suspend
        ? appLocalizations.suspended
        : isStart
        ? appLocalizations.proxyOn
        : appLocalizations.tapToConnect;
    final duration = context.motionDuration(Durations.medium2);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          toggled: isStart,
          label: label,
          child: SizedBox.square(
            dimension: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: active ? 1 : 0),
              duration: duration,
              curve: Easing.standard,
              builder: (_, t, _) => GlassButton(
                circle: true,
                kind: GlassKind.panel,
                color: Color.lerp(glass.glass, colorScheme.primary, t),
                onTap: () => _handleTap(ref, hasProfile),
                child: Center(
                  child: Icon(
                    hasProfile
                        ? Icons.power_settings_new_rounded
                        : Icons.add_rounded,
                    size: size * 0.4,
                    color: Color.lerp(
                      colorScheme.onSurface,
                      colorScheme.onPrimary,
                      t,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FadeBox(
          child: Text(
            label,
            key: ValueKey(label),
            maxLines: 1,
            style: context.textTheme.titleMedium,
          ),
        ),
        Consumer(
          builder: (_, ref, _) {
            final runTime = ref.watch(runTimeProvider);
            return AnimatedOpacity(
              opacity: runTime == null ? 0 : 1,
              duration: duration,
              child: Text(
                getTimeText(runTime),
                style: context.textTheme.bodySmall?.copyWith(
                  color: glass.secondaryLabel,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}


/// Compact connection control used by the wide desktop sidebar.
class CompactConnectControl extends ConsumerWidget {
  const CompactConnectControl({super.key});

  void _handleTap(WidgetRef ref, bool hasProfile) {
    if (!hasProfile) {
      ref.read(currentPageLabelProvider.notifier).toPage(PageLabel.profiles);
      return;
    }
    ref.read(commonActionProvider.notifier).toggleRunning();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasProfile = ref.watch(
      profilesProvider.select((state) => state.isNotEmpty),
    );
    final isStart = ref.watch(isStartProvider);
    final suspend = ref.watch(suspendProvider);
    final runTime = ref.watch(runTimeProvider);
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final glass = context.glass;
    final active = isStart && !suspend;
    final label = !hasProfile
        ? appLocalizations.addProfile
        : suspend
        ? appLocalizations.suspended
        : isStart
        ? appLocalizations.proxyOn
        : appLocalizations.tapToConnect;
    final duration = context.motionDuration(Durations.medium2);
    return Semantics(
      button: true,
      toggled: isStart,
      label: label,
      child: GlassButton(
        kind: GlassKind.tile,
        borderRadius: AppRadius.small,
        elevated: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: () => _handleTap(ref, hasProfile),
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: active ? 1 : 0),
              duration: duration,
              curve: Easing.standard,
              builder: (_, t, _) => SizedBox.square(
                dimension: 34,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: Color.lerp(
                      glass.fill,
                      colorScheme.primary.withValues(alpha: 0.18),
                      t,
                    ),
                    shape: AppShape.circle,
                  ),
                  child: Icon(
                    hasProfile
                        ? Icons.power_settings_new_rounded
                        : Icons.add_rounded,
                    size: 19,
                    color: Color.lerp(
                      glass.secondaryLabel,
                      colorScheme.primary,
                      t,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall,
                  ),
                  if (runTime != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      getTimeText(runTime),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: glass.secondaryLabel,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: duration,
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? context.toneColor(GlassTone.success)
                    : glass.secondaryLabel.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
