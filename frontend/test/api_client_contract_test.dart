import 'dart:convert';

import 'package:encore_frontend/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient contract parsing', () {
    test('parses auth url payload', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/auth/github/url');
        return http.Response(jsonEncode({'url': 'https://github.com/login/oauth/authorize?client_id=x'}), 200);
      });

      final api = ApiClient(baseUrl: 'http://localhost:8080', httpClient: mock);
      final result = await api.getGitHubLoginUrl();
      expect(result['url'], contains('github.com/login/oauth/authorize'));
    });

    test('parses gameplay available-dice shape', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/gameplay/s1/available-dice/0');
        return http.Response(jsonEncode({'colorDice': ['Blue', 'Green'], 'numberDice': ['One', 'Joker']}), 200);
      });

      final api = ApiClient(baseUrl: 'http://localhost:8080', jwt: 't', httpClient: mock);
      final result = await api.getAvailableDice('s1', playerIndex: 0);

      expect(result.containsKey('colorDice'), true);
      expect(result.containsKey('numberDice'), true);
      expect((result['colorDice'] as List).length, 2);
    });

    test('throws on non-2xx response', () async {
      final mock = MockClient((request) async => http.Response('bad request', 400));
      final api = ApiClient(baseUrl: 'http://localhost:8080', httpClient: mock);

      expect(() => api.getGitHubLoginUrl(), throwsException);
    });
  });
}
