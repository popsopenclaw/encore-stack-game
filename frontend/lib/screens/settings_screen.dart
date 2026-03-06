import 'package:flutter/material.dart';

import '../app/router.dart';
import '../state/auth_session_controller.dart';
import '../state/lobby_controller.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';
import '../widgets/ui_kit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: lobbyController,
      builder: (context, _) {
        return AppShell(
          title: 'Settings',
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                children: [
                  CommonCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Settings', style: AppTextStyles.title),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'Backend endpoint and account controls live here.',
                          style: AppTextStyles.bodyMuted,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: const [
                            AppMetaPill(text: 'Backend URL'),
                            AppMetaPill(text: 'Account Session'),
                            AppMetaPill(text: 'Diagnostics', emphasis: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CommonCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Connection', style: AppTextStyles.subtitle),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'Realtime lobby connection status is shown here instead of on Home.',
                          style: AppTextStyles.bodyMuted,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Realtime status',
                                style: AppTextStyles.body,
                              ),
                            ),
                            AppMetaPill(
                              text: lobbyController.realtimeStatus.name,
                              emphasis: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CommonCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Session Control',
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'Logout clears local auth state and disconnects lobby realtime services.',
                          style: AppTextStyles.bodyMuted,
                        ),
                        const SizedBox(height: AppSpacing.md),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
