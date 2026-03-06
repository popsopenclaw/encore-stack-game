import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/backend_config.dart';
import '../services/api_client.dart';
import '../services/lobby_realtime_service.dart';
import 'auth_session_controller.dart';

final lobbyController = LobbyController();

class LobbyController extends ChangeNotifier {
  final _realtime = LobbyRealtimeService();

  String? lobbyCode;
  String lobbyName = '';
  String? activeSessionId;
  bool hasActiveGame = false;
  int maxPlayers = 6;
  String status = 'Ready';
  RealtimeStatus realtimeStatus = RealtimeStatus.disconnected;
  List<Map<String, dynamic>> lobbies = const [];
  List<Map<String, dynamic>> members = const [];
  String? hostDisplayName;
  String? hostAccountId;
  final Map<String, bool> readyByAccountId = {};

  String _backendUrl = kBackendUrlFromBuild;
  String? _jwt;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _backendUrl = prefs.getString(kBackendPrefKey) ?? kBackendUrlFromBuild;
    _jwt = prefs.getString(kJwtPrefKey);

    if (_jwt != null && _jwt!.isNotEmpty) {
      await _realtime.connect(
        backendUrl: _backendUrl,
        jwt: _jwt,
        onLobbyUpdated: (lobby) {
          if (lobbyCode != null &&
              (lobby['code']?.toString().toUpperCase() == lobbyCode)) {
            _bindLobby(lobby);
          }
          final idx = lobbies.indexWhere(
            (l) =>
                (l['code']?.toString().toUpperCase()) ==
                (lobby['code']?.toString().toUpperCase()),
          );
          if (idx >= 0) {
            lobbies[idx] = lobby;
          } else {
            lobbies = [lobby, ...lobbies];
          }
          notifyListeners();
        },
        onStatusChanged: (s) {
          realtimeStatus = s;
          notifyListeners();
        },
        onReconnected: () async {
          if (lobbyCode != null) {
            await _realtime.joinLobbyGroup(lobbyCode!);
          }
        },
      );
    }

