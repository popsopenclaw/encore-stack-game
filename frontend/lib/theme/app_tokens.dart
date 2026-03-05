import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_palette.dart';

@immutable
class AppRadius extends ThemeExtension<AppRadius> {
  const AppRadius({required this.card, required this.panel, required this.pill});

  final double card;
  final double panel;
  final double pill;

  @override
  AppRadius copyWith({double? card, double? panel, double? pill}) =>
      AppRadius(card: card ?? this.card, panel: panel ?? this.panel, pill: pill ?? this.pill);

  @override
  AppRadius lerp(ThemeExtension<AppRadius>? other, double t) {
    if (other is! AppRadius) return this;
    return AppRadius(
      card: lerpDouble(card, other.card, t) ?? card,
      panel: lerpDouble(panel, other.panel, t) ?? panel,
      pill: lerpDouble(pill, other.pill, t) ?? pill,
    );
  }

  static const AppRadius standard = AppRadius(card: 12, panel: 16, pill: 999);
}

@immutable
class AppSurface extends ThemeExtension<AppSurface> {
  const AppSurface({required this.boardLikePanel, required this.panelText});

  final Color boardLikePanel;
  final Color panelText;

  @override
  AppSurface copyWith({Color? boardLikePanel, Color? panelText}) =>
      AppSurface(boardLikePanel: boardLikePanel ?? this.boardLikePanel, panelText: panelText ?? this.panelText);

  @override
  AppSurface lerp(ThemeExtension<AppSurface>? other, double t) {
    if (other is! AppSurface) return this;
    return AppSurface(
      boardLikePanel: Color.lerp(boardLikePanel, other.boardLikePanel, t) ?? boardLikePanel,
      panelText: Color.lerp(panelText, other.panelText, t) ?? panelText,
    );
  }

  static const AppSurface standard = AppSurface(boardLikePanel: AppPalette.boardFrame, panelText: AppPalette.textOnDark);
}
