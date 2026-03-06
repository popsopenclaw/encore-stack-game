import 'package:flutter/material.dart';

import '../app/router.dart';
import '../state/auth_session_controller.dart';
import '../theme/app_palette.dart';

class SessionGateScreen extends StatefulWidget {
  const SessionGateScreen({super.key});

  @override
  State<SessionGateScreen> createState() => _SessionGateScreenState();
}

class _SessionGateScreenState extends State<SessionGateScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await authSessionController.init();
    if (!mounted) return;

    final route =
        authSessionController.hasSession ? AppRoutes.home : AppRoutes.login;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.6),
                  radius: 1.25,
                  colors: [
                    Color(0xFF13356F),
                    Color(0xFF06152F),
                    Color(0xFF020815),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFCC3A),
                        Color(0xFFFFA530),
                        Color(0xFFFF58A2),
                      ],
                    ),
                    boxShadow: const [
                      BoxShadow(color: AppPalette.neonGlow, blurRadius: 18),
                    ],
                  ),
                  child: const Text(
                    'ENCORE!',
                    style: TextStyle(
                      color: Color(0xFF1D0820),
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppPalette.neonCyan,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Connecting to session gateway...',
                  style: TextStyle(
                    color: AppPalette.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
