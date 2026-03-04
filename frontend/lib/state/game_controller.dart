import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/backend_config.dart';
import '../services/api_client.dart';

class GameController extends ChangeNotifier {
  final backendUrl = TextEditingController(text: kBackendUrlFromBuild);
  final oauthCode = TextEditingController();
  final players = TextEditingController(text: 'pop,bot2');

  String? jwt;
  String? sessionId;
  String status = 'Ready';
  Map<String, dynamic>? state;
  List<dynamic> scores = const [];
  List<dynamic> events = const [];

  String get apiBase => backendUrl.text.trim();
  ApiClient get client => ApiClient(baseUrl: apiBase, jwt: jwt);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(kBackendPrefKey);
    if (saved != null && saved.isNotEmpty) backendUrl.text = saved;
    final savedJwt = prefs.getString(kJwtPrefKey);
    if (savedJwt != null && savedJwt.isNotEmpty) jwt = savedJwt;
    notifyListeners();
  }

  Future<void> disposeController() async {
    backendUrl.dispose();
    oauthCode.dispose();
    players.dispose();
  }

  Future<void> saveBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kBackendPrefKey, apiBase);
    _setStatus('Backend URL saved: $apiBase');
  }

  Future<void> setLocalBackend() async {
    backendUrl.text = 'http://localhost:8080';
    await saveBackendUrl();
  }

  Future<void> setProductionBackend() async {
    backendUrl.text = kBackendUrlFromBuild;
    await saveBackendUrl();
  }

  Future<void> githubLoginUrl(Future<void> Function(String url) openUrl) async {
    await _run('OAuth URL', () async {
      final body = await client.getGitHubLoginUrl();
      await openUrl(body['url'] as String);
    });
  }

  Future<void> exchange() async => _run('OAuth exchange', () async {
        final body = await client.exchangeGitHubCode(oauthCode.text.trim());
        jwt = body['accessToken'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(kJwtPrefKey, jwt!);
      });

  Future<void> startGame() async => _run('Start game', () async {
        final names = players.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        final game = await client.startGame(names);
        state = game;
        sessionId = game['sessionId'] as String;
      });

  Future<void> reloadState() async {
    if (sessionId == null) return;
    await _run('Reload state', () async {
      state = await client.getGame(sessionId!);
    });
  }

  Future<void> roll() async {
    if (sessionId == null) return;
    await _run('Roll', () async {
      await client.roll(sessionId!);
      state = await client.getGame(sessionId!);
    });
  }

  Future<void> activePass() async {
    if (sessionId == null) return;
    await _run('Active pass', () async {
      final idx = (state?['activePlayerIndex'] as int?) ?? 0;
      await client.activeSelect(sessionId!, playerIndex: idx, pass: true);
      state = await client.getGame(sessionId!);
    });
  }

  Future<void> allPassOnce() async {
    if (sessionId == null || state == null) return;
    await _run('Resolve pass round', () async {
      final count = (state!['players'] as List<dynamic>).length;
      for (var i = 0; i < count; i++) {
        await client.playerAction(sessionId!, playerIndex: i, pass: true);
      }
      state = await client.getGame(sessionId!);
    });
  }

  Future<void> loadScoreAndEvents() async {
    if (sessionId == null) return;
    await _run('Load score/events', () async {
      scores = await client.getScore(sessionId!);
      events = await client.getEvents(sessionId!);
    });
  }

  Future<void> _run(String action, Future<void> Function() fn) async {
    _setStatus('$action...');
    try {
      await fn();
      _setStatus('$action done');
    } catch (e) {
      _setStatus('$action failed: $e');
    }
  }

  void _setStatus(String value) {
    status = value;
    notifyListeners();
  }
}
