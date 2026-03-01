import 'package:flutter/material.dart';

class PrimaryActionsSection extends StatelessWidget {
  const PrimaryActionsSection({
    super.key,
    required this.onOAuthUrl,
    required this.onExchange,
    required this.onStartGame,
    required this.onReload,
    required this.onRoll,
    required this.onActivePass,
    required this.onAllPass,
    required this.onScoreEvents,
  });

  final VoidCallback onOAuthUrl;
  final VoidCallback onExchange;
  final VoidCallback onStartGame;
  final VoidCallback onReload;
  final VoidCallback onRoll;
  final VoidCallback onActivePass;
  final VoidCallback onAllPass;
  final VoidCallback onScoreEvents;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(onPressed: onOAuthUrl, child: const Text('OAuth URL')),
            ElevatedButton(onPressed: onExchange, child: const Text('Exchange Code')),
            ElevatedButton(onPressed: onStartGame, child: const Text('Start Game')),
            ElevatedButton(onPressed: onReload, child: const Text('Reload')),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(onPressed: onRoll, child: const Text('Roll')),
            OutlinedButton(onPressed: onActivePass, child: const Text('Active Pass')),
            OutlinedButton(onPressed: onAllPass, child: const Text('All Pass Once')),
            OutlinedButton(onPressed: onScoreEvents, child: const Text('Score+Events')),
          ],
        ),
      ],
    );
  }
}
