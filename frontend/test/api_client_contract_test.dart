import 'dart:convert';

import 'package:encore_frontend/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient contract parsing', () {
    test('parses auth providers payload', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/auth/providers');
        return http.Response(
          jsonEncode({
            'providers': [
              {'id': 'github', 'label': 'GitHub', 'kind': 'oauth'},
              {'id': 'local', 'label': 'Email', 'kind': 'credentials'},
            ],
          }),
          200,
        );
      });

      final api = ApiClient(baseUrl: 'http://localhost:8080', httpClient: mock);
      final result = await api.getAuthProviders();
      expect((result['providers'] as List).length, 2);
    });

    test('parses oauth exchange player name field', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/auth/oauth/github/exchange');
        return http.Response(
          jsonEncode({
            'accessToken': 'jwt',
            'username': 'tester',
            'email': 'tester@example.com',
            'avatarUrl': 'https://example.com/a.png',
            'playerName': 'ember-falcon-42',
          }),
          200,
        );
      });

      final api = ApiClient(baseUrl: 'http://localhost:8080', httpClient: mock);
      final result = await api.exchangeOAuthCode('github', 'code');

      expect(result['playerName'], 'ember-falcon-42');
    });

    test('posts local auth payload', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/auth/local/login');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'tester@example.com');
        expect(body['password'], 'secret123');
        return http.Response(
          jsonEncode({
            'accessToken': 'jwt',
            'username': 'tester',
            'email': 'tester@example.com',
            'avatarUrl': '',
            'playerName': 'ember-falcon-42',
          }),
          200,
        );
      });

      final api = ApiClient(baseUrl: 'http://localhost:8080', httpClient: mock);
      final result = await api.loginLocal(
        email: 'tester@example.com',
        password: 'secret123',
      );

      expect(result['email'], 'tester@example.com');
    });

    test('sends create lobby request without display name fields', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/lobby');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['maxPlayers'], 4);
        expect(body.containsKey('name'), isFalse);
        expect(body.containsKey('hostDisplayName'), isFalse);
        return http.Response(jsonEncode({'code': 'ABC123'}), 200);
      });

      final api = ApiClient(
        baseUrl: 'http://localhost:8080',
        jwt: 't',
        httpClient: mock,
      );
      await api.createLobby(maxPlayers: 4);
    });

    test('sends join lobby request without display name fields', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/lobby/join');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['code'], 'ABC123');
        expect(body.containsKey('displayName'), isFalse);
        return http.Response(jsonEncode({'code': 'ABC123'}), 200);
      });

      final api = ApiClient(
        baseUrl: 'http://localhost:8080',
        jwt: 't',
        httpClient: mock,
      );
      await api.joinLobby(code: 'ABC123');
    });

    test('parses profile payload and sends profile update', () async {
      final mock = MockClient((request) async {
        if (request.method == 'GET') {
          expect(request.url.path, '/api/profile');
          return http.Response(
            jsonEncode({
              'id': '11111111-1111-1111-1111-111111111111',
              'playerName': 'ember-falcon-42',
              'username': 'tester',
              'email': 'tester@example.com',
              'avatarUrl': 'https://example.com/a.png',
            }),
            200,
          );
        }

        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/profile');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['playerName'], 'tidal-rook-8');
        return http.Response(
          jsonEncode({
            'id': '11111111-1111-1111-1111-111111111111',
            'playerName': 'tidal-rook-8',
            'username': 'tester',
            'email': 'tester@example.com',
            'avatarUrl': 'https://example.com/a.png',
          }),
          200,
        );
      });

      final api = ApiClient(
        baseUrl: 'http://localhost:8080',
        jwt: 't',
        httpClient: mock,
      );
      final profile = await api.getProfile();
      expect(profile['playerName'], 'ember-falcon-42');

      final updated = await api.updateProfile(playerName: 'tidal-rook-8');
      expect(updated['playerName'], 'tidal-rook-8');
    });

    test('parses gameplay available-dice shape', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/gameplay/s1/available-dice/0');
        return http.Response(
          jsonEncode({
            'colorDice': ['Blue', 'Green'],
            'numberDice': ['One', 'Joker'],
          }),
          200,
        );
      });

      final api = ApiClient(
        baseUrl: 'http://localhost:8080',
        jwt: 't',
        httpClient: mock,
      );
      final result = await api.getAvailableDice('s1', playerIndex: 0);

      expect(result.containsKey('colorDice'), true);
      expect(result.containsKey('numberDice'), true);
      expect((result['colorDice'] as List).length, 2);
    });

    test(
      'throws typed ApiErrorException on structured error response',
      () async {
        final mock = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'code': 'forbidden',
              'message': 'Only host can start a match',
              'correlationId': 'cid-1',
            }),
            403,
          );
        });
        final api = ApiClient(
          baseUrl: 'http://localhost:8080',
          httpClient: mock,
        );

        expect(
          () => api.getAuthProviders(),
          throwsA(
            isA<ApiErrorException>()
                .having((e) => e.statusCode, 'statusCode', 403)
                .having((e) => e.code, 'code', ApiErrorCode.forbidden)
                .having((e) => e.message, 'message', contains('Only host'))
                .having((e) => e.correlationId, 'correlationId', 'cid-1'),
          ),
        );
      },
    );
  });
}
