import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_tokens.dart';

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
          margin: const EdgeInsets.all(10),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        extensions: const [
          AppRadius.standard,
          AppSurface.standard,
        ],
      );
}
