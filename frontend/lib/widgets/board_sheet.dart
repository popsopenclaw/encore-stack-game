import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';

class BoardSheet extends StatelessWidget {
  const BoardSheet({
    super.key,
    required this.board,
    required this.checkedCellIds,
    required this.colorFor,
    required this.selectedCellIds,
    required this.onCellTap,
    this.interactionEnabled = true,
    this.blockedCellIds = const <String>{},
    this.interactionHint,
    this.blockedTapHintForCell,
    this.onBlockedTapHint,
    this.reachableCellIds = const <String>{},
  });

  final List<Map<String, dynamic>> board;
  final Set<String> checkedCellIds;
  final Color Function(String) colorFor;
  final Set<String> selectedCellIds;
  final void Function(String cellId) onCellTap;
  final bool interactionEnabled;
  final Set<String> blockedCellIds;
  final String? interactionHint;
  final String Function(String cellId)? blockedTapHintForCell;
  final void Function(String message)? onBlockedTapHint;
  final Set<String> reachableCellIds;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1A3F), Color(0xFF071431), Color(0xFF060F27)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.panelLine),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.neonGlow,
            blurRadius: 18,
            spreadRadius: -3,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 780;

          return Column(
            children: [
              Expanded(
                child:
                    compact
                        ? Column(
                          children: [
                            Expanded(
                              child: BoardGrid(
                                board: board,
                                checkedCellIds: checkedCellIds,
                                colorFor: colorFor,
                                selectedCellIds: selectedCellIds,
                                onCellTap: onCellTap,
                                interactionEnabled: interactionEnabled,
                                blockedCellIds: blockedCellIds,
                                blockedTapHintForCell: blockedTapHintForCell,
                                onBlockedTapHint: onBlockedTapHint,
                                reachableCellIds: reachableCellIds,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const SideScoreLegend(compact: true),
                          ],
                        )
                        : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: BoardGrid(
                                board: board,
                                checkedCellIds: checkedCellIds,
                                colorFor: colorFor,
                                selectedCellIds: selectedCellIds,
                                onCellTap: onCellTap,
                                interactionEnabled: interactionEnabled,
                                blockedCellIds: blockedCellIds,
                                blockedTapHintForCell: blockedTapHintForCell,
                                onBlockedTapHint: onBlockedTapHint,
                                reachableCellIds: reachableCellIds,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const SideScoreLegend(),
                          ],
                        ),
              ),
              if (interactionHint != null && interactionHint!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    interactionHint!,
                    style: AppTextStyles.bodyMuted.copyWith(
                      color: AppPalette.textOnDark,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const BottomRulesStrip(),
            ],
          );
        },
      ),
    );
  }
}

class SideScoreLegend extends StatelessWidget {
  const SideScoreLegend({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    Widget row(Color c, String a, String b) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: AppPalette.white.withValues(alpha: 0.25),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _pill(a),
            const SizedBox(width: 4),
            _pill(b),
          ],
        ),
      );
    }

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SCORES',
          style: TextStyle(
            color: AppPalette.neonCyan,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 8),
        row(AppPalette.tileGreen, '5', '3'),
        row(AppPalette.tileYellow, '5', '3'),
        row(AppPalette.tileBlue, '5', '3'),
        row(AppPalette.tilePurple, '5', '3'),
        row(AppPalette.tileOrange, '5', '3'),
        const SizedBox(height: 10),
        const _RuleLine('A-O', '+5', AppPalette.success),
        const _RuleLine('!', '+1', AppPalette.success),
        const _RuleLine('★', '-2', AppPalette.danger),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppPalette.surfaceInset,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppPalette.borderLight),
          ),
          child: const Text('TOTAL =', style: AppTextStyles.boardLabel),
        ),
      ],
    );

    if (compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppPalette.surfaceInset,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppPalette.borderLight),
        ),
        child: body,
      );
    }

    return SizedBox(width: 190, child: body);
  }

  Widget _pill(String t) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppPalette.surfaceInset,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppPalette.borderLight),
      ),
      child: Text(
        t,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: AppPalette.textPrimary,
        ),
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine(this.label, this.value, this.valueColor);

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: AppPalette.surfaceInset,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppPalette.borderLight),
              ),
              child: Text(
                label,
                style: AppTextStyles.boardHeader.copyWith(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTextStyles.boardHeader.copyWith(
              color: valueColor,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class BottomRulesStrip extends StatelessWidget {
  const BottomRulesStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF081B41), Color(0xFF071330)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppPalette.borderLight),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _capsule('?'),
            const SizedBox(width: 6),
            _capsule('✖'),
            const SizedBox(width: 6),
            const Text('=', style: AppTextStyles.boardLabel),
            const SizedBox(width: 10),
            ...List.generate(
              8,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _circle('!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _capsule(String t) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppPalette.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppPalette.borderLight),
      ),
      child: Text(t, style: AppTextStyles.boardHeader.copyWith(fontSize: 18)),
    );
  }

  Widget _circle(String t) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppPalette.surfaceRaised,
        shape: BoxShape.circle,
        border: Border.all(color: AppPalette.borderLight),
      ),
      child: Text(t, style: AppTextStyles.boardHeader.copyWith(fontSize: 17)),
    );
  }
}

