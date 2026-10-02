import 'package:material_ui/material_ui.dart';

/// The Liquid Glass palette. Content sits on neutral, opaque grouped cells;
/// only floating controls (sidebar, dock, segmented tracks, toolbars and
/// dialogs) are glass, which blurs and saturates what lies beneath it and
/// carries a specular rim.
@immutable
class GlassStyle extends ThemeExtension<GlassStyle> {
  const GlassStyle({
    required this.brightness,
    required this.background,
    required this.card,
    required this.fill,
    required this.thumb,
    required this.glass,
    required this.glassStrong,
    required this.rimLight,
    required this.rimShade,
    required this.separator,
    required this.shadow,
    required this.selected,
    required this.secondaryLabel,
    required this.blurSigma,
  });

  final Brightness brightness;
  final Color background;
  final Color card;
  final Color fill;
  final Color thumb;
  final Color glass;
  final Color glassStrong;
  final Color rimLight;
  final Color rimShade;
  final Color separator;
  final Color shadow;
  final Color selected;
  final Color secondaryLabel;
  final double blurSigma;

  bool get isDark => brightness == Brightness.dark;

  static const saturation = 1.8;

  /// Dark mode follows macOS unless [pureBlack] asks for iOS's OLED black.
  factory GlassStyle.of(ColorScheme scheme, {bool pureBlack = false}) {
    if (scheme.brightness == Brightness.dark) {
      return GlassStyle(
        brightness: Brightness.dark,
        background: pureBlack ? Colors.black : const Color(0xFF1E1F22),
        card: pureBlack ? const Color(0xFF191A1C) : const Color(0xFF27282C),
        fill: const Color(0xFF313238),
        thumb: const Color(0xFF3A3B40),
        glass: pureBlack ? const Color(0xE61B1C1F) : const Color(0xF02A2B2F),
        glassStrong: pureBlack
            ? const Color(0xFA202124)
            : const Color(0xFA2A2B2F),
        rimLight: Colors.white.withValues(alpha: 0.10),
        rimShade: Colors.white.withValues(alpha: 0.04),
        separator: const Color(0xFF3A3B40),
        shadow: Colors.black.withValues(alpha: 0.22),
        selected: scheme.primary.withValues(alpha: 0.18),
        secondaryLabel: const Color(0xFF9A9CA3),
        blurSigma: 16,
      );
    }
    return GlassStyle(
      brightness: Brightness.light,
      background: const Color(0xFFF3F3F3),
      card: Colors.white,
      fill: const Color(0xFFF0F1F3),
      thumb: Colors.white,
      glass: const Color(0xF7F7F7F8),
      glassStrong: const Color(0xFFFAFAFB),
      rimLight: Colors.white,
      rimShade: const Color(0xFFE7E8EB),
      separator: const Color(0xFFE6E7EA),
      shadow: Colors.black.withValues(alpha: 0.06),
      selected: scheme.primary.withValues(alpha: 0.12),
      secondaryLabel: const Color(0xFF7C7F87),
      blurSigma: 16,
    );
  }

  @override
  GlassStyle copyWith({double? blurSigma}) {
    return GlassStyle(
      brightness: brightness,
      background: background,
      card: card,
      fill: fill,
      thumb: thumb,
      glass: glass,
      glassStrong: glassStrong,
      rimLight: rimLight,
      rimShade: rimShade,
      separator: separator,
      shadow: shadow,
      selected: selected,
      secondaryLabel: secondaryLabel,
      blurSigma: blurSigma ?? this.blurSigma,
    );
  }

  @override
  GlassStyle lerp(covariant GlassStyle? other, double t) {
    if (other == null) {
      return this;
    }
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return GlassStyle(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: mix(background, other.background),
      card: mix(card, other.card),
      fill: mix(fill, other.fill),
      thumb: mix(thumb, other.thumb),
      glass: mix(glass, other.glass),
      glassStrong: mix(glassStrong, other.glassStrong),
      rimLight: mix(rimLight, other.rimLight),
      rimShade: mix(rimShade, other.rimShade),
      separator: mix(separator, other.separator),
      shadow: mix(shadow, other.shadow),
      selected: mix(selected, other.selected),
      secondaryLabel: mix(secondaryLabel, other.secondaryLabel),
      blurSigma: blurSigma + (other.blurSigma - blurSigma) * t,
    );
  }
}

extension GlassContextExt on BuildContext {
  GlassStyle get glass =>
      Theme.of(this).extension<GlassStyle>() ??
      GlassStyle.of(Theme.of(this).colorScheme);
}

/// Apple's system colors, for states and the settings icons.
enum GlassTone {
  accent,
  success,
  warning,
  danger,
  neutral,
  indigo,
  teal,
  pink;

  (Color, Color) get lightAndDark => switch (this) {
    GlassTone.accent => (const Color(0xFF1677FF), const Color(0xFF4096FF)),
    GlassTone.success => (const Color(0xFF34C759), const Color(0xFF30D158)),
    GlassTone.warning => (const Color(0xFFFF9500), const Color(0xFFFF9F0A)),
    GlassTone.danger => (const Color(0xFFFF3B30), const Color(0xFFFF453A)),
    GlassTone.neutral => (const Color(0xFF8E8E93), const Color(0xFF8E8E93)),
    GlassTone.indigo => (const Color(0xFF5856D6), const Color(0xFF5E5CE6)),
    GlassTone.teal => (const Color(0xFF30B0C7), const Color(0xFF40C8E0)),
    GlassTone.pink => (const Color(0xFFFF2D55), const Color(0xFFFF375F)),
  };

  Color on(Brightness brightness) {
    final (light, dark) = lightAndDark;
    return brightness == Brightness.dark ? dark : light;
  }
}

extension GlassToneExt on BuildContext {
  Color toneColor(GlassTone tone) {
    final colorScheme = Theme.of(this).colorScheme;
    if (tone == GlassTone.accent) {
      return colorScheme.primary;
    }
    return tone.on(colorScheme.brightness);
  }
}
