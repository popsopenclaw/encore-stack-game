import 'package:flutter/material.dart';

import 'app_palette.dart';

class AppTextStyles {
  static const title = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.6,
    color: AppPalette.textPrimary,
  );

  static const subtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: AppPalette.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 13,
    height: 1.35,
    color: AppPalette.textPrimary,
  );

  static const bodyMuted = TextStyle(
    fontSize: 12,
    height: 1.35,
    color: AppPalette.textMuted,
  );

  static const monoBadge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.8,
    color: AppPalette.textOnDark,
  );

  static const boardHeader = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.3,
    color: AppPalette.textPrimary,
  );

  static const boardLabel = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    color: AppPalette.textPrimary,
  );

  static const boardValue = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.7,
    color: AppPalette.textOnDark,
  );
}
