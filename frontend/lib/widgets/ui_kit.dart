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
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      padding: padding,
      child: child,
    );
  }
}

class DieChip extends StatelessWidget {
  const DieChip({super.key, required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppPalette.borderDark),
      ),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
    );
  }
}

class AppMetaPill extends StatelessWidget {
  const AppMetaPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final radius = Theme.of(context).extension<AppRadius>() ?? AppRadius.standard;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius.pill),
        border: Border.all(color: AppPalette.borderLight),
      ),
      child: Text(
        text,
        style: TextStyle(color: scheme.onSurface, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
