import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_tokens.dart';

class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppPalette.inkAccent,
      onPrimary: AppPalette.black,
      secondary: AppPalette.neonPink,
      onSecondary: AppPalette.black,
      error: AppPalette.danger,
      onError: AppPalette.black,
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
        backgroundColor: Colors.transparent,
        foregroundColor: AppPalette.textOnDark,
        elevation: 0,
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
          horizontal: 12,
          vertical: 12,
        ),
        hintStyle: const TextStyle(color: AppPalette.textMuted),
        labelStyle: const TextStyle(
          color: AppPalette.textMuted,
          fontWeight: FontWeight.w700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.control),
          borderSide: const BorderSide(color: AppPalette.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.control),
          borderSide: const BorderSide(color: AppPalette.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.control),
          borderSide: const BorderSide(color: AppPalette.inkAccent, width: 1.8),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppPalette.textOnDark,
        unselectedLabelColor: AppPalette.textMuted,
        indicatorColor: AppPalette.inkAccent,
        dividerColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.control),
          ),
          backgroundColor: AppPalette.inkAccent,
          foregroundColor: AppPalette.black,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.35,
            fontSize: 13,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.control),
          ),
          side: const BorderSide(color: AppPalette.borderLight),
          foregroundColor: AppPalette.textPrimary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            fontSize: 13,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 34),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.control),
          ),
          foregroundColor: AppPalette.inkAccent,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            fontSize: 13,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: AppPalette.surfaceInset,
          foregroundColor: AppPalette.textOnDark,
          minimumSize: const Size(38, 38),
          side: const BorderSide(color: AppPalette.borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.control),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppPalette.panelCore,
        contentTextStyle: const TextStyle(
          color: AppPalette.textOnDark,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.control),
          side: const BorderSide(color: AppPalette.borderLight),
        ),
      ),
      extensions: const [radius, surface],
    );
  }
}
