import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class GameAuditMatchInfo {
  const GameAuditMatchInfo({
    required this.sessionId,
    required this.phase,
    required this.resolver,
    required this.openDraftTurnsRemaining,
    required this.jokersRemaining,
    required this.endTriggered,
    required this.isFinished,
    required this.status,
  });

  final String? sessionId;
  final String phase;
  final String resolver;
  final int openDraftTurnsRemaining;
  final int jokersRemaining;
  final bool endTriggered;
  final bool isFinished;
  final String status;
}

class GameAuditPanel extends StatelessWidget {
  const GameAuditPanel({
    super.key,
    required this.scores,
    required this.events,
    required this.matchInfo,
  });

  final List<dynamic> scores;
  final List<dynamic> events;
  final GameAuditMatchInfo matchInfo;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Match Log', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppPalette.surfaceInset,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppPalette.borderLight),
            ),
            child: const TabBar(
              tabs: [
                Tab(text: 'Scores'),
                Tab(text: 'Timeline'),
                Tab(text: 'Info'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppPalette.surfaceInset,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppPalette.borderLight),
              ),
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: TabBarView(
                children: [
                  _ScoresView(scores: scores),
                  _TimelineView(events: events),
                  _InfoView(matchInfo: matchInfo),
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
            style: const TextStyle(fontWeight: FontWeight.w900),
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

class _InfoView extends StatelessWidget {
  const _InfoView({required this.matchInfo});

  final GameAuditMatchInfo matchInfo;

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Session', matchInfo.sessionId ?? '-'),
      MapEntry('Phase', _prettyEnum(matchInfo.phase)),
      MapEntry('Resolver', matchInfo.resolver),
      MapEntry('Open Draft', '${matchInfo.openDraftTurnsRemaining}'),
      MapEntry('Jokers Left', '${matchInfo.jokersRemaining}'),
      MapEntry('End Triggered', matchInfo.endTriggered ? 'Yes' : 'No'),
      MapEntry('Finished', matchInfo.isFinished ? 'Yes' : 'No'),
      MapEntry('Status', matchInfo.status),
    ];

    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final row = rows[index];
        return _AuditListTile(
          title: Text(row.key),
          subtitle: Text(row.value, style: AppTextStyles.bodyMuted),
        );
      },
    );
  }
}

String _prettyEnum(String raw) {
  final s = raw.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (m) => '${m[1]} ${m[2]}',
  );
  if (s.isEmpty) return raw;
  return s[0].toUpperCase() + s.substring(1);
}
