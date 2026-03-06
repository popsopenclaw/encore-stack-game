import 'package:encore_frontend/widgets/game_audit_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GameAuditPanel exposes Scores, Timeline, and Info tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 500,
            child: GameAuditPanel(
              scores: [],
              events: [],
              matchInfo: GameAuditMatchInfo(
                sessionId: 'session01',
                phase: 'NeedActiveSelection',
                resolver: 'P1',
                openDraftTurnsRemaining: 18,
                jokersRemaining: 8,
                endTriggered: false,
                isFinished: false,
                status: 'Ready',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Scores'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Info'), findsOneWidget);

    await tester.tap(find.text('Info'));
    await tester.pumpAndSettle();

    expect(find.text('Session'), findsOneWidget);
    expect(find.text('session01'), findsOneWidget);
    expect(find.text('Phase'), findsOneWidget);
    expect(find.text('Need Active Selection'), findsOneWidget);
    expect(find.text('Resolver'), findsOneWidget);
    expect(find.text('P1'), findsOneWidget);
  });
}
