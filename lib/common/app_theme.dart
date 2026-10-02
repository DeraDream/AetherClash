import 'package:fl_clash/models/config.dart';
import 'package:material_ui/material_ui.dart';

import 'constant.dart';
import 'glass.dart';
import 'shape.dart';

ThemeData buildAppTheme({
  required Brightness brightness,
  required ColorScheme materialScheme,
  required PageTransitionsTheme pageTransitionsTheme,
  required ThemeProps themeProps,
}) {
  final glass = GlassStyle.of(
    materialScheme,
    pureBlack: brightness == Brightness.dark && themeProps.pureBlack,
  );
  final colorScheme = materialScheme.toGlass(glass);
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    pageTransitionsTheme: pageTransitionsTheme,
    extensions: [glass],
  );
  final text = _glassTextTheme(base.textTheme);
  final floatingSide = BorderSide(color: glass.rimShade);
  return base.copyWith(
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: glass.background,
    dividerColor: glass.separator,
    textTheme: text,
    appBarTheme: AppBarThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.headlineSmall?.copyWith(
        color: colorScheme.onSurface,
        fontSize: 26,
      ),
    ),
    cardTheme: CardThemeData(
      color: glass.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: AppShape.medium,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: glass.glassStrong,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: AppShape.small.copyWith(side: floatingSide),
      barrierColor: colorScheme.modalScrim,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: glass.glassStrong,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      modalBarrierColor: colorScheme.modalScrim,
      shape: AppShape.top(AppCorner.extraLarge),
    ),
    dividerTheme: DividerThemeData(color: glass.separator, thickness: 0.5),
    inputDecorationTheme: _inputTheme(glass, colorScheme),
    filledButtonTheme: const FilledButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(AppShape.small),
        elevation: WidgetStatePropertyAll(0),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(AppShape.small),
        backgroundColor: WidgetStatePropertyAll(glass.fill),
        side: const WidgetStatePropertyAll(BorderSide.none),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    ),
    textButtonTheme: const TextButtonThemeData(
      style: ButtonStyle(shape: WidgetStatePropertyAll(AppShape.small)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(AppShape.small),
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(glass.fill),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: AppShape.small,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(AppShape.extraSmall),
        side: const WidgetStatePropertyAll(BorderSide.none),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? glass.thumb : glass.fill,
        ),
        foregroundColor: WidgetStatePropertyAll(colorScheme.onSurface),
      ),
    ),
    switchTheme: _switchTheme(glass, colorScheme),
    chipTheme: ChipThemeData(
      backgroundColor: glass.fill,
      selectedColor: colorScheme.secondaryContainer,
      side: BorderSide.none,
      shape: AppShape.full,
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(glass.glassStrong),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: WidgetStatePropertyAll(glass.shadow),
        elevation: const WidgetStatePropertyAll(12),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
        shape: WidgetStatePropertyAll(
          AppShape.medium.copyWith(side: floatingSide),
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: glass.glassStrong,
      surfaceTintColor: Colors.transparent,
      shadowColor: glass.shadow,
      elevation: 12,
      shape: AppShape.medium.copyWith(side: floatingSide),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: ShapeDecoration(
        color: glass.isDark ? const Color(0xF23A3A3C) : const Color(0xE6202022),
        shape: AppShape.small,
      ),
      textStyle: text.bodySmall?.copyWith(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: glass.glassStrong,
      contentTextStyle: text.bodyMedium?.copyWith(color: colorScheme.onSurface),
      elevation: 0,
      shape: AppShape.medium.copyWith(side: floatingSide),
    ),
    listTileTheme: ListTileThemeData(iconColor: glass.secondaryLabel),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      linearTrackColor: glass.fill,
      borderRadius: AppRadius.full,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(6),
      radius: const Radius.circular(AppCorner.full),
      thumbColor: WidgetStatePropertyAll(
        colorScheme.onSurface.withValues(alpha: 0.2),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: ShapeDecoration(
        color: glass.thumb,
        shape: AppShape.extraSmall,
      ),
      splashBorderRadius: AppRadius.extraSmall,
      labelColor: colorScheme.onSurface,
      unselectedLabelColor: glass.secondaryLabel,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      labelStyle: text.titleSmall,
    ),
  );
}

TextTheme _glassTextTheme(TextTheme text) {
  TextStyle? weight(TextStyle? style, FontWeight weight) =>
      style?.copyWith(fontWeight: weight, letterSpacing: 0);
  return text.copyWith(
    displaySmall: weight(text.displaySmall, FontWeight.w700),
    headlineLarge: weight(text.headlineLarge, FontWeight.w700),
    headlineMedium: weight(text.headlineMedium, FontWeight.w700),
    headlineSmall: weight(text.headlineSmall, FontWeight.w700),
    titleLarge: weight(text.titleLarge, FontWeight.w700),
    titleMedium: weight(text.titleMedium, FontWeight.w600),
    titleSmall: weight(text.titleSmall, FontWeight.w600),
  );
}

InputDecorationThemeData _inputTheme(GlassStyle glass, ColorScheme scheme) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      AppShape.input.copyWith(
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecorationThemeData(
    filled: true,
    fillColor: glass.fill,
    border: AppShape.input,
    enabledBorder: AppShape.input,
    disabledBorder: AppShape.input,
    focusedBorder: border(scheme.primary, 1.5),
    errorBorder: border(scheme.error),
    focusedErrorBorder: border(scheme.error, 1.5),
  );
}

SwitchThemeData _switchTheme(GlassStyle glass, ColorScheme scheme) {
  final on = GlassTone.success.on(scheme.brightness);
  return SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? Colors.white.withValues(alpha: 0.6)
          : Colors.white,
    ),
    trackColor: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      final color = selected ? on : glass.fill;
      return states.contains(WidgetState.disabled)
          ? color.withValues(alpha: color.a * 0.5)
          : color;
    }),
    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
  );
}

extension GlassSchemeExt on ColorScheme {
  Color get modalScrim => scrim.withValues(alpha: 0.2);

  /// Neutral grouped surfaces keep the accent as the only strong color.
  ColorScheme toGlass(GlassStyle glass) {
    final dark = glass.isDark;
    return copyWith(
      surface: glass.background,
      onSurface: dark ? Colors.white : Colors.black,
      onSurfaceVariant: glass.secondaryLabel,
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: glass.card,
      surfaceContainerLow: glass.card,
      surfaceContainer: glass.card,
      surfaceContainerHigh: dark
          ? const Color(0xFF303136)
          : const Color(0xFFEFEFF1),
      surfaceContainerHighest: dark
          ? const Color(0xFF393A40)
          : const Color(0xFFE5E6E9),
      outline: dark ? const Color(0xFF505159) : const Color(0xFFD0D2D6),
      outlineVariant: glass.separator,
      secondaryContainer: primary.withValues(alpha: dark ? 0.18 : 0.10),
      onSecondaryContainer: primary,
    );
  }
}

ColorScheme seededColorScheme(
  Color seed,
  Brightness brightness,
  DynamicSchemeVariant variant,
) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    dynamicSchemeVariant: variant,
  );
  if (seed.toARGB32() != defaultPrimaryColor) {
    return scheme;
  }
  return scheme.copyWith(
    primary: GlassTone.accent.on(brightness),
    onPrimary: Colors.white,
  );
}
