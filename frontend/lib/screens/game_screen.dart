import 'package:flutter/material.dart';

import '../app/router.dart';
import '../state/auth_session_controller.dart';
import '../state/game_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../widgets/board_sheet.dart';
import '../widgets/common_card.dart';
import '../widgets/game_audit_panel.dart';
import '../widgets/match_hud_panel.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController controller;
  bool _sessionHydrated = false;

  @override
  void initState() {
    super.initState();
    controller = GameController()..init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionHydrated) return;
    _sessionHydrated = true;
    final sid = ModalRoute.of(context)?.settings.arguments as String?;
    if (sid != null && sid.isNotEmpty) {
      controller.loadSession(sid);
    }
  }

  @override
  void dispose() {
    controller.disposeController();
    controller.dispose();
    super.dispose();
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
      animation: Listenable.merge([controller, authSessionController]),
      builder: (context, _) {
        final board = (controller.state?['board'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

        return Scaffold(
          appBar: AppBar(title: const Text('Game')),
          body: Row(
            children: [
              Expanded(
                flex: 2,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    MatchHudPanel(controller: controller),
                    const SizedBox(height: AppSpacing.sm),
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
                              const Text('No active game loaded.'),
                              const SizedBox(height: AppSpacing.md),
                              OutlinedButton(
                                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false),
                                child: const Text('Back to Home'),
                              ),
                            ],
                          ),
                        )
                      : BoardSheet(
                          board: board,
                          colorFor: AppPalette.fromGameColor,
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
