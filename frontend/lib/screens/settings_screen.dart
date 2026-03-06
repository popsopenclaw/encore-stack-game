import 'package:flutter/material.dart';

import '../app/router.dart';
import '../state/auth_session_controller.dart';
import '../state/lobby_controller.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Settings',
      child: Center(
        child: SizedBox(
          width: 560,
          child: CommonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Settings', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Backend and gameplay settings will live here.',
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () async {
                    await lobbyController.resetForLogout();
                    await authSessionController.logout();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (_) => false,
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
