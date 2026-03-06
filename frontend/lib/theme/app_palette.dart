import 'package:flutter/material.dart';

class AppPalette {
  static const scaffoldBg = Color(0xFF040B1F);
  static const appBarBg = Color(0xFF050E24);
  static const cardBg = Color(0xFF0A1736);
  static const surfaceRaised = Color(0xFF102247);
  static const surfaceInset = Color(0xFF081430);
  static const surfaceTint = Color(0xFF1B3A70);
  static const inkAccent = Color(0xFF29D8FF);

  static const boardFrame = Color(0xFF07122B);
  static const boardFrameShadow = Color(0x99010612);
  static const boardNotch = Color(0xFF020A1D);
  static const stripBg = Color(0xFF0B1A3C);

  static const tileYellow = Color(0xFFFFD94E);
  static const tileOrange = Color(0xFFFF9A2F);
  static const tileBlue = Color(0xFF38B8FF);
  static const tileGreen = Color(0xFF79E364);
  static const tilePurple = Color(0xFFFF4FB2);

  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF02050C);
  static const red = Color(0xFFFF4B63);
  static const grey = Color(0xFF8A9ABA);

  static const textPrimary = Color(0xFFEAF4FF);
  static const textMuted = Color(0xFF9AB0D4);
  static const textOnDark = Color(0xFFF1F8FF);
  static const borderLight = Color(0x6623CFFF);
  static const borderDark = Color(0x99328DCB);
  static const success = Color(0xFF6EF3A8);
  static const danger = Color(0xFFFF738B);

  static const hostHighlightBg = Color(0x3319CEFF);

  static const neonCyan = Color(0xFF24D7FF);
  static const neonBlue = Color(0xFF4D6EFF);
  static const neonPink = Color(0xFFFF52C7);
  static const neonGlow = Color(0x9921D8FF);
  static const panelLine = Color(0xAA2FD8FF);
  static const panelCore = Color(0xFF091A3A);

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
