import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_palette.dart';

@immutable
class AppRadius extends ThemeExtension<AppRadius> {
  const AppRadius({
    required this.card,
    required this.panel,
    required this.pill,
    required this.control,
  });

  final double card;
  final double panel;
  final double pill;
  final double control;

  @override
  AppRadius copyWith({
    double? card,
    double? panel,
    double? pill,
    double? control,
  }) => AppRadius(
    card: card ?? this.card,
    panel: panel ?? this.panel,
    pill: pill ?? this.pill,
    control: control ?? this.control,
  );

  @override
  AppRadius lerp(ThemeExtension<AppRadius>? other, double t) {
    if (other is! AppRadius) return this;
    return AppRadius(
      card: lerpDouble(card, other.card, t) ?? card,
      panel: lerpDouble(panel, other.panel, t) ?? panel,
      pill: lerpDouble(pill, other.pill, t) ?? pill,
      control: lerpDouble(control, other.control, t) ?? control,
    );
  }

  static const AppRadius standard = AppRadius(
    card: 18,
    panel: 20,
    pill: 999,
    control: 12,
  );
}

@immutable
class AppSurface extends ThemeExtension<AppSurface> {
  const AppSurface({
    required this.boardLikePanel,
    required this.panelText,
    required this.inset,
    required this.raised,
    required this.frameStroke,
    required this.glow,
  });

  final Color boardLikePanel;
  final Color panelText;
  final Color inset;
  final Color raised;
  final Color frameStroke;
  final Color glow;

  @override
  AppSurface copyWith({
    Color? boardLikePanel,
    Color? panelText,
    Color? inset,
    Color? raised,
    Color? frameStroke,
    Color? glow,
  }) => AppSurface(
    boardLikePanel: boardLikePanel ?? this.boardLikePanel,
    panelText: panelText ?? this.panelText,
    inset: inset ?? this.inset,
    raised: raised ?? this.raised,
    frameStroke: frameStroke ?? this.frameStroke,
    glow: glow ?? this.glow,
  );

  @override
  AppSurface lerp(ThemeExtension<AppSurface>? other, double t) {
    if (other is! AppSurface) return this;
    return AppSurface(
      boardLikePanel:
          Color.lerp(boardLikePanel, other.boardLikePanel, t) ?? boardLikePanel,
      panelText: Color.lerp(panelText, other.panelText, t) ?? panelText,
      inset: Color.lerp(inset, other.inset, t) ?? inset,
      raised: Color.lerp(raised, other.raised, t) ?? raised,
      frameStroke: Color.lerp(frameStroke, other.frameStroke, t) ?? frameStroke,
      glow: Color.lerp(glow, other.glow, t) ?? glow,
    );
  }

  static const AppSurface standard = AppSurface(
    boardLikePanel: AppPalette.cardBg,
    panelText: AppPalette.textPrimary,
    inset: AppPalette.surfaceInset,
    raised: AppPalette.surfaceRaised,
    frameStroke: AppPalette.panelLine,
    glow: AppPalette.neonGlow,
  );
}
