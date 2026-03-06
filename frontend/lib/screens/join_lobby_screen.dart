import 'package:flutter/material.dart';

import '../app/router.dart';
import '../state/lobby_controller.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';
import '../widgets/ui_kit.dart';

class JoinLobbyScreen extends StatefulWidget {
  const JoinLobbyScreen({super.key});

  @override
  State<JoinLobbyScreen> createState() => _JoinLobbyScreenState();
}

class _JoinLobbyScreenState extends State<JoinLobbyScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Join Lobby',
      child: ListView(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: CommonCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Access Existing Lobby',
                      style: AppTextStyles.title,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Enter the room code from the host. Your saved player name will be used automatically.',
                      style: AppTextStyles.bodyMuted,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: const [
                        AppMetaPill(text: 'Lobby Code', emphasis: true),
                        AppMetaPill(text: 'Host Approval'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _code,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Lobby code',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: () async {
                        await lobbyController.joinLobby(
                          code: _code.text.trim(),
                        );
                        if (!context.mounted) return;
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.lobbyRoom,
                        );
                      },
                      icon: const Icon(Icons.meeting_room),
                      label: const Text('Join Game'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
