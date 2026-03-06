import 'package:flutter/material.dart';

import '../app/router.dart';
import '../services/api_client.dart';
import '../state/game_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/board_sheet.dart';
import '../widgets/common_card.dart';
import '../widgets/game_audit_panel.dart';
import '../widgets/match_hud_panel.dart';
import '../widgets/ui_kit.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController controller;
  late final Future<void> _controllerInit;
  bool _sessionHydrated = false;

  @override
  void initState() {
    super.initState();
    controller = GameController();
    _controllerInit = controller.init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionHydrated) return;
    _sessionHydrated = true;
    _hydrateSession();
  }

  Future<void> _hydrateSession() async {
    await _controllerInit;
    if (!mounted) return;
    final sid = ModalRoute.of(context)?.settings.arguments as String?;
    if (sid != null && sid.isNotEmpty) {
      await controller.loadSession(sid);
      return;
    }
    await _restoreLastSession();
  }

  Future<void> _restoreLastSession() async {
    final restored = await controller.restoreLastSessionIfAny();
    if (!mounted || restored) return;
    final code = controller.lastLoadErrorCode;
    if (code == ApiErrorCode.notFound || code == ApiErrorCode.forbidden) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Previous game session is unavailable.')),
      );
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    }
  }

  @override
  void dispose() {
    controller.disposeController();
    controller.dispose();
    super.dispose();
  }

  Future<void> _openAuditPanel() async {
    await controller.loadScoreAndEvents();
    if (!mounted) return;
    await _showAuditSheet();
  }

  Future<void> _showAuditSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.68,
          child: CommonCard(
            child: GameAuditPanel(
              scores: controller.scores,
              events: controller.events,
              matchInfo: _buildMatchInfo(),
            ),
          ),
        );
      },
    );
  }

  GameAuditMatchInfo _buildMatchInfo() {
    final resolverIdx = controller.currentResolvingPlayerIndex;
    final resolver = controller.currentResolvingPlayer;
    final resolverName =
        resolver?['name']?.toString() ??
        (resolverIdx == null ? '-' : 'P${resolverIdx + 1}');

    return GameAuditMatchInfo(
      sessionId: controller.sessionId,
      phase: controller.phase,
      resolver: resolverName,
      openDraftTurnsRemaining: controller.openDraftTurnsRemaining,
      jokersRemaining: controller.currentResolvingPlayerJokers,
      endTriggered: controller.endTriggered,
      isFinished: controller.isFinished,
      status: controller.status,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final board =
            (controller.state?['board'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        final loadCode = controller.lastLoadErrorCode;
        final missingOrForbidden =
            loadCode == ApiErrorCode.notFound ||
            loadCode == ApiErrorCode.forbidden;
        final emptyMessage =
            missingOrForbidden
                ? 'Previous game session is no longer available.'
                : (controller.attemptedAutoResume
                    ? 'No recent game session found.'
                    : 'No active game loaded.');

        return AppShell(
          title: 'Game',
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1420),
              child:
                  board.isEmpty
                      ? CommonCard(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emptyMessage, style: AppTextStyles.body),
                              const SizedBox(height: AppSpacing.md),
                              OutlinedButton(
                                onPressed:
                                    () => Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      AppRoutes.home,
                                      (_) => false,
                                    ),
                                child: const Text('Back to Home'),
                              ),
                            ],
                          ),
                        ),
                      )
                      : LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth > 1150;
                          final boardPanel = CommonCard(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: BoardSheet(
                              board: board,
                              colorFor: AppPalette.fromGameColor,
                              selectedCellIds: controller.selectedCellIds,
                              onCellTap: controller.toggleCellSelection,
                              interactionEnabled:
                                  controller.canInteractWithBoard,
                              blockedCellIds: controller.blockedCellIds,
                              blockedTapHintForCell:
                                  controller.hintForBlockedCellTap,
                              onBlockedTapHint: controller.showBoardHint,
                              interactionHint:
                                  controller.boardHintMessage ??
                                  (!controller.canInteractWithBoard
                                      ? 'Board interaction is enabled during Players Resolving.'
                                      : controller.validationMessage),
                            ),
                          );

                          final scorePanel = _ScorePreviewPanel(
                            scores: controller.scores,
                            status: controller.status,
                            onOpenTimeline: _openAuditPanel,
                          );

                          if (!wide) {
                            return ListView(
                              children: [
                                boardPanel,
                                const SizedBox(height: AppSpacing.sm),
                                scorePanel,
                                const SizedBox(height: AppSpacing.sm),
                                MatchHudPanel(controller: controller),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(flex: 10, child: boardPanel),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(flex: 4, child: scorePanel),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              MatchHudPanel(controller: controller),
                            ],
                          );
                        },
                      ),
            ),
          ),
        );
      },
    );
  }
}

class _ScorePreviewPanel extends StatelessWidget {
  const _ScorePreviewPanel({
    required this.scores,
    required this.status,
    required this.onOpenTimeline,
  });

  final List<dynamic> scores;
  final String status;
  final VoidCallback onOpenTimeline;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Scores', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          if (scores.isEmpty)
            const Text(
              'Scoreboard loads after opening timeline.',
              style: AppTextStyles.bodyMuted,
            )
          else
            ...scores.take(4).map((entry) {
              final row = (entry as Map).map((k, v) => MapEntry('$k', v));
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.surfaceInset,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppPalette.borderLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(row['player']?.toString() ?? 'Player'),
                      ),
                      Text(
                        '${row['total'] ?? '-'}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const Spacer(),
          Text(status, style: AppTextStyles.bodyMuted),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: onOpenTimeline,
            icon: const Icon(Icons.timeline),
            label: const Text('Open Scores / Timeline'),
          ),
        ],
      ),
    );
  }
}
