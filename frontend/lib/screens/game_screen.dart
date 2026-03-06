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

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.controllerOverride});

  final GameController? controllerOverride;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController controller;
  late final Future<void> _controllerInit;
  late final bool _ownsController;
  bool _sessionHydrated = false;

  @override
  void initState() {
    super.initState();
    controller = widget.controllerOverride ?? GameController();
    _ownsController = widget.controllerOverride == null;
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
    if (_ownsController) {
      controller.disposeController();
      controller.dispose();
    }
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
                          final stackedBoardHeight =
                              constraints.maxHeight.clamp(520.0, 760.0);
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

                          if (!wide) {
                            return ListView(
                              children: [
                                SizedBox(
                                  height: stackedBoardHeight,
                                  child: boardPanel,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                MatchHudPanel(
                                  controller: controller,
                                  onOpenTimeline: _openAuditPanel,
                                ),
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 10, child: boardPanel),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                flex: 4,
                                child: MatchHudPanel(
                                  controller: controller,
                                  onOpenTimeline: _openAuditPanel,
                                ),
                              ),
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
