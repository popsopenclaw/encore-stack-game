import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_tokens.dart';

class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppPalette.inkAccent,
      onPrimary: AppPalette.white,
      secondary: AppPalette.tileBlue,
      onSecondary: AppPalette.textPrimary,
      error: AppPalette.danger,
      onError: AppPalette.white,
      surface: AppPalette.cardBg,
      onSurface: AppPalette.textPrimary,
    );

    const radius = AppRadius.standard;
    const surface = AppSurface.standard;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppPalette.scaffoldBg,
      fontFamily: 'Trebuchet MS',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppPalette.appBarBg,
        foregroundColor: AppPalette.textOnDark,
        elevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface.boardLikePanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.card),
          side: const BorderSide(color: AppPalette.borderLight),
        ),
        margin: const EdgeInsets.all(0),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: AppPalette.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        labelStyle: const TextStyle(
          color: AppPalette.textMuted,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.control),
          borderSide: const BorderSide(color: AppPalette.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.control),
          borderSide: const BorderSide(color: AppPalette.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.control),
          borderSide: const BorderSide(color: AppPalette.inkAccent, width: 1.6),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppPalette.inkAccent,
        unselectedLabelColor: AppPalette.textMuted,
        indicatorColor: AppPalette.inkAccent,
        dividerColor: AppPalette.borderLight,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.control),
          ),
          backgroundColor: AppPalette.inkAccent,
          foregroundColor: AppPalette.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.control),
          ),
          side: const BorderSide(color: AppPalette.borderDark),
          foregroundColor: AppPalette.textPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 34),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.control),
          ),
          foregroundColor: AppPalette.inkAccent,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: AppPalette.surfaceRaised,
          foregroundColor: AppPalette.textPrimary,
          minimumSize: const Size(36, 36),
          side: const BorderSide(color: AppPalette.borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.control),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppPalette.boardFrame,
        contentTextStyle: TextStyle(color: AppPalette.textOnDark),
      ),
      extensions: const [radius, surface],
    );
  }
}
