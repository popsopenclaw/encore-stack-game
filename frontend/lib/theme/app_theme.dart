import 'package:flutter/material.dart';

import 'app_palette.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppPalette.boardFrame),
        scaffoldBackgroundColor: AppPalette.scaffoldBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppPalette.appBarBg,
          foregroundColor: AppPalette.black,
        ),
        cardTheme: CardThemeData(
          color: AppPalette.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ),
      );
}
