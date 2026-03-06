import 'package:flutter/material.dart';

import '../app/router.dart';
import '../services/api_client.dart';
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

  Future<void> _showAuditSheet(BuildContext context) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.62,
          child: CommonCard(
            child: GameAuditPanel(
              scores: controller.scores,
              events: controller.events,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (authSessionController.initialized &&
        !authSessionController.hasSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (_) => false,
        );
      });
    }

    return AnimatedBuilder(
      animation: Listenable.merge([controller, authSessionController]),
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
        final isWide = MediaQuery.sizeOf(context).width > 1080;

        return Scaffold(
          appBar: AppBar(title: const Text('Game')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? AppSpacing.lg : AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  child:
                      board.isEmpty
                          ? CommonCard(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(emptyMessage),
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
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: CommonCard(
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
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              MatchHudPanel(
                                controller: controller,
                                onShowAudit: () => _showAuditSheet(context),
                              ),
                            ],
                          ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
