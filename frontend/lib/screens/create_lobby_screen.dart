import 'package:flutter/material.dart';

import '../app/router.dart';

class CreateLobbyScreen extends StatelessWidget {
  const CreateLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Lobby')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Lobby name')),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Max players (1-6)')),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.game),
              child: const Text('Create & Start'),
            ),
          ],
        ),
      ),
    );
  }
}
