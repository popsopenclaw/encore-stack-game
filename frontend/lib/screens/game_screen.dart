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

  Color _dieColor(String die) {
    switch (die.toLowerCase()) {
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
        return AppPalette.white;
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
        final currentRoll = controller.state?['currentRoll'] as Map<String, dynamic>?;
        final colorDice = ((currentRoll?['colorDice'] as List<dynamic>?) ?? const []).map((e) => '$e').toList();
        final numberDice = ((currentRoll?['numberDice'] as List<dynamic>?) ?? const []).map((e) => '$e').toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Game')),
          body: Row(
            children: [
              SizedBox(
                width: 430,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppPalette.boardFrame,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(color: AppPalette.boardFrameShadow, blurRadius: 14, offset: Offset(0, 8)),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Match Controls', style: AppTextStyles.subtitle.copyWith(color: AppPalette.textOnDark)),
                          const SizedBox(height: AppSpacing.xs),
                          if (lobbyController.lobbyCode != null)
                            Text(
                              'Lobby: ${lobbyController.lobbyCode} • ${lobbyController.lobbyName.isEmpty ? 'Untitled' : lobbyController.lobbyName}',
                              style: const TextStyle(color: AppPalette.textOnDark),
                            ),
                          Text('Realtime: ${lobbyController.realtimeStatus.name}', style: const TextStyle(color: AppPalette.textOnDark)),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Phase: ${controller.phase}', style: const TextStyle(color: AppPalette.textOnDark)),
                          if (controller.sessionId != null)
                            Text('Session: ${controller.sessionId}', style: const TextStyle(color: AppPalette.textOnDark)),

                          const SizedBox(height: AppSpacing.md),
                          if (colorDice.isNotEmpty || numberDice.isNotEmpty) ...[
                            Text('Current Roll', style: AppTextStyles.subtitle.copyWith(color: AppPalette.textOnDark)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ...colorDice.map((d) => _dieChip(d, _dieColor(d), AppPalette.textPrimary)),
                                ...numberDice.map((d) => _dieChip(_prettyEnum(d), AppPalette.white, AppPalette.textPrimary)),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton(onPressed: controller.canRoll ? controller.roll : null, child: const Text('Roll Dice')),
                              OutlinedButton(onPressed: controller.canActivePass ? controller.activePass : null, child: const Text('Active Pass')),
                              OutlinedButton(onPressed: controller.reloadState, child: const Text('Refresh State')),
                              OutlinedButton(onPressed: controller.loadScoreAndEvents, child: const Text('Refresh Score & Timeline')),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          InputDecorator(
                            decoration: const InputDecoration(labelText: 'Color die', filled: true, fillColor: AppPalette.white),
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
                            decoration: const InputDecoration(labelText: 'Number die', filled: true, fillColor: AppPalette.white),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: controller.selectedNumberDie,
                                items: controller.availableNumberDice.map((d) => DropdownMenuItem(value: d, child: Text(_prettyEnum(d)))).toList(),
                                onChanged: controller.setSelectedNumberDie,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Selected cells: ${controller.selectedCellIds.length}', style: const TextStyle(color: AppPalette.textOnDark)),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton(
                                onPressed: controller.canSubmitActiveSelection ? controller.submitActiveSelection : null,
                                child: const Text('Confirm Active Selection'),
                              ),
                              FilledButton(
                                onPressed: controller.canSubmitMove ? controller.submitPlayerMove : null,
                                child: const Text('Submit Move'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(controller.status, style: const TextStyle(color: AppPalette.textOnDark)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    CommonCard(child: GameAuditPanel(scores: controller.scores, events: controller.events)),
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
                              if (lobbyController.lobbyCode != null)
                                ElevatedButton.icon(
                                  onPressed: () => controller.startMatchFromLobby(lobbyController.lobbyCode!),
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Start Match'),
                                )
                              else
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

  Widget _dieChip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppPalette.borderDark),
      ),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
    );
  }

  String _prettyEnum(String raw) {
    final s = raw.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    return s[0].toUpperCase() + s.substring(1);
  }
}
