import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class GameAuditPanel extends StatelessWidget {
  const GameAuditPanel({super.key, required this.scores, required this.events});

  final List<dynamic> scores;
  final List<dynamic> events;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Match Log', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppPalette.surfaceRaised,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppPalette.borderLight),
            ),
            child: const TabBar(
              dividerColor: Colors.transparent,
              tabs: [Tab(text: 'Scores'), Tab(text: 'Timeline')],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 220,
            child: Container(
              decoration: BoxDecoration(
                color: AppPalette.surfaceRaised,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppPalette.borderLight),
              ),
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: TabBarView(
                children: [
                  _ScoresView(scores: scores),
                  _TimelineView(events: events),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditListTile extends StatelessWidget {
  const _AuditListTile({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final Widget title;
  final Widget subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.borderLight),
      ),
      child: ListTile(
        dense: true,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
      ),
    );
  }
}

class _ScoresView extends StatelessWidget {
  const _ScoresView({required this.scores});
  final List<dynamic> scores;

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      return const Center(child: Text('No score data loaded yet.'));
    }

    return ListView.separated(
      itemCount: scores.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final row = (scores[index] as Map).map((k, v) => MapEntry('$k', v));
        return _AuditListTile(
          title: Text(row['player']?.toString() ?? 'Player ${index + 1}'),
          subtitle: Text(
            'Columns ${row['columns']} • Colors ${row['colors']} • Exclamation bonus ${row['jokerBonus']} • Star penalty ${row['starPenalty']} (max -30)',
            style: AppTextStyles.bodyMuted,
          ),
          trailing: Text(
            '${(row['isWinner'] == true) ? 'Winner • ' : ''}R${row['rank'] ?? '-'} • T${row['tiebreakExclamationMarks'] ?? row['jokerBonus'] ?? '-'}\nTotal ${row['total']}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );
      },
    );
  }
}

class _TimelineView extends StatelessWidget {
  const _TimelineView({required this.events});
  final List<dynamic> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(child: Text('No timeline events loaded yet.'));
    }

    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final row = (events[index] as Map).map((k, v) => MapEntry('$k', v));
        return _AuditListTile(
          title: Text('T${row['turn'] ?? '?'} • ${row['type'] ?? 'event'}'),
          subtitle: Text(
            'Player ${row['playerIndex'] ?? '-'} • ${row['data'] ?? ''}',
            style: AppTextStyles.bodyMuted,
          ),
        );
      },
    );
  }
}
