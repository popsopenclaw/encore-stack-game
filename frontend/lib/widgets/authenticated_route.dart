import 'package:flutter/material.dart';

import '../app/router.dart';
import '../state/auth_session_controller.dart';

class AuthenticatedRoute extends StatefulWidget {
  const AuthenticatedRoute({required this.child, super.key});

  final Widget child;

  @override
  State<AuthenticatedRoute> createState() => _AuthenticatedRouteState();
}

class _AuthenticatedRouteState extends State<AuthenticatedRoute> {
  @override
  void initState() {
    super.initState();
    if (!authSessionController.initialized) {
      authSessionController.init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: authSessionController,
      builder: (context, _) {
        if (!authSessionController.initialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authSessionController.hasSession) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.login,
              (_) => false,
            );
          });

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return widget.child;
      },
    );
  }
}
