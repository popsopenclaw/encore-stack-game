import 'package:flutter/material.dart';

import '../state/game_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'ui_kit.dart';

class MatchHudPanel extends StatelessWidget {
  const MatchHudPanel({
    super.key,
    required this.controller,
    required this.onOpenTimeline,
  });

  final GameController controller;
  final VoidCallback onOpenTimeline;

  @override
  Widget build(BuildContext context) {
    final resolverIdx = controller.currentResolvingPlayerIndex;
    final resolver = controller.currentResolvingPlayer;
    final resolverName =
        resolver?['name']?.toString() ??
        (resolverIdx == null ? '-' : 'P${resolverIdx + 1}');
    final inActiveSelection = controller.phase == 'NeedActiveSelection';
    final inPlayersResolving = controller.phase == 'PlayersResolving';
    final canPickDice = inActiveSelection || inPlayersResolving;
    final colorDice = controller.availableColorDice;
    final numberDice = controller.availableNumberDice;

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Controls', style: AppTextStyles.subtitle),
              _darkPill('Phase ${_prettyEnum(controller.phase)}'),
              _darkPill('Resolver $resolverName'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (colorDice.isEmpty && numberDice.isEmpty)
            const Text('Roll to reveal dice', style: AppTextStyles.bodyMuted)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DiceGroup(
                  label: 'Color',
                  keyPrefix: 'color-die',
                  options: colorDice,
                  selected: controller.selectedColorDie,
                  onSelect: controller.setSelectedColorDie,
                  enabled: canPickDice,
                  textFor: (d) => d,
                  bgFor: AppPalette.fromGameColor,
                  fgFor: (_) => AppPalette.black,
                ),
                const SizedBox(height: AppSpacing.xs),
                _DiceGroup(
                  label: 'Number',
                  keyPrefix: 'number-die',
                  options: numberDice,
                  selected: controller.selectedNumberDie,
                  onSelect: controller.setSelectedNumberDie,
                  enabled: canPickDice,
                  textFor: _prettyEnum,
                  bgFor: (_) => AppPalette.surfaceRaised,
                  fgFor: (_) => AppPalette.textPrimary,
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
              OutlinedButton.icon(
                onPressed: controller.reloadState,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
              FilledButton.icon(
                onPressed: onOpenTimeline,
                icon: const Icon(Icons.timeline, size: 16),
                label: const Text('Open Scores / Timeline'),
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
              Text(controller.status, style: AppTextStyles.bodyMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Solo mode rules are not supported in this build.',
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ),
    );
  }

  Widget _darkPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppPalette.surfaceInset,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppPalette.borderLight),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppPalette.textOnDark,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.25,
        ),
      ),
    );
  }

  static String _prettyEnum(String raw) {
    final s = raw.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );
    if (s.isEmpty) return raw;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _DiceGroup extends StatelessWidget {
  const _DiceGroup({
    required this.label,
    required this.keyPrefix,
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.enabled,
    required this.textFor,
    required this.bgFor,
    required this.fgFor,
  });

  final String label;
  final String keyPrefix;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelect;
  final bool enabled;
  final String Function(String value) textFor;
  final Color Function(String value) bgFor;
  final Color Function(String value) fgFor;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyMuted),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children:
              options
                  .map(
                    (d) => DieChip(
                      key: ValueKey('$keyPrefix-$d'),
                      text: textFor(d),
                      bg: bgFor(d),
                      fg: fgFor(d),
                      selected: selected == d,
                      enabled: enabled,
                      onTap: () => onSelect(d),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}
