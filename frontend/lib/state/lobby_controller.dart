import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/backend_config.dart';
import '../services/api_client.dart';
import '../services/lobby_realtime_service.dart';

final lobbyController = LobbyController();

class LobbyController extends ChangeNotifier {
  final _realtime = LobbyRealtimeService();

  String? lobbyCode;
  String lobbyName = '';
  int maxPlayers = 6;
  String displayName = 'Player';
  String status = 'Ready';
  List<Map<String, dynamic>> lobbies = const [];

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
          if (lobbyCode != null && (lobby['code']?.toString().toUpperCase() == lobbyCode)) {
            _bindLobby(lobby);
          }
          final idx = lobbies.indexWhere((l) => (l['code']?.toString().toUpperCase()) == (lobby['code']?.toString().toUpperCase()));
          if (idx >= 0) {
            lobbies[idx] = lobby;
          } else {
            lobbies = [lobby, ...lobbies];
          }
          notifyListeners();
        },
      );
    }

    await refreshLobbies();
  }

  Future<void> refreshSessionConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _backendUrl = prefs.getString(kBackendPrefKey) ?? kBackendUrlFromBuild;
    _jwt = prefs.getString(kJwtPrefKey);
  }

  ApiClient get _api => ApiClient(baseUrl: _backendUrl, jwt: _jwt);

  Future<void> createLobby({required String name, required int max, required String hostDisplayName}) async {
    await _withStatus('Creating lobby', () async {
      await refreshSessionConfig();
      final lobby = await _api.createLobby(name: name, maxPlayers: max.clamp(1, 6), hostDisplayName: hostDisplayName);
      _bindLobby(lobby);
      if (lobbyCode != null) await _realtime.joinLobbyGroup(lobbyCode!);
      await refreshLobbies();
    });
  }

  Future<void> joinLobby({required String code, required String name}) async {
    await _withStatus('Joining lobby', () async {
      await refreshSessionConfig();
      final lobby = await _api.joinLobby(code: code.trim().toUpperCase(), displayName: name.trim());
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

  void _bindLobby(Map<String, dynamic> lobby) {
    lobbyCode = (lobby['code'] as String?)?.toUpperCase();
    lobbyName = (lobby['name'] as String?) ?? '';
    maxPlayers = (lobby['maxPlayers'] as int?) ?? 6;
  }

  Future<void> _withStatus(String label, Future<void> Function() op) async {
    status = '$label...';
    notifyListeners();
    try {
      await op();
      status = '$label done';
    } catch (e) {
      status = '$label failed: $e';
    }
    notifyListeners();
  }

  Future<void> resetForLogout() async {
    await _realtime.disconnect();
    lobbyCode = null;
    lobbyName = '';
    lobbies = const [];
    status = 'Logged out';
    notifyListeners();
  }

  @override
  void dispose() {
    _realtime.disconnect();
    super.dispose();
  }
}
