import 'package:flutter/material.dart';

import '../app/router.dart';
import '../state/auth_session_controller.dart';
import '../state/game_controller.dart';
import '../state/lobby_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/board_sheet.dart';
import '../widgets/common_card.dart';
import '../widgets/game_audit_panel.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController controller;

  @override
  void initState() {
    super.initState();
    controller = GameController()..init();
    lobbyController.init();
  }

  @override
  void dispose() {
    controller.disposeController();
    controller.dispose();
    super.dispose();
  }

  Color _cellColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'yellow':
        return AppPalette.tileYellow;
      case 'orange':
        return AppPalette.tileOrange;
      case 'blue':
        return AppPalette.tileBlue;
      case 'green':
        return AppPalette.tileGreen;
      case 'purple':
        return AppPalette.tilePurple;
      default:
        return AppPalette.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (authSessionController.initialized && !authSessionController.hasSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
      });
    }

    return AnimatedBuilder(
      animation: Listenable.merge([controller, lobbyController, authSessionController]),
      builder: (context, _) {
        final board = (controller.state?['board'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

        return Scaffold(
          appBar: AppBar(title: const Text('Game')),
          body: Row(
            children: [
              SizedBox(
                width: 420,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    CommonCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Match Controls', style: AppTextStyles.subtitle),
                          const SizedBox(height: AppSpacing.sm),
                          if (lobbyController.lobbyCode != null)
                            Text(
                              'Lobby: ${lobbyController.lobbyCode} • ${lobbyController.lobbyName.isEmpty ? 'Untitled' : lobbyController.lobbyName}',
                            ),
                          Text('Realtime: ${lobbyController.realtimeStatus.name}'),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Phase: ${controller.phase}'),
                          if (controller.sessionId != null) Text('Session: ${controller.sessionId}'),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton(onPressed: controller.canRoll ? controller.roll : null, child: const Text('Roll Dice')),
                              OutlinedButton(onPressed: controller.canActivePass ? controller.activePass : null, child: const Text('Active Pass')),
                              OutlinedButton(onPressed: controller.reloadState, child: const Text('Refresh State')),
                              OutlinedButton(onPressed: controller.loadScoreAndEvents, child: const Text('Refresh Score & Timeline')),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          InputDecorator(
                            decoration: const InputDecoration(labelText: 'Color die'),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: controller.selectedColorDie,
                                items: controller.availableColorDice.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                                onChanged: controller.setSelectedColorDie,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InputDecorator(
                            decoration: const InputDecoration(labelText: 'Number die'),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: controller.selectedNumberDie,
                                items: controller.availableNumberDice.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                                onChanged: controller.setSelectedNumberDie,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Selected cells: ${controller.selectedCellIds.length}'),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton(
                                onPressed: controller.canSubmitActiveSelection ? controller.submitActiveSelection : null,
                                child: const Text('Confirm Active Selection'),
                              ),
                              ElevatedButton(
                                onPressed: controller.canSubmitMove ? controller.submitPlayerMove : null,
                                child: const Text('Submit Move'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(controller.status),
                          const SizedBox(height: AppSpacing.md),
                          GameAuditPanel(scores: controller.scores, events: controller.events),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CommonCard(
                  child: board.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('No active match yet.'),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.createLobby),
                                child: const Text('Create Lobby'),
                              ),
                            ],
                          ),
                        )
                      : BoardSheet(
                          board: board,
                          colorFor: _cellColor,
                          selectedCellIds: controller.selectedCellIds,
                          onCellTap: controller.toggleCellSelection,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
