import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_tokens.dart';

class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final surface =
        Theme.of(context).extension<AppSurface>() ?? AppSurface.standard;
    final radius =
        Theme.of(context).extension<AppRadius>() ?? AppRadius.standard;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [surface.raised, surface.boardLikePanel, surface.inset],
        ),
        borderRadius: BorderRadius.circular(radius.panel),
        border: Border.all(color: surface.frameStroke),
        boxShadow: [
          BoxShadow(
            color: surface.glow,
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
          const BoxShadow(
            color: Color(0xAA02050E),
            blurRadius: 14,
            spreadRadius: -1,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class DieChip extends StatelessWidget {
  const DieChip({
    super.key,
    required this.text,
    required this.bg,
    required this.fg,
    this.selected = false,
    this.enabled = true,
    this.onTap,
  });

  final String text;
  final Color bg;
  final Color fg;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius =
        Theme.of(context).extension<AppRadius>() ?? AppRadius.standard;
    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bg.withValues(alpha: enabled ? 0.96 : 0.7),
            bg.withValues(alpha: enabled ? 0.78 : 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(radius.control),
        border: Border.all(
          color:
              selected
                  ? AppPalette.neonCyan
                  : AppPalette.white.withValues(alpha: enabled ? 0.44 : 0.24),
          width: selected ? 1.6 : 1,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: AppPalette.neonCyan.withValues(alpha: 0.36),
              blurRadius: 14,
              spreadRadius: -2,
            ),
          BoxShadow(
            color: bg.withValues(alpha: enabled ? 0.32 : 0.14),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: enabled ? fg : fg.withValues(alpha: 0.66),
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
          fontSize: 12,
        ),
      ),
    );

    if (onTap == null) return chip;
    return GestureDetector(onTap: enabled ? onTap : null, child: chip);
  }
}

class AppMetaPill extends StatelessWidget {
  const AppMetaPill({super.key, required this.text, this.emphasis = false});

  final String text;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final radius =
        Theme.of(context).extension<AppRadius>() ?? AppRadius.standard;
    final bg =
        emphasis
            ? AppPalette.neonCyan.withValues(alpha: 0.2)
            : AppPalette.surfaceInset;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius.pill),
        border: Border.all(
          color: emphasis ? AppPalette.neonCyan : AppPalette.borderLight,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppPalette.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}
