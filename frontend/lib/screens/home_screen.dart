import 'package:flutter/material.dart';

import '../app/router.dart';
import '../state/lobby_controller.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';
import '../widgets/menu_tile_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _openingLobby = false;

  @override
  void initState() {
    super.initState();
    lobbyController.init();
  }

  Future<void> _openLobby() async {
    if (_openingLobby) return;

    setState(() => _openingLobby = true);

    try {
      final sessionId = await lobbyController.resolveCurrentLobbySession();
      if (!mounted) return;

      if (sessionId != null && sessionId.isNotEmpty) {
        Navigator.pushNamed(context, AppRoutes.game, arguments: sessionId);
        return;
      }

      Navigator.pushNamed(context, AppRoutes.lobbyRoom);
    } finally {
      if (mounted) setState(() => _openingLobby = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        animation: lobbyController,
        builder: (context, _) {
          final hasLobby = lobbyController.lobbyCode != null;
          final lobbyLabel =
              lobbyController.lobbyName.isEmpty
                  ? (lobbyController.lobbyCode ?? 'Current Lobby')
                  : lobbyController.lobbyName;
          final lobbySubtitle =
              lobbyController.hasResumableCurrentGame
                  ? 'Match already started'
                  : 'Waiting in lobby';

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: ListView(
                children: [
                  const Text('Home Base', style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Create a lobby, join one by code, or reopen the one you are already in.',
                    style: AppTextStyles.bodyMuted,
                  ),
                  if (hasLobby) ...[
                    const SizedBox(height: AppSpacing.md),
                    CommonCard(
                      child: Row(
                        children: [
                          const Icon(Icons.meeting_room),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lobbyLabel, style: AppTextStyles.subtitle),
                                const SizedBox(height: 2),
                                Text(
                                  '${lobbyController.lobbyCode} • $lobbySubtitle',
                                  style: AppTextStyles.bodyMuted,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          FilledButton.icon(
                            onPressed: _openingLobby ? null : _openLobby,
                            icon: Icon(
                              lobbyController.hasResumableCurrentGame
                                  ? Icons.play_arrow
                                  : Icons.arrow_forward,
                            ),
                            label: Text(
                              _openingLobby ? 'Opening...' : 'Open Lobby',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  MenuTileButton(
                    title: 'Create Lobby',
                    subtitle: 'Host a new multiplayer room',
                    icon: Icons.group_add,
                    onTap:
                        () =>
                            Navigator.pushNamed(context, AppRoutes.createLobby),
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
        },
      ),
    );
  }
}
