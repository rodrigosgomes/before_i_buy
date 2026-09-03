import 'package:flutter/material.dart';

abstract final class BibColors {
  static const canvas = Color(0xFFFAF9F6);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFEFECE6);
  static const textPrimary = Color(0xFF4F5D65);
  static const textSecondary = Color(0xFF6E7B82);
  static const brandTerracotta = Color(0xFFC56C51);
  static const actionPrimary = Color(0xFFA94F38);
  static const actionPrimaryPressed = Color(0xFF8F3F2C);
  static const onActionPrimary = Color(0xFFFFFFFF);
  static const infoContainer = Color(0xFFE4EEF4);
  static const warningContainer = Color(0xFFF4EBC4);
  static const error = Color(0xFFA33A3A);
  static const outline = Color(0xFFC8C3BC);
}

abstract final class BibSpacing {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x7 = 32.0;
  static const x8 = 40.0;
}

abstract final class BibRadii {
  static const field = 16.0;
  static const card = 20.0;
  static const hero = 28.0;
  static const button = 20.0;
}

ThemeData buildBibTheme() {
  const scheme = ColorScheme.light(
    primary: BibColors.actionPrimary,
    onPrimary: BibColors.onActionPrimary,
    primaryContainer: Color(0xFFF5D8CF),
    onPrimaryContainer: Color(0xFF4A190D),
    secondary: BibColors.textPrimary,
    onSecondary: Colors.white,
    surface: BibColors.surface,
    onSurface: BibColors.textPrimary,
    error: BibColors.error,
    outline: BibColors.outline,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final body = base.textTheme.apply(
    fontFamily: 'Inter',
    fontFamilyFallback: const ['Arial', 'sans-serif'],
    bodyColor: BibColors.textPrimary,
    displayColor: BibColors.textPrimary,
  );
  final textTheme = body.copyWith(
    displayLarge: body.displayLarge?.copyWith(
      fontFamily: 'Manrope',
      fontSize: 32,
      height: 38 / 32,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: body.headlineMedium?.copyWith(
      fontFamily: 'Manrope',
      fontSize: 26,
      height: 32 / 26,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: body.titleLarge?.copyWith(
      fontFamily: 'Manrope',
      fontSize: 22,
      height: 28 / 22,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: body.titleMedium?.copyWith(
      fontSize: 18,
      height: 24 / 18,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: body.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
    bodyMedium: body.bodyMedium?.copyWith(fontSize: 16, height: 1.5),
    labelLarge: body.labelLarge?.copyWith(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
    ),
  );
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(BibRadii.field),
    borderSide: const BorderSide(color: BibColors.outline),
  );
  return base.copyWith(
    scaffoldBackgroundColor: BibColors.canvas,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: BibColors.canvas,
      foregroundColor: BibColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BibColors.surface,
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: BibColors.actionPrimary, width: 2),
      ),
      errorBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: BibColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: BibSpacing.x4,
        vertical: BibSpacing.x4,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BibRadii.button),
          ),
        ),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
      ),
    ),
  );
}