class BoardGrid extends StatelessWidget {
  const BoardGrid({
    super.key,
    required this.board,
    required this.checkedCellIds,
    required this.colorFor,
    required this.selectedCellIds,
    required this.onCellTap,
    required this.interactionEnabled,
    required this.blockedCellIds,
    this.blockedTapHintForCell,
    this.onBlockedTapHint,
    this.reachableCellIds = const <String>{},
  });

  final List<Map<String, dynamic>> board;
  final Set<String> checkedCellIds;
  final Color Function(String) colorFor;
  final Set<String> selectedCellIds;
  final void Function(String cellId) onCellTap;
  final bool interactionEnabled;
  final Set<String> blockedCellIds;
  final String Function(String cellId)? blockedTapHintForCell;
  final void Function(String message)? onBlockedTapHint;
  final Set<String> reachableCellIds;

  @override
  Widget build(BuildContext context) {
    final maxX = board
        .map((e) => e['x'] as int)
        .reduce((a, b) => a > b ? a : b);
    final maxY = board
        .map((e) => e['y'] as int)
        .reduce((a, b) => a > b ? a : b);
    final grid = <String, Map<String, dynamic>>{
      for (final c in board) '${c['x']}_${c['y']}': c,
    };

    const topPts = [5, 3, 3, 3, 2, 2, 2, 1, 2, 2, 2, 3, 3, 3, 5];
    const lowPts = [3, 2, 2, 2, 1, 1, 1, 0, 1, 1, 1, 2, 2, 2, 3];
    const letters = 'ABCDEFGHIJKLMNO';

    Widget pill(String t, {Color? bg, Color? fg}) {
      return Container(
        width: 30,
        height: 26,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: bg ?? AppPalette.surfaceInset,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppPalette.borderLight),
        ),
        alignment: Alignment.center,
        child: Text(
          t,
          style: AppTextStyles.boardHeader.copyWith(
            color: fg ?? AppPalette.textPrimary,
            fontSize: 14,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                15,
                (i) => pill(
                  letters[i],
                  fg: i == 7 ? AppPalette.red : AppPalette.textPrimary,
                ),
              ),
            ),
            ...List.generate(maxY + 1, (y) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(maxX + 1, (x) {
                  final c = grid['${x}_$y'];
                  if (c == null) return const SizedBox(width: 30, height: 30);
                  final cellId = c['id'] as String;
                  final isChecked = checkedCellIds.contains(cellId);
                  final isSelected = selectedCellIds.contains(cellId);
                  final isBlocked = blockedCellIds.contains(cellId);
                  final isTapEnabled = interactionEnabled && !isBlocked;
                  final isReachable = reachableCellIds.isEmpty ||
                      reachableCellIds.contains(cellId) ||
                      isChecked ||
                      isSelected;

                  return Opacity(
                    opacity: isReachable ? 1.0 : 0.4,
                    child: GestureDetector(
                    onTap: () {
                      if (isTapEnabled) {
                        onCellTap(cellId);
                        return;
                      }
                      final hint = blockedTapHintForCell?.call(cellId);
                      if (hint != null && hint.isNotEmpty) {
                        onBlockedTapHint?.call(hint);
                      }
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colorFor(
                              (c['color'] as String),
                            ).withValues(alpha: isChecked ? 1 : 0.94),
                            colorFor(
                              (c['color'] as String),
                            ).withValues(alpha: isChecked ? 0.86 : 0.78),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppPalette.neonCyan
                                  : isChecked
                                  ? AppPalette.white
                                  : AppPalette.white.withValues(alpha: 0.32),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            const BoxShadow(
                              color: AppPalette.neonGlow,
                              blurRadius: 8,
                              spreadRadius: -2,
                            ),
                          if (isChecked)
                            const BoxShadow(
                              color: AppPalette.neonBlue,
                              blurRadius: 8,
                              spreadRadius: -4,
                            ),
                        ],
                      ),
                      child:
                          isSelected || isChecked
                              ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: AppPalette.white,
                              )
                              : (c['starred'] as bool)
                              ? const Icon(
                                Icons.star,
                                size: 16,
                                color: AppPalette.white,
                              )
                              : null,
                    ),
                  ),
                  );
                }),
              );
            }),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                15,
                (i) => pill(
                  '${topPts[i]}',
                  fg: i == 7 ? AppPalette.red : AppPalette.textPrimary,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                15,
                (i) => pill(
                  '${lowPts[i]}',
                  fg: i == 7 ? AppPalette.red : AppPalette.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
