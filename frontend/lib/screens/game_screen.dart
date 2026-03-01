import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/backend_config.dart';
import '../services/api_client.dart';
import '../theme/app_palette.dart';
import '../widgets/backend_url_section.dart';
import '../widgets/board_sheet.dart';
import '../widgets/common_card.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _backendUrl = TextEditingController(text: kBackendUrlFromBuild);
  final _oauthCode = TextEditingController();
  final _players = TextEditingController(text: 'pop,bot2');

  String? _jwt;
  String? _sessionId;
  String _status = 'Ready';
  Map<String, dynamic>? _state;
  List<dynamic> _scores = const [];
  List<dynamic> _events = const [];

  String get _apiBase => _backendUrl.text.trim();
  ApiClient get _client => ApiClient(baseUrl: _apiBase, jwt: _jwt);

  @override
  void initState() {
    super.initState();
    _loadBackendUrl();
  }

  @override
  void dispose() {
    _backendUrl.dispose();
    _oauthCode.dispose();
    _players.dispose();
    super.dispose();
  }

  Future<void> _loadBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(kBackendPrefKey);
    if (saved != null && saved.isNotEmpty) _backendUrl.text = saved;
  }

  Future<void> _saveBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kBackendPrefKey, _apiBase);
    _setStatus('Backend URL saved: $_apiBase');
  }

  void _setStatus(String text) {
    if (!mounted) return;
    setState(() => _status = text);
  }

  Future<void> _run(String action, Future<void> Function() fn) async {
    try {
      _setStatus('$action...');
      await fn();
      _setStatus('$action done');
    } catch (e) {
      _setStatus('$action failed: $e');
    }
  }

  void _setLocalBackend() {
    _backendUrl.text = 'http://localhost:8080';
    _saveBackendUrl();
  }

  void _setProductionBackend() {
    _backendUrl.text = kBackendUrlFromBuild;
    _saveBackendUrl();
  }

  Future<void> _githubLoginUrl() async => _run('OAuth URL', () async {
        final body = await _client.getGitHubLoginUrl();
        await launchUrl(Uri.parse(body['url'] as String), mode: LaunchMode.externalApplication);
      });

  Future<void> _exchange() async => _run('OAuth exchange', () async {
        final body = await _client.exchangeGitHubCode(_oauthCode.text.trim());
        setState(() => _jwt = body['accessToken'] as String);
      });

  Future<void> _startGame() async => _run('Start game', () async {
        final names = _players.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        final state = await _client.startGame(names);
        setState(() {
          _state = state;
          _sessionId = state['sessionId'] as String;
        });
      });

  Future<void> _reloadState() async {
    if (_sessionId == null) return;
    await _run('Reload state', () async {
      final state = await _client.getGame(_sessionId!);
      setState(() => _state = state);
    });
  }

  Future<void> _roll() async {
    if (_sessionId == null) return;
    await _run('Roll', () async {
      await _client.roll(_sessionId!);
      await _reloadState();
    });
  }

  Future<void> _activePass() async {
    if (_sessionId == null) return;
    await _run('Active pass', () async {
      final idx = (_state?['activePlayerIndex'] as int?) ?? 0;
      await _client.activeSelect(_sessionId!, playerIndex: idx, pass: true);
      await _reloadState();
    });
  }

  Future<void> _allPassOnce() async {
    if (_sessionId == null || _state == null) return;
    await _run('Resolve pass round', () async {
      final players = (_state!['players'] as List<dynamic>).length;
      for (var i = 0; i < players; i++) {
        await _client.playerAction(_sessionId!, playerIndex: i, pass: true);
      }
      await _reloadState();
    });
  }

  Future<void> _loadScoreAndEvents() async {
    if (_sessionId == null) return;
    await _run('Load score/events', () async {
      final score = await _client.getScore(_sessionId!);
      final events = await _client.getEvents(_sessionId!);
      setState(() {
        _scores = score;
        _events = events;
      });
    });
  }

  Color _cellColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'yellow':
        return AppPalette.tileYellow;
      case 'orange':
        return AppPalette.tileOrange;
      case 'blue':
        return AppPalette.tileBlue;
      case 'green':
        return AppPalette.tileGreen;
      case 'purple':
        return AppPalette.tilePurple;
      default:
        return AppPalette.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = (_state?['board'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Game')),
      body: Row(
        children: [
          SizedBox(
            width: 390,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                CommonCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BackendUrlSection(
                        controller: _backendUrl,
                        onSave: _saveBackendUrl,
                        onUseLocal: _setLocalBackend,
                        onUseProduction: _setProductionBackend,
                      ),
                      TextField(controller: _players, decoration: const InputDecoration(labelText: 'Players comma-separated')),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        ElevatedButton(onPressed: _githubLoginUrl, child: const Text('OAuth URL')),
                        ElevatedButton(onPressed: _exchange, child: const Text('Exchange Code')),
                        ElevatedButton(onPressed: _startGame, child: const Text('Start Game')),
                        ElevatedButton(onPressed: _reloadState, child: const Text('Reload')),
                      ]),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        OutlinedButton(onPressed: _roll, child: const Text('Roll')),
                        OutlinedButton(onPressed: _activePass, child: const Text('Active Pass')),
                        OutlinedButton(onPressed: _allPassOnce, child: const Text('All Pass Once')),
                        OutlinedButton(onPressed: _loadScoreAndEvents, child: const Text('Score+Events')),
                      ]),
                      TextField(controller: _oauthCode, decoration: const InputDecoration(labelText: 'OAuth code')),
                      const SizedBox(height: 8),
                      Text(_status),
                      if (_sessionId != null) Text('Session: $_sessionId'),
                      if (_scores.isNotEmpty) Text('Scores loaded: ${_scores.length}'),
                      if (_events.isNotEmpty) Text('Events loaded: ${_events.length}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CommonCard(
              child: board.isEmpty
                  ? const Center(child: Text('Start a game to render board'))
                  : BoardSheet(board: board, colorFor: _cellColor),
            ),
          ),
        ],
      ),
    );
  }
}
