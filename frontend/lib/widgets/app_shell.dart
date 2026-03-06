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
      body: Stack(
        children: [
          const Positioned.fill(child: _CosmicBackdrop()),
          SafeArea(
            child: Column(
              children: [
                _TopRail(title: title, actions: actions),
                Expanded(child: Padding(padding: padding, child: child)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopRail extends StatelessWidget {
  const _TopRail({required this.title, required this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: _RailLine(reverse: true)),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFCC3A),
                      Color(0xFFFFA830),
                      Color(0xFFFF58A2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: AppPalette.neonGlow,
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Text(
                  'ENCORE!',
                  style: TextStyle(
                    color: Color(0xFF21081A),
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Expanded(child: _RailLine()),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xC5112D5D), Color(0xB0081C3F)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppPalette.panelLine),
              boxShadow: const [
                BoxShadow(
                  color: AppPalette.neonGlow,
                  blurRadius: 14,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              children: [
                if (canPop)
                  const BackButton(color: AppPalette.textOnDark)
                else
                  const SizedBox(width: 40),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppPalette.textPrimary,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                if (actions != null && actions!.isNotEmpty)
                  Row(mainAxisSize: MainAxisSize.min, children: actions!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RailLine extends StatelessWidget {
  const _RailLine({this.reverse = false});

  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: reverse ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        height: 3,
        width: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          gradient: LinearGradient(
            begin: reverse ? Alignment.centerRight : Alignment.centerLeft,
            end: reverse ? Alignment.centerLeft : Alignment.centerRight,
            colors: const [AppPalette.neonCyan, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _CosmicBackdrop extends StatelessWidget {
  const _CosmicBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.8),
              radius: 1.2,
              colors: [Color(0xFF113068), Color(0xFF050B20), Color(0xFF020612)],
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppPalette.neonBlue.withValues(alpha: 0.15),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
        ),
        ...List.generate(56, (i) {
          final x = (i * 97) % 1000 / 1000;
          final y = (i * 53) % 1200 / 1200;
          final size = i % 5 == 0 ? 2.3 : 1.4;
          return Positioned(
            left: x * MediaQuery.sizeOf(context).width,
            top: y * MediaQuery.sizeOf(context).height,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppPalette.white.withValues(
                  alpha: i % 4 == 0 ? 0.8 : 0.45,
                ),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
        Align(
          alignment: Alignment.bottomCenter,
          child: IgnorePointer(
            child: Container(
              height: 170,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFF031433)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
