import 'package:flutter/material.dart';

import '../app/router.dart';
import '../state/auth_session_controller.dart';
import '../state/lobby_controller.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_shell.dart';
import '../widgets/menu_tile_button.dart';

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
    if (authSessionController.initialized && !authSessionController.hasSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
      });
    }

    return AppShell(
      title: 'Home',
      actions: [
        IconButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.profile), icon: const Icon(Icons.person)),
        IconButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.settings), icon: const Icon(Icons.settings)),
      ],
      child: AnimatedBuilder(
        animation: Listenable.merge([lobbyController, authSessionController]),
        builder: (context, _) => Column(
          children: [
            Card(
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.wifi_tethering),
                title: const Text('Realtime status'),
                subtitle: Text(lobbyController.realtimeStatus.name),
              ),
            ),
            if (lobbyController.lobbyCode != null)
              Card(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Row(
                    children: [
                      const Icon(Icons.groups),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text('Current lobby: ${lobbyController.lobbyName.isEmpty ? lobbyController.lobbyCode : lobbyController.lobbyName} (${lobbyController.lobbyCode})'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.game),
                        child: const Text('Open'),
                      )
                    ],
                  ),
                ),
              ),
            MenuTileButton(
              title: 'Create Lobby',
              subtitle: 'Host a new multiplayer room',
              icon: Icons.group_add,
              onTap: () => Navigator.pushNamed(context, AppRoutes.createLobby),
            ),
            MenuTileButton(
              title: 'Join Lobby',
              subtitle: 'Enter using a lobby code',
              icon: Icons.meeting_room,
              onTap: () => Navigator.pushNamed(context, AppRoutes.joinLobby),
            ),
            MenuTileButton(
              title: 'Open Game',
              subtitle: 'Direct game screen for development',
              icon: Icons.videogame_asset,
              onTap: () => Navigator.pushNamed(context, AppRoutes.game),
            ),
          ],
        ),
      ),
    );
  }
}
