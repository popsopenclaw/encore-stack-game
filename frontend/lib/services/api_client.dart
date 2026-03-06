import 'dart:convert';

import 'package:http/http.dart' as http;

class UnauthorizedApiException implements Exception {
  @override
  String toString() => 'UnauthorizedApiException';
}

enum ApiErrorCode {
  invalidRequest,
  invalidOperation,
  notFound,
  forbidden,
  redisUnavailable,
  internalError,
  unknown,
}

class ApiErrorException implements Exception {
  ApiErrorException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.correlationId,
  });

  final int statusCode;
  final ApiErrorCode code;
  final String message;
  final String? correlationId;

  bool get isRetryable =>
      code == ApiErrorCode.redisUnavailable || statusCode >= 500;

  @override
  String toString() =>
      'ApiErrorException($statusCode, $code, $message, cid=$correlationId)';
}

class ApiClient {
  ApiClient({required this.baseUrl, this.jwt, http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final String baseUrl;
  final String? jwt;
  final http.Client _http;

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    if (jwt != null && jwt!.isNotEmpty) 'Authorization': 'Bearer $jwt',
  };

  Future<Map<String, dynamic>> getAuthProviders() async {
    final r = await _http.get(_u('/api/auth/providers'));
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> getOAuthLoginUrl(String provider) async {
    final r = await _http.get(
      _u('/api/auth/oauth/$provider/url?state=encore-app'),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> exchangeOAuthCode(
    String provider,
    String code,
  ) async {
    final r = await _http.post(
      _u('/api/auth/oauth/$provider/exchange'),
      headers: _jsonHeaders,
      body: jsonEncode({'code': code}),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> loginLocal({
    required String email,
    required String password,
  }) async {
    final r = await _http.post(
      _u('/api/auth/local/login'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> registerLocal({
    required String email,
    required String password,
  }) async {
    final r = await _http.post(
      _u('/api/auth/local/register'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final r = await _http.get(_u('/api/profile'), headers: _jsonHeaders);
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String playerName,
  }) async {
    final r = await _http.patch(
      _u('/api/profile'),
      headers: _jsonHeaders,
      body: jsonEncode({'playerName': playerName}),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> getGame(String sessionId) async {
    final r = await _http.get(
      _u('/api/gameplay/$sessionId'),
      headers: _jsonHeaders,
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> roll(String sessionId) async {
    final r = await _http.post(
      _u('/api/gameplay/$sessionId/roll'),
      headers: _jsonHeaders,
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> activeSelect(
    String sessionId, {
    required int playerIndex,
    String? colorDie,
    String? numberDie,
    bool pass = false,
  }) async {
    final r = await _http.post(
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

  Future<Map<String, dynamic>> getAvailableDice(
    String sessionId, {
    required int playerIndex,
  }) async {
    final r = await _http.get(
      _u('/api/gameplay/$sessionId/available-dice/$playerIndex'),
      headers: _jsonHeaders,
    );
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
    final r = await _http.post(
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
    final r = await _http.get(
      _u('/api/gameplay/$sessionId/score'),
      headers: _jsonHeaders,
    );
    return _decodeList(r);
  }

  Future<List<dynamic>> getEvents(String sessionId) async {
    final r = await _http.get(
      _u('/api/gameplay/$sessionId/events'),
      headers: _jsonHeaders,
    );
    return _decodeList(r);
  }

  Future<Map<String, dynamic>> createLobby({required int maxPlayers}) async {
    final r = await _http.post(
      _u('/api/lobby'),
      headers: _jsonHeaders,
      body: jsonEncode({'maxPlayers': maxPlayers}),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> joinLobby({required String code}) async {
    final r = await _http.post(
      _u('/api/lobby/join'),
      headers: _jsonHeaders,
      body: jsonEncode({'code': code}),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> getLobby(String code) async {
    final r = await _http.get(_u('/api/lobby/$code'), headers: _jsonHeaders);
    return _decodeMap(r);
  }

  Future<List<dynamic>> listLobbies({int limit = 20}) async {
    final r = await _http.get(
      _u('/api/lobby?limit=$limit'),
      headers: _jsonHeaders,
    );
    return _decodeList(r);
  }

  Future<Map<String, dynamic>> startLobbyMatch(
    String code, {
    String name = 'Game',
  }) async {
    final r = await _http.post(
      _u('/api/lobby/$code/start'),
      headers: _jsonHeaders,
      body: jsonEncode({'name': name}),
    );
    return _decodeMap(r);
  }

  Future<void> leaveLobby(String code) async {
    final r = await _http.post(
      _u('/api/lobby/$code/leave'),
      headers: _jsonHeaders,
    );
    _throwIfError(r);
  }

  Map<String, dynamic> _decodeMap(http.Response r) {
    _throwIfError(r);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  List<dynamic> _decodeList(http.Response r) {
    _throwIfError(r);
    return jsonDecode(r.body) as List<dynamic>;
  }

  void _throwIfError(http.Response r) {
    if (r.statusCode == 401) throw UnauthorizedApiException();
    if (r.statusCode < 400) return;

    final body = r.body;
    String message = body.isNotEmpty ? body : 'HTTP ${r.statusCode}';
    ApiErrorCode code = ApiErrorCode.unknown;
    String? correlationId;

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final rawCode = decoded['code']?.toString();
        final rawMessage = decoded['message']?.toString();
        correlationId = decoded['correlationId']?.toString();
        if (rawCode != null) code = _mapCode(rawCode);
        if (rawMessage != null && rawMessage.isNotEmpty) message = rawMessage;
      }
    } catch (_) {
      // fallback to raw body message
    }

    throw ApiErrorException(
      statusCode: r.statusCode,
      code: code,
      message: message,
      correlationId: correlationId,
    );
  }

  ApiErrorCode _mapCode(String code) {
    return switch (code) {
      'invalid_request' => ApiErrorCode.invalidRequest,
      'invalid_operation' => ApiErrorCode.invalidOperation,
      'not_found' => ApiErrorCode.notFound,
      'forbidden' => ApiErrorCode.forbidden,
      'redis_unavailable' => ApiErrorCode.redisUnavailable,
      'internal_error' => ApiErrorCode.internalError,
      _ => ApiErrorCode.unknown,
    };
  }
}
