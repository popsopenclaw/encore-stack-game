import 'package:flutter/material.dart';

import '../app/router.dart';
import '../widgets/app_shell.dart';
import '../widgets/menu_tile_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Home',
      actions: [
        IconButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.profile), icon: const Icon(Icons.person)),
        IconButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.settings), icon: const Icon(Icons.settings)),
      ],
      child: Column(
        children: [
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
    );
  }
}
