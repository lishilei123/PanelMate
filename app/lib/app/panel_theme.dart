import 'package:flutter/material.dart';

import 'panel_gradient_theme.dart';

class PanelTheme {
  const PanelTheme._();

  static const Color ink = Color(0xFF132F3A);
  static const Color mutedInk = Color(0xFF60717B);

  static ThemeData light([
    PanelGradientTheme gradientTheme = const PanelGradientTheme(
      id: PanelGradientTheme.defaultId,
      label: '薄荷清晨',
      description: '清水蓝、薄荷绿和轻暖色',
      primary: Color(0xFF168F8F),
      secondary: Color(0xFF47A975),
      tertiary: Color(0xFFFF8A5C),
      backgroundColors: <Color>[
        Color(0xFFE8FBF6),
        Color(0xFFF8FCFF),
        Color(0xFFEAF4FF),
        Color(0xFFF7FFF9),
      ],
      backgroundStops: <double>[0.0, 0.38, 0.72, 1.0],
      veilColors: <Color>[
        Color(0xADFFFFFF),
        Color(0x2EFFFFFF),
        Color(0x2E78DCCB),
      ],
      accentColors: <Color>[
        Color(0x1F8FE7E2),
        Colors.transparent,
        Color(0x14FFB58F),
      ],
    ),
  ]) {
    final primary = gradientTheme.primary;
    final colorScheme = ColorScheme.fromSeed(seedColor: primary).copyWith(
      primary: primary,
      secondary: gradientTheme.secondary,
      tertiary: gradientTheme.tertiary,
      surface: const Color(0xFFF8FCFB),
      surfaceContainerHighest: const Color(0xFFEAF4F2),
      onSurface: ink,
      onSurfaceVariant: mutedInk,
      outline: const Color(0xFFCADFDA),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        titleTextStyle: const TextStyle(
          color: ink,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: const IconThemeData(color: ink),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: Color(0xDFFFFFFF)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE4EFEC),
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.70),
        hintStyle: const TextStyle(color: Color(0xFF7B8A92)),
        labelStyle: const TextStyle(color: mutedInk),
        helperStyle: const TextStyle(color: Color(0xFF6F7F88)),
        floatingLabelStyle: TextStyle(
          color: primary,
          fontWeight: FontWeight.w700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xE6FFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xE6FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 1.25),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE57373)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE57373), width: 1.25),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFBBD7D2),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.72),
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white.withValues(alpha: 0.94),
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.74),
        elevation: 0,
        indicatorColor: primary.withValues(alpha: 0.14),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? primary
                : const Color(0xFF667680),
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? primary
                : const Color(0xFF667680),
          ),
        ),
      ),
    );
  }
}