    if (_jwt != null && _jwt!.isNotEmpty) {
      await refreshLobbies();
    }
  }

  Future<void> refreshSessionConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _backendUrl = prefs.getString(kBackendPrefKey) ?? kBackendUrlFromBuild;
    _jwt = prefs.getString(kJwtPrefKey);
  }

  String get backendUrl => _backendUrl;
  String? get jwt => _jwt;
  String? get currentAccountId => _jwt == null ? null : _readSubFromJwt(_jwt!);
  bool get hasResumableCurrentGame =>
      hasActiveGame &&
      activeSessionId != null &&
      activeSessionId!.trim().isNotEmpty;
  bool _isHostForCurrentUser = false;
  bool get isCurrentUserHost => _isHostForCurrentUser;

  ApiClient get _api => ApiClient(baseUrl: _backendUrl, jwt: _jwt);

  Future<void> createLobby({required String name, required int max}) async {
    await _withStatus('Creating lobby', () async {
      await refreshSessionConfig();
      final lobby = await _api.createLobby(
        name: name,
        maxPlayers: max.clamp(1, 6),
      );
      _bindLobby(lobby);
      if (lobbyCode != null) await _realtime.joinLobbyGroup(lobbyCode!);
      await refreshLobbies();
    });
  }

  Future<void> joinLobby({required String code}) async {
    await _withStatus('Joining lobby', () async {
      await refreshSessionConfig();
      final lobby = await _api.joinLobby(code: code.trim().toUpperCase());
      _bindLobby(lobby);
      if (lobbyCode != null) await _realtime.joinLobbyGroup(lobbyCode!);
      await refreshLobbies();
    });
  }

  Future<void> leaveCurrentLobby() async {
    if (lobbyCode == null) return;
    await _withStatus('Leaving lobby', () async {
      await refreshSessionConfig();
      final current = lobbyCode!;
      await _api.leaveLobby(current);
      await _realtime.leaveLobbyGroup(current);
      lobbyCode = null;
      lobbyName = '';
      activeSessionId = null;
      hasActiveGame = false;
      members = const [];
      await refreshLobbies();
    });
  }

  Future<void> refreshLobbies() async {
    await _withStatus('Loading lobbies', () async {
      await refreshSessionConfig();
      final data = await _api.listLobbies(limit: 20);
      lobbies = data.cast<Map<String, dynamic>>();
    });
  }

  Future<void> refreshCurrentLobby() async {
    if (lobbyCode == null) return;
    await _withStatus('Refreshing lobby', () async {
      await refreshSessionConfig();
      final lobby = await _api.getLobby(lobbyCode!);
      _bindLobby(lobby);
    });
  }

  Future<String?> resolveCurrentLobbySession() async {
    if (lobbyCode == null) return null;
    if (hasResumableCurrentGame) return activeSessionId;
    await refreshCurrentLobby();
    return hasResumableCurrentGame ? activeSessionId : null;
  }

  void markCurrentLobbyStarted(String sessionId) {
    final trimmed = sessionId.trim();
    if (trimmed.isEmpty) return;
    activeSessionId = trimmed;
    hasActiveGame = true;
    _syncLobbyListEntry(
      (lobby) => {...lobby, 'activeSessionId': trimmed, 'hasActiveGame': true},
    );
    notifyListeners();
  }

  void _bindLobby(Map<String, dynamic> lobby) {
    lobbyCode = (lobby['code'] as String?)?.toUpperCase();
    lobbyName = (lobby['name'] as String?) ?? '';
    activeSessionId = lobby['activeSessionId']?.toString();
    hasActiveGame =
        (lobby['hasActiveGame'] as bool?) ??
        (activeSessionId != null && activeSessionId!.trim().isNotEmpty);
    maxPlayers = (lobby['maxPlayers'] as int?) ?? 6;
    hostDisplayName = lobby['hostDisplayName']?.toString();
    hostAccountId = lobby['hostAccountId']?.toString();
    final explicitHost = lobby['isHostForCurrentUser'];
    if (explicitHost is bool) {
      _isHostForCurrentUser = explicitHost;
    } else {
      final me = currentAccountId?.toLowerCase();
      final host = hostAccountId?.toLowerCase();
      _isHostForCurrentUser = me != null && host != null && me == host;
    }

    final rawMembers = (lobby['members'] as List<dynamic>?) ?? const [];
    members =
        rawMembers.map((e) => (e as Map).map((k, v) => MapEntry('$k', v))).map((
          m,
        ) {
          final accountId = m['accountId']?.toString() ?? '';
          final isHost = accountId.isNotEmpty && accountId == hostAccountId;
          readyByAccountId.putIfAbsent(accountId, () => false);
          return {
            ...m,
            'isHost': isHost,
            'isReady': readyByAccountId[accountId] ?? false,
          };
        }).toList();

    _syncLobbyListEntry((_) => lobby);
  }

  void _syncLobbyListEntry(
    Map<String, dynamic> Function(Map<String, dynamic>) update,
  ) {
    final code = lobbyCode;
    if (code == null) return;
    final idx = lobbies.indexWhere(
      (l) => (l['code']?.toString().toUpperCase()) == code,
    );
    if (idx < 0) return;
    final next = [...lobbies];
    next[idx] = update({...next[idx]});
    lobbies = next;
  }

  Future<void> _withStatus(String label, Future<void> Function() op) async {
    status = '$label...';
    notifyListeners();
    try {
      await op();
      status = '$label done';
    } on UnauthorizedApiException {
      await authSessionController.logout();
      await _realtime.disconnect();
      realtimeStatus = RealtimeStatus.disconnected;
      status = 'Session expired. Please login again.';
    } on ApiErrorException catch (e) {
      status = '$label failed: ${_messageForApiError(e)}';
    } catch (e) {
      status = '$label failed: $e';
    }
    notifyListeners();
  }

  Future<void> resetForLogout() async {
    await _realtime.disconnect();
    realtimeStatus = RealtimeStatus.disconnected;
    lobbyCode = null;
    lobbyName = '';
    activeSessionId = null;
    hasActiveGame = false;
    hostDisplayName = null;
    hostAccountId = null;
    _isHostForCurrentUser = false;
    readyByAccountId.clear();
    members = const [];
    lobbies = const [];
    status = 'Logged out';
    notifyListeners();
  }

  void toggleMyReady() {
    final id = currentAccountId;
    if (id == null || id.isEmpty) return;
    readyByAccountId[id] = !(readyByAccountId[id] ?? false);
    members =
        members
            .map(
              (m) => {
                ...m,
                if ((m['accountId']?.toString() ?? '') == id)
                  'isReady': readyByAccountId[id],
              },
            )
            .toList();
    notifyListeners();
  }

  String _messageForApiError(ApiErrorException e) {
    switch (e.code) {
      case ApiErrorCode.forbidden:
        return 'You do not have permission for this action.';
      case ApiErrorCode.notFound:
        return 'Lobby not found.';
      case ApiErrorCode.redisUnavailable:
        return 'Realtime services are temporarily unavailable. Try again.';
      default:
        return e.message;
    }
  }

  String? _readSubFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return map['sub']?.toString();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _realtime.disconnect();
    super.dispose();
  }
}
