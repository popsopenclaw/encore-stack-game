import 'package:flutter/material.dart';

import '../app/router.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';

class JoinLobbyScreen extends StatelessWidget {
  const JoinLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Join Lobby',
      child: CommonCard(
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Lobby code')),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Display name')),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.game),
              child: const Text('Join Game'),
            ),
          ],
        ),
      ),
    );
  }
}
