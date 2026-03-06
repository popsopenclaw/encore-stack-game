import 'package:flutter/material.dart';

import '../state/die_face_codec.dart';
import '../state/game_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'ui_kit.dart';

class MatchHudPanel extends StatelessWidget {
  const MatchHudPanel({
    super.key,
    required this.controller,
    required this.onShowAudit,
  });

  final GameController controller;
  final VoidCallback onShowAudit;

  @override
  Widget build(BuildContext context) {
    final currentRoll =
        controller.state?['currentRoll'] as Map<String, dynamic>?;
    final resolverIdx = controller.currentResolvingPlayerIndex;
    final resolver = controller.currentResolvingPlayer;
    final resolverName =
        resolver?['name']?.toString() ??
        (resolverIdx == null ? '-' : 'P${resolverIdx + 1}');
    final inActiveSelection = controller.phase == 'NeedActiveSelection';
    final inPlayersResolving = controller.phase == 'PlayersResolving';
    final canPickDice = inActiveSelection || inPlayersResolving;
    final colorDice = DieFaceCodec.colorFaces(currentRoll?['colorDice']);
    final numberDice = DieFaceCodec.numberFaces(currentRoll?['numberDice']);

    return Container(
      decoration: BoxDecoration(
        color: AppPalette.boardFrame,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.borderDark),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.boardFrameShadow,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Controls',
                style: TextStyle(
                  color: AppPalette.textOnDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              _darkPill('Phase ${_prettyEnum(controller.phase)}'),
              if (controller.sessionId != null)
                _darkPill('Session ${controller.sessionId!.substring(0, 8)}'),
              _darkPill('Resolver $resolverName'),
              _darkPill('Open draft ${controller.openDraftTurnsRemaining}'),
              _darkPill('! ${controller.currentResolvingPlayerJokers}'),
              if (controller.endTriggered) _darkPill('End triggered'),
              if (controller.isFinished) _darkPill('Finished'),
              OutlinedButton.icon(
                onPressed: () async {
                  await controller.loadScoreAndEvents();
                  onShowAudit();
                },
                icon: const Icon(Icons.timeline, size: 16),
                label: const Text('Scores / Timeline'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.textOnDark,
                  side: const BorderSide(color: AppPalette.borderLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              ...colorDice.map(
                (d) => DieChip(
                  text: d,
                  bg: AppPalette.fromGameColor(d),
                  fg: AppPalette.textPrimary,
                ),
              ),
              ...numberDice.map(
                (d) => DieChip(
                  text: _prettyEnum(d),
                  bg: AppPalette.white,
                  fg: AppPalette.textPrimary,
                ),
              ),
              if (colorDice.isEmpty && numberDice.isEmpty)
                const Text(
                  'Roll to reveal dice',
                  style: TextStyle(color: AppPalette.textOnDark),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              FilledButton.icon(
                onPressed: controller.canRoll ? controller.roll : null,
                icon: const Icon(Icons.casino, size: 16),
                label: const Text('Roll'),
              ),
              FilledButton.tonalIcon(
                onPressed:
                    controller.canActivePass ? controller.activePass : null,
                icon: const Icon(Icons.fast_forward, size: 16),
                label: const Text('Pass'),
              ),
              OutlinedButton.icon(
                onPressed: controller.reloadState,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.textOnDark,
                  side: const BorderSide(color: AppPalette.borderLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: controller.selectedColorDie,
                  dropdownColor: AppPalette.surfaceRaised,
                  style: AppTextStyles.body,
                  decoration: const InputDecoration(
                    labelText: 'Color',
                    isDense: true,
                  ),
                  items:
                      controller.availableColorDice
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                  onChanged:
                      canPickDice ? controller.setSelectedColorDie : null,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: controller.selectedNumberDie,
                  dropdownColor: AppPalette.surfaceRaised,
                  style: AppTextStyles.body,
                  decoration: const InputDecoration(
                    labelText: 'Number',
                    isDense: true,
                  ),
                  items:
                      controller.availableNumberDice
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(_prettyEnum(d)),
                            ),
                          )
                          .toList(),
                  onChanged:
                      canPickDice ? controller.setSelectedNumberDie : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _darkPill('Selected ${controller.selectedCellIds.length}'),
              FilledButton(
                onPressed:
                    controller.canSubmitActiveSelection
                        ? controller.submitActiveSelection
                        : null,
                child: const Text('Confirm'),
              ),
              FilledButton(
                onPressed:
                    controller.canSubmitMove
                        ? controller.submitPlayerMove
                        : null,
                child: const Text('Submit'),
              ),
              if (controller.validationMessage != null)
                Text(
                  controller.validationMessage!,
                  style: const TextStyle(
                    color: AppPalette.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              Text(
                controller.status,
                style: const TextStyle(
                  color: AppPalette.textOnDark,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Solo mode rules are not supported in this build.',
            style: TextStyle(color: AppPalette.textOnDark, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _darkPill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: AppPalette.stripBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppPalette.borderDark),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: AppPalette.textOnDark,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  static String _prettyEnum(String raw) {
    final s = raw.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );
    if (s.isEmpty) return raw;
    return s[0].toUpperCase() + s.substring(1);
  }
}
