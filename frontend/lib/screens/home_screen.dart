import 'package:flutter/material.dart';

import '../app/router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.profile), icon: const Icon(Icons.person)),
          IconButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.settings), icon: const Icon(Icons.settings)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.createLobby),
              child: const Text('Create Lobby'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.joinLobby),
              child: const Text('Join Lobby'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.game),
              child: const Text('Open Game (Dev)'),
            ),
          ],
        ),
      ),
    );
  }
}
