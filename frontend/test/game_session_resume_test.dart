import 'dart:convert';

import 'package:encore_frontend/config/backend_config.dart';
import 'package:encore_frontend/services/api_client.dart';
import 'package:encore_frontend/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GameController session resume', () {
    test('restoreLastSessionIfAny returns false when nothing saved', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = _TestGameController(
        ApiClient(
          baseUrl: 'http://localhost:8080',
          httpClient: MockClient((_) async => http.Response('{}', 500)),
        ),
      );

      final restored = await controller.restoreLastSessionIfAny();

      expect(restored, false);
      expect(controller.sessionId, isNull);
      expect(controller.attemptedAutoResume, true);
      expect(controller.lastLoadErrorCode, isNull);
    });

    test('restoreLastSessionIfAny restores saved session', () async {
      SharedPreferences.setMockInitialValues({kActiveGameSessionPrefKey: 's1'});
      final controller = _TestGameController(
        ApiClient(
          baseUrl: 'http://localhost:8080',
          jwt: 't',
          httpClient: MockClient((request) async {
            expect(request.url.path, '/api/gameplay/s1');
            return http.Response(
              jsonEncode({
                'sessionId': 's1',
                'phase': 'NeedRoll',
                'activePlayerIndex': 0,
                'players': const [],
                'board': const [],
              }),
              200,
            );
          }),
        ),
      );

      final restored = await controller.restoreLastSessionIfAny();
      final prefs = await SharedPreferences.getInstance();

      expect(restored, true);
      expect(controller.sessionId, 's1');
      expect((controller.state?['sessionId'] ?? '').toString(), 's1');
      expect(prefs.getString(kActiveGameSessionPrefKey), 's1');
      expect(controller.lastLoadErrorCode, isNull);
    });

    test('restoreLastSessionIfAny clears invalid saved session', () async {
      SharedPreferences.setMockInitialValues({
        kActiveGameSessionPrefKey: 'gone',
      });
      final controller = _TestGameController(
        ApiClient(
          baseUrl: 'http://localhost:8080',
          jwt: 't',
          httpClient: MockClient((request) async {
            expect(request.url.path, '/api/gameplay/gone');
            return http.Response(
              jsonEncode({'code': 'not_found', 'message': 'Game not found'}),
              404,
            );
          }),
        ),
      );

      final restored = await controller.restoreLastSessionIfAny();
      final prefs = await SharedPreferences.getInstance();

      expect(restored, false);
      expect(controller.sessionId, isNull);
      expect(controller.state, isNull);
      expect(controller.lastLoadErrorCode, ApiErrorCode.notFound);
      expect(prefs.getString(kActiveGameSessionPrefKey), isNull);
    });

    test(
      'loadSession normalizes duplicate dice in active selection state',
      () async {
        SharedPreferences.setMockInitialValues({});
        final controller = _TestGameController(
          ApiClient(
            baseUrl: 'http://localhost:8080',
            jwt: 't',
            httpClient: MockClient((request) async {
              expect(request.url.path, '/api/gameplay/session01');
              return http.Response(
                jsonEncode({
                  'sessionId': 'session01',
                  'phase': 'NeedActiveSelection',
                  'activePlayerIndex': 0,
                  'players': [
                    {
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

        expect(controller.availableColorDice, ['Orange', 'Blue']);
        expect(controller.availableNumberDice, ['Four', 'Two']);
        expect(controller.selectedColorDie, 'Orange');
        expect(controller.selectedNumberDie, 'Four');
      },
    );

    test(
      'submitActiveSelection sends canonical enum names from numeric roll values',
      () async {
        SharedPreferences.setMockInitialValues({});
        Map<String, dynamic>? capturedRequest;

        final controller = _TestGameController(
          ApiClient(
            baseUrl: 'http://localhost:8080',
            jwt: 't',
            httpClient: MockClient((request) async {
              if (request.method == 'GET' &&
                  request.url.path == '/api/gameplay/session01') {
                return http.Response(
                  jsonEncode({
                    'sessionId': 'session01',
                    'phase': 'NeedActiveSelection',
                    'activePlayerIndex': 0,
                    'players': [
                      {
                        'name': 'A',
                        'checkedCells': const [],
                        'jokerMarksRemaining': 8,
                      },
                    ],
                    'board': const [],
                    'currentRoll': {
                      'colorDice': [1, 2, 3],
                      'numberDice': [4, 2, 0],
                    },
                  }),
                  200,
                );
              }

              if (request.method == 'POST' &&
                  request.url.path == '/api/gameplay/session01/active-select') {
                capturedRequest =
                    jsonDecode(request.body) as Map<String, dynamic>;
                return http.Response(
                  jsonEncode({
                    'sessionId': 'session01',
                    'phase': 'PlayersResolving',
                    'activePlayerIndex': 0,
                    'players': const [],
                    'board': const [],
                  }),
                  200,
                );
              }

              throw StateError(
                'Unexpected request: ${request.method} ${request.url.path}',
              );
            }),
          ),
        );

        await controller.loadSession('session01');
        await controller.submitActiveSelection();

        expect(capturedRequest, isNotNull);
        expect(capturedRequest!['colorDie'], 'Orange');
        expect(capturedRequest!['numberDie'], 'Four');
        expect(capturedRequest!['pass'], false);
      },
    );
  });
}

class _TestGameController extends GameController {
  _TestGameController(this._client);

  final ApiClient _client;

  @override
  ApiClient get client => _client;
}
