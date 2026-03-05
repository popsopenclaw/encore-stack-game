import 'package:flutter/material.dart';

class AppPalette {
  static const scaffoldBg = Color(0xFFEFE9D8);
  static const appBarBg = Color(0xFFD8CCB1);
  static const cardBg = Color(0xFFFFFAEE);

  static const boardFrame = Color(0xFF202020);
  static const boardFrameShadow = Color(0x8A000000);
  static const boardNotch = Color(0xFF121212);
  static const stripBg = Color(0xFF1F1F1F);

  static const tileYellow = Color(0xFFF6D65E);
  static const tileOrange = Color(0xFFF29A42);
  static const tileBlue = Color(0xFF72B9F4);
  static const tileGreen = Color(0xFF9ED86E);
  static const tilePurple = Color(0xFFE77CB3);

  static const white = Colors.white;
  static const black = Colors.black;
  static const red = Colors.red;
  static const grey = Colors.grey;

  static const textPrimary = Color(0xFF1E1E1E);
  static const textOnDark = Color(0xFFF5F5F5);
  static const borderLight = Color(0x42000000);
  static const borderDark = Color(0x8A000000);
  static const success = Color(0xFF7CFC98);
  static const danger = Color(0xFFFF6A6A);

  static const hostHighlightBg = Color(0xFFFFF3CD);

  static Color fromGameColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'yellow':
        return tileYellow;
      case 'orange':
        return tileOrange;
      case 'blue':
        return tileBlue;
      case 'green':
        return tileGreen;
      case 'purple':
        return tilePurple;
      default:
        return grey;
    }
  }
}
