import 'package:flutter/material.dart';

import '../app/router.dart';
import '../state/lobby_state.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';

class CreateLobbyScreen extends StatefulWidget {
  const CreateLobbyScreen({super.key});

  @override
  State<CreateLobbyScreen> createState() => _CreateLobbyScreenState();
}

class _CreateLobbyScreenState extends State<CreateLobbyScreen> {
  final _name = TextEditingController(text: 'Encore Lobby');
  final _max = TextEditingController(text: '6');

  @override
  void dispose() {
    _name.dispose();
    _max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Create Lobby',
      child: CommonCard(
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Lobby name')),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: _max, decoration: const InputDecoration(labelText: 'Max players (1-6)')),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                final parsed = int.tryParse(_max.text.trim()) ?? 6;
                lobbyState.createLobby(name: _name.text.trim(), max: parsed);
                Navigator.pushReplacementNamed(context, AppRoutes.game);
              },
              child: const Text('Create & Start'),
            ),
          ],
        ),
      ),
    );
  }
}
