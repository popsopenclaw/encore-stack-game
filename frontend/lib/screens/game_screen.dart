import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/game_controller.dart';
import '../state/lobby_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/backend_url_section.dart';
import '../widgets/board_sheet.dart';
import '../widgets/common_card.dart';
import '../widgets/primary_actions_section.dart';
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
    return AnimatedBuilder(
      animation: Listenable.merge([controller, lobbyController]),
      builder: (context, _) {
        final board = (controller.state?['board'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

        return Scaffold(
          appBar: AppBar(title: const Text('Game')),
          body: Row(
            children: [
              SizedBox(
                width: 390,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    CommonCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          BackendUrlSection(
                            controller: controller.backendUrl,
                            onSave: controller.saveBackendUrl,
                            onUseLocal: controller.setLocalBackend,
                            onUseProduction: controller.setProductionBackend,
                          ),
                          Text('Connection', style: AppTextStyles.subtitle),
                        const SizedBox(height: AppSpacing.xs),
                        TextField(controller: controller.players, decoration: const InputDecoration(labelText: 'Players comma-separated')),
                          const SizedBox(height: AppSpacing.md),
                          Text('Session Actions', style: AppTextStyles.subtitle),
                          const SizedBox(height: AppSpacing.xs),
                          PrimaryActionsSection(
                            onOAuthUrl: () => controller.githubLoginUrl(
                              (url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                            ),
                            onExchange: controller.exchange,
                            onStartGame: controller.startGame,
                            onReload: controller.reloadState,
                            onRoll: controller.roll,
                            onActivePass: controller.activePass,
                            onAllPass: controller.allPassOnce,
                            onScoreEvents: controller.loadScoreAndEvents,
                          ),
                          TextField(controller: controller.oauthCode, decoration: const InputDecoration(labelText: 'OAuth code')),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: controller.loadAvailableDiceForCurrentPlayer,
                            child: const Text('Load Available Dice'),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: controller.selectedColorDie,
                            items: controller.availableColorDice
                                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                .toList(),
                            onChanged: controller.setSelectedColorDie,
                            decoration: const InputDecoration(labelText: 'Selected Color Die'),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: controller.selectedNumberDie,
                            items: controller.availableNumberDice
                                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                .toList(),
                            onChanged: controller.setSelectedNumberDie,
                            decoration: const InputDecoration(labelText: 'Selected Number Die'),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(onPressed: controller.submitActiveSelection, child: const Text('Submit Active Selection')),
                              OutlinedButton(onPressed: controller.submitPlayerMove, child: const Text('Submit Move (Selected Cells)')),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(controller.status),
                          if (controller.sessionId != null) Text('Session: ${controller.sessionId}'),
                          if (controller.scores.isNotEmpty) Text('Scores loaded: ${controller.scores.length}'),
                          if (controller.events.isNotEmpty) Text('Events loaded: ${controller.events.length}'),
                        if (lobbyController.lobbyCode != null)
                          Text('Lobby: ${lobbyController.lobbyCode} • ${lobbyController.lobbyName.isEmpty ? 'Untitled' : lobbyController.lobbyName}'),
                        const SizedBox(height: 8),
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
                      ? const Center(child: Text('Start a game to render board'))
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
