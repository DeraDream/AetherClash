import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

ThemeData _build({
  Brightness brightness = Brightness.light,
  ThemeProps themeProps = const ThemeProps(),
}) {
  return buildAppTheme(
    brightness: brightness,
    materialScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: brightness,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(),
    themeProps: themeProps,
  );
}

void main() {
  group('buildAppTheme', () {
    test('uses the seeded Material 3 scheme', () {
      final theme = _build();
      expect(theme.useMaterial3, isTrue);
      expect(
        theme.colorScheme.primary,
        ColorScheme.fromSeed(seedColor: Colors.teal).primary,
      );
    });

    test('pure black only reaches the dark theme', () {
      final dark = _build(
        brightness: Brightness.dark,
        themeProps: const ThemeProps(pureBlack: true),
      );
      expect(dark.colorScheme.surface, Colors.black);
      final light = _build(themeProps: const ThemeProps(pureBlack: true));
      expect(light.colorScheme.surface, isNot(Colors.black));
    });

    test('text fields are filled glass with the small corner', () {
      final theme = _build();
      final border = theme.inputDecorationTheme.border;
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(border, isA<OutlineInputBorder>());
      expect((border! as OutlineInputBorder).borderRadius, AppRadius.small);
    });

    test('content is opaque and neutral, the scaffold shows the floor', () {
      final theme = _build();
      final glass = theme.extension<GlassStyle>()!;
      expect(theme.scaffoldBackgroundColor, Colors.transparent);
      expect(theme.colorScheme.surface, const Color(0xFFF3F3F3));
      expect(theme.colorScheme.surfaceContainer, Colors.white);
      expect(theme.colorScheme.onSurface, Colors.black);
      expect(theme.cardTheme.color, glass.card);
      expect(theme.cardTheme.shape, isA<RoundedSuperellipseBorder>());
    });

    test('taps land exactly where controls are drawn', () {
      expect(_build().materialTapTargetSize, MaterialTapTargetSize.shrinkWrap);
    });

    test('dark glass uses the desktop neutral and switches turn system green', () {
      final dark = _build(brightness: Brightness.dark);
      expect(dark.colorScheme.surface, const Color(0xFF1E1F22));
      expect(dark.extension<GlassStyle>()!.isDark, isTrue);
      final track = dark.switchTheme.trackColor!.resolve({
        WidgetState.selected,
      });
      expect(track, GlassTone.success.on(Brightness.dark));
    });
  });

  group('seededColorScheme', () {
    test('the default seed is exactly system blue', () {
      for (final brightness in Brightness.values) {
        final scheme = seededColorScheme(
          const Color(defaultPrimaryColor),
          brightness,
          DynamicSchemeVariant.fidelity,
        );
        expect(scheme.primary, GlassTone.accent.on(brightness));
        expect(scheme.onPrimary, Colors.white);
      }
    });

    test('any other seed is a plain seeded scheme', () {
      expect(
        seededColorScheme(
          Colors.teal,
          Brightness.light,
          DynamicSchemeVariant.tonalSpot,
        ),
        ColorScheme.fromSeed(
          seedColor: Colors.teal,
          dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
        ),
      );
    });
  });
}
