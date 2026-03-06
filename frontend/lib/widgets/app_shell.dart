import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.padding = AppSpacing.pagePadding,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppPalette.surfaceTint.withValues(alpha: 0.35),
                    AppPalette.scaffoldBg,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -140,
            top: -120,
            child: _Wash(
              size: 380,
              color: AppPalette.tileYellow.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            left: -120,
            bottom: -180,
            child: _Wash(
              size: 340,
              color: AppPalette.tileBlue.withValues(alpha: 0.12),
            ),
          ),
          SafeArea(child: Padding(padding: padding, child: child)),
        ],
      ),
    );
  }
}

class _Wash extends StatelessWidget {
  const _Wash({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
