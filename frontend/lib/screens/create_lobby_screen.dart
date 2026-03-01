import 'package:flutter/material.dart';

import '../app/router.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';

class CreateLobbyScreen extends StatelessWidget {
  const CreateLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Create Lobby',
      child: CommonCard(
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
