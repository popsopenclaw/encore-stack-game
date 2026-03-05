import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_tokens.dart';

class AppPanel extends StatelessWidget {
  const AppPanel({super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).extension<AppSurface>() ?? AppSurface.standard;
    final radius = Theme.of(context).extension<AppRadius>() ?? AppRadius.standard;
    return Container(
      decoration: BoxDecoration(
        color: surface.boardLikePanel,
        borderRadius: BorderRadius.circular(radius.panel),
        boxShadow: const [BoxShadow(color: AppPalette.boardFrameShadow, blurRadius: 14, offset: Offset(0, 8))],
      ),
      padding: padding,
      child: child,
    );
  }
}

class AppMetaPill extends StatelessWidget {
  const AppMetaPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final radius = Theme.of(context).extension<AppRadius>() ?? AppRadius.standard;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppPalette.stripBg,
        borderRadius: BorderRadius.circular(radius.pill),
        border: Border.all(color: AppPalette.borderDark),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppPalette.textOnDark, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
