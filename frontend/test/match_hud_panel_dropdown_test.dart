import 'dart:convert';

import 'package:encore_frontend/services/api_client.dart';
import 'package:encore_frontend/state/game_controller.dart';
import 'package:encore_frontend/widgets/match_hud_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'MatchHudPanel supports chip-based die selection when roll contains duplicate faces',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final controller = _TestGameController(
        ApiClient(
          baseUrl: 'http://localhost:8080',
          jwt: _jwtWithSub('11111111-1111-1111-1111-111111111111'),
          httpClient: MockClient((request) async {
            expect(request.url.path, '/api/gameplay/session01');
            return http.Response(
              jsonEncode({
                'sessionId': 'session01',
                'phase': 'NeedActiveSelection',
                'activePlayerIndex': 0,
                'players': [
                  {
                    'accountId': '11111111-1111-1111-1111-111111111111',
                    'name': 'A',
                    'checkedCells': const [],
                    'jokerMarksRemaining': 8,
                  },
                ],
                'board': const [],
                'currentRoll': {
                  'colorDice': [1, 1, 2],
                  'numberDice': [4, 4, 2],
                },
              }),
              200,
            );
          }),
        ),
      );

      await controller.loadSession('session01');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MatchHudPanel(controller: controller)),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(find.text('Open Scores / Timeline'), findsNothing);
      expect(controller.availableColorDice, ['Orange', 'Blue']);
      expect(controller.availableNumberDice, ['Four', 'Two']);

      await tester.tap(find.byKey(const ValueKey('color-die-Blue')));
      await tester.pump();
      expect(controller.selectedColorDie, 'Blue');

      await tester.tap(find.byKey(const ValueKey('number-die-Two')));
      await tester.pump();
      expect(controller.selectedNumberDie, 'Two');
    },
  );
}

String _jwtWithSub(String sub) {
  final payload = base64Url.encode(utf8.encode(jsonEncode({'sub': sub})));
  return 'header.$payload.signature';
}

class _TestGameController extends GameController {
  _TestGameController(this._client) {
    jwt = _client.jwt;
  }

  final ApiClient _client;

  @override
  ApiClient get client => _client;
}
