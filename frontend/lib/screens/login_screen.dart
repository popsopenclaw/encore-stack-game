import 'package:flutter/material.dart';

import '../app/router.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Login',
      child: Center(
        child: SizedBox(
          width: 420,
          child: CommonCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 42),
                const SizedBox(height: 10),
                const Text('Login with GitHub OAuth to continue'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
                  icon: const Icon(Icons.login),
                  label: const Text('Continue (OAuth flow)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
