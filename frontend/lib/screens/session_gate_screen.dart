import 'package:flutter/material.dart';

import '../app/router.dart';
import '../state/auth_session_controller.dart';

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

    final route = authSessionController.hasSession ? AppRoutes.home : AppRoutes.login;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
