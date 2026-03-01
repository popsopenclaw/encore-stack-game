import 'package:flutter/material.dart';

import '../app/router.dart';

class JoinLobbyScreen extends StatelessWidget {
  const JoinLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Lobby')),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
