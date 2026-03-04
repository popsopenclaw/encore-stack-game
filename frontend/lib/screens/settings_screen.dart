import 'package:flutter/material.dart';

import '../app/router.dart';
import '../state/auth_session_controller.dart';
import '../state/lobby_controller.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Settings',
      child: CommonCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Backend & gameplay settings will live here.'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                await lobbyController.resetForLogout();
                await authSessionController.logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            )
          ],
        ),
      ),
    );
  }
}
