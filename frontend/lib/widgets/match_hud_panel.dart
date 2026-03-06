import 'package:flutter/material.dart';

import '../state/game_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'ui_kit.dart';

class MatchHudPanel extends StatelessWidget {
  const MatchHudPanel({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final colorDice = controller.availableColorDice;
    final numberDice = controller.availableNumberDice;
    final actionButtons = <Widget>[
      if (controller.canRoll)
        FilledButton.icon(
          onPressed: controller.roll,
          icon: const Icon(Icons.casino, size: 16),
          label: const Text('Roll'),
        ),
      if (controller.canActivePass)
        FilledButton.tonalIcon(
          onPressed: controller.activePass,
          icon: const Icon(Icons.fast_forward, size: 16),
          label: const Text('Pass'),
        ),
      if (controller.canSubmitActiveSelection)
        FilledButton(
          onPressed: controller.submitActiveSelection,
          child: const Text('Confirm'),
        ),
      if (controller.canSubmitMove)
        FilledButton(
          onPressed: controller.submitPlayerMove,
          child: const Text('Submit'),
        ),
    ];

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
              _darkPill('Turn: ${controller.turnPlayerName}'),
              _darkPill('Board: ${controller.selectedBoardPlayerName}'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (colorDice.isEmpty && numberDice.isEmpty)
            const Text(
              'No dice available right now.',
              style: AppTextStyles.bodyMuted,
            )
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
                  enabled: controller.canPickDice,
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
                  enabled: controller.canPickDice,
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
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (controller.isViewingOwnBoard ||
                  controller.selectedCellIds.isNotEmpty)
                _darkPill('Selected ${controller.selectedCellIds.length}'),
              ...actionButtons,
            ],
          ),
          if (controller.validationMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              controller.validationMessage!,
              style: const TextStyle(
                color: AppPalette.danger,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(controller.status, style: AppTextStyles.bodyMuted),
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
