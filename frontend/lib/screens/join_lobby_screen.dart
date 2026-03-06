import 'package:flutter/material.dart';

import '../app/router.dart';
import '../state/lobby_controller.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';

class JoinLobbyScreen extends StatefulWidget {
  const JoinLobbyScreen({super.key});

  @override
  State<JoinLobbyScreen> createState() => _JoinLobbyScreenState();
}

class _JoinLobbyScreenState extends State<JoinLobbyScreen> {
  final _code = TextEditingController();
  final _name = TextEditingController(text: 'Player');

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Join Lobby',
      child: Center(
        child: SizedBox(
          width: 520,
          child: CommonCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join an existing lobby',
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _code,
                  decoration: const InputDecoration(labelText: 'Lobby code'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Display name'),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () async {
                    await lobbyController.joinLobby(
                      code: _code.text.trim(),
                      name: _name.text.trim(),
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
    );
  }
}
