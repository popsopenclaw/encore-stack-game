import 'package:flutter/material.dart';

import '../app/router.dart';
import '../state/auth_session_controller.dart';
import '../state/lobby_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';
import '../widgets/menu_tile_button.dart';
import '../widgets/ui_kit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    lobbyController.init();
  }

  @override
  Widget build(BuildContext context) {
    if (authSessionController.initialized &&
        !authSessionController.hasSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (_) => false,
        );
      });
    }

    return AppShell(
      title: 'Home',
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          icon: const Icon(Icons.person),
        ),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          icon: const Icon(Icons.settings),
        ),
      ],
      child: AnimatedBuilder(
        animation: Listenable.merge([lobbyController, authSessionController]),
        builder:
            (context, _) => ListView(
              children: [
                CommonCard(
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_tethering),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          'Realtime status',
                          style: AppTextStyles.subtitle,
                        ),
                      ),
                      AppMetaPill(text: lobbyController.realtimeStatus.name),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (lobbyController.lobbyCode != null)
                  CommonCard(
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Row(
                        children: [
                          const Icon(Icons.groups),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Current lobby: ${lobbyController.lobbyName.isEmpty ? lobbyController.lobbyCode : lobbyController.lobbyName} (${lobbyController.lobbyCode})',
                              style: const TextStyle(
                                color: AppPalette.textMuted,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed:
                                () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.lobbyRoom,
                                ),
                            icon: const Icon(Icons.meeting_room, size: 16),
                            label: const Text('Open Lobby'),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                MenuTileButton(
                  title: 'Create Lobby',
                  subtitle: 'Host a new multiplayer room',
                  icon: Icons.group_add,
                  onTap:
                      () => Navigator.pushNamed(context, AppRoutes.createLobby),
                ),
                const SizedBox(height: AppSpacing.sm),
                MenuTileButton(
                  title: 'Join Lobby',
                  subtitle: 'Enter using a lobby code',
                  icon: Icons.meeting_room,
                  onTap:
                      () => Navigator.pushNamed(context, AppRoutes.joinLobby),
                ),
              ],
            ),
      ),
    );
  }
}
