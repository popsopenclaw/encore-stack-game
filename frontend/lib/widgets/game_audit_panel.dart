import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class GameAuditPanel extends StatelessWidget {
  const GameAuditPanel({
    super.key,
    required this.scores,
    required this.events,
  });

  final List<dynamic> scores;
  final List<dynamic> events;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Scores'),
              Tab(text: 'Timeline'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 220,
            child: TabBarView(
              children: [
                _ScoresView(scores: scores),
                _TimelineView(events: events),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoresView extends StatelessWidget {
  const _ScoresView({required this.scores});
  final List<dynamic> scores;

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) return const Center(child: Text('No score data loaded yet.'));

    return ListView.separated(
      itemCount: scores.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final row = (scores[index] as Map).map((k, v) => MapEntry('$k', v));
        return ListTile(
          dense: true,
          title: Text(row['player']?.toString() ?? 'Player ${index + 1}'),
          subtitle: Text('Columns: ${row['columns']} • Colors: ${row['colors']} • Jokers: ${row['jokerBonus']} • Star penalty: ${row['starPenalty']}'),
          trailing: Text('Total ${row['total']}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
    if (events.isEmpty) return const Center(child: Text('No timeline events loaded yet.'));

    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final row = (events[index] as Map).map((k, v) => MapEntry('$k', v));
        return ListTile(
          dense: true,
          title: Text('T${row['turn'] ?? '?'} • ${row['type'] ?? 'event'}'),
          subtitle: Text('Player: ${row['playerIndex'] ?? '-'} • ${row['data'] ?? ''}'),
        );
      },
    );
  }
}
