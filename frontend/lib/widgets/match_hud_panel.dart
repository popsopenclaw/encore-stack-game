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
    final currentRoll = controller.state?['currentRoll'] as Map<String, dynamic>?;
    final colorDice = ((currentRoll?['colorDice'] as List<dynamic>?) ?? const []).map((e) => '$e').toList();
    final numberDice = ((currentRoll?['numberDice'] as List<dynamic>?) ?? const []).map((e) => '$e').toList();

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Match HUD', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppPalette.scaffoldBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppPalette.borderLight),
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                AppMetaPill(text: 'Phase ${controller.phase}'),
                if (controller.sessionId != null) AppMetaPill(text: 'Session ${controller.sessionId!.substring(0, 8)}'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppPalette.scaffoldBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppPalette.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Roll', style: AppTextStyles.subtitle),
                const SizedBox(height: AppSpacing.sm),
                if (colorDice.isEmpty && numberDice.isEmpty)
                  const Text('Roll to reveal dice', style: AppTextStyles.body)
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ...colorDice.map((d) => DieChip(text: d, bg: AppPalette.fromGameColor(d), fg: AppPalette.textPrimary)),
                      ...numberDice.map((d) => DieChip(text: _prettyEnum(d), bg: AppPalette.white, fg: AppPalette.textPrimary)),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton(onPressed: controller.canRoll ? controller.roll : null, child: const Text('Roll')),
              FilledButton.tonal(onPressed: controller.canActivePass ? controller.activePass : null, child: const Text('Pass')),
              OutlinedButton(onPressed: controller.reloadState, child: const Text('Refresh')),
              OutlinedButton(onPressed: controller.loadScoreAndEvents, child: const Text('Score/Timeline')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: controller.selectedColorDie,
                  decoration: const InputDecoration(labelText: 'Color Die'),
                  items: controller.availableColorDice
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: controller.setSelectedColorDie,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: controller.selectedNumberDie,
                  decoration: const InputDecoration(labelText: 'Number Die'),
                  items: controller.availableNumberDice
                      .map((d) => DropdownMenuItem(value: d, child: Text(_prettyEnum(d))))
                      .toList(),
                  onChanged: controller.setSelectedNumberDie,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Selected cells: ${controller.selectedCellIds.length}', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
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
          Text(controller.status, style: AppTextStyles.body),
        ],
      ),
    );
  }

  static String _prettyEnum(String raw) {
    final s = raw.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    return s[0].toUpperCase() + s.substring(1);
  }
}
