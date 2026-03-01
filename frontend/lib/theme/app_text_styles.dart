import 'package:flutter/material.dart';

import 'app_palette.dart';

class AppTextStyles {
  static const title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppPalette.textPrimary,
  );

  static const subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppPalette.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 13,
    color: AppPalette.textPrimary,
  );

  static const monoBadge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppPalette.textOnDark,
  );

  static const boardHeader = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w900,
    color: AppPalette.textPrimary,
  );

  static const boardLabel = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppPalette.textPrimary,
  );

  static const boardValue = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    color: AppPalette.textOnDark,
  );
}
