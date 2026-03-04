import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({required this.baseUrl, this.jwt});

  final String baseUrl;
  final String? jwt;

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        if (jwt != null && jwt!.isNotEmpty) 'Authorization': 'Bearer $jwt',
      };

  Future<Map<String, dynamic>> getGitHubLoginUrl() async {
    final r = await http.get(_u('/api/auth/github/url?state=encore-app'));
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> exchangeGitHubCode(String code) async {
    final r = await http.post(
      _u('/api/auth/github/exchange'),
      headers: _jsonHeaders,
      body: jsonEncode({'code': code}),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> startGame(List<String> playerNames) async {
    final r = await http.post(
      _u('/api/gameplay/start'),
      headers: _jsonHeaders,
      body: jsonEncode({'playerNames': playerNames}),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> getGame(String sessionId) async {
    final r = await http.get(_u('/api/gameplay/$sessionId'), headers: _jsonHeaders);
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> roll(String sessionId) async {
    final r = await http.post(_u('/api/gameplay/$sessionId/roll'), headers: _jsonHeaders);
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> activeSelect(
    String sessionId, {
    required int playerIndex,
    String? colorDie,
    String? numberDie,
    bool pass = false,
  }) async {
    final r = await http.post(
      _u('/api/gameplay/$sessionId/active-select'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'playerIndex': playerIndex,
        'colorDie': colorDie,
        'numberDie': numberDie,
        'pass': pass,
      }),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> getAvailableDice(String sessionId, {required int playerIndex}) async {
    final r = await http.get(_u('/api/gameplay/$sessionId/available-dice/$playerIndex'), headers: _jsonHeaders);
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> playerAction(
    String sessionId, {
    required int playerIndex,
    String? colorDie,
    String? numberDie,
    List<String>? cellIds,
    bool pass = false,
  }) async {
    final r = await http.post(
      _u('/api/gameplay/$sessionId/action'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'playerIndex': playerIndex,
        'colorDie': colorDie,
        'numberDie': numberDie,
        'cellIds': cellIds,
        'pass': pass,
      }),
    );
    return _decodeMap(r);
  }

  Future<List<dynamic>> getScore(String sessionId) async {
    final r = await http.get(_u('/api/gameplay/$sessionId/score'), headers: _jsonHeaders);
    return _decodeList(r);
  }

  Future<List<dynamic>> getEvents(String sessionId) async {
    final r = await http.get(_u('/api/gameplay/$sessionId/events'), headers: _jsonHeaders);
    return _decodeList(r);
  }

  Future<Map<String, dynamic>> createLobby({
    required String name,
    required int maxPlayers,
    required String hostDisplayName,
  }) async {
    final r = await http.post(
      _u('/api/lobby'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'name': name,
        'maxPlayers': maxPlayers,
        'hostDisplayName': hostDisplayName,
      }),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> joinLobby({
    required String code,
    required String displayName,
  }) async {
    final r = await http.post(
      _u('/api/lobby/join'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'code': code,
        'displayName': displayName,
      }),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> getLobby(String code) async {
    final r = await http.get(_u('/api/lobby/$code'), headers: _jsonHeaders);
    return _decodeMap(r);
  }

  Future<List<dynamic>> listLobbies({int limit = 20}) async {
    final r = await http.get(_u('/api/lobby?limit=$limit'), headers: _jsonHeaders);
    return _decodeList(r);
  }

  Future<void> leaveLobby(String code) async {
    final r = await http.post(_u('/api/lobby/$code/leave'), headers: _jsonHeaders);
    if (r.statusCode >= 400) {
      throw Exception('HTTP ${r.statusCode}: ${r.body}');
    }
  }

  Map<String, dynamic> _decodeMap(http.Response r) {
    if (r.statusCode >= 400) {
      throw Exception('HTTP ${r.statusCode}: ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  List<dynamic> _decodeList(http.Response r) {
    if (r.statusCode >= 400) {
      throw Exception('HTTP ${r.statusCode}: ${r.body}');
    }
    return jsonDecode(r.body) as List<dynamic>;
  }
}
