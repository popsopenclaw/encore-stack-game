import 'package:flutter/material.dart';

import '../app/router.dart';
import '../state/lobby_state.dart';
import '../theme/app_spacing.dart';
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
      child: CommonCard(
        child: Column(
          children: [
            TextField(controller: _code, decoration: const InputDecoration(labelText: 'Lobby code')),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Display name')),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                lobbyState.joinLobby(code: _code.text.trim(), name: _name.text.trim());
                Navigator.pushReplacementNamed(context, AppRoutes.game);
              },
              child: const Text('Join Game'),
            ),
          ],
        ),
      ),
    );
  }
}
