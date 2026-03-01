import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config/backend_config.dart';
import 'theme/app_palette.dart';
import 'theme/app_theme.dart';
import 'widgets/backend_url_section.dart';
import 'widgets/board_sheet.dart';
import 'widgets/common_card.dart';

void main() => runApp(const EncoreApp());

class EncoreApp extends StatelessWidget {
  const EncoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Encore',
      theme: AppTheme.light,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _backendUrl = TextEditingController(text: kBackendUrlFromBuild);
  final _oauthCode = TextEditingController();
  final _players = TextEditingController(text: 'pop,bot2');

  String? _jwt;
  String? _sessionId;
  String _status = 'Ready';
  Map<String, dynamic>? _state;

  String get _apiBase => _backendUrl.text.trim();

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
    if (saved != null && saved.isNotEmpty) {
      _backendUrl.text = saved;
    }
  }

  Future<void> _saveBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kBackendPrefKey, _apiBase);
    if (mounted) {
      setState(() => _status = 'Backend URL saved: $_apiBase');
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

  Future<void> _githubLoginUrl() async {
    final r = await http.get(Uri.parse('$_apiBase/api/auth/github/url?state=encore-app'));
    final url = (jsonDecode(r.body) as Map<String, dynamic>)['url'] as String;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    setState(() => _status = 'Browser opened. Paste OAuth code from callback URL.');
  }

  Future<void> _exchange() async {
    final r = await http.post(
      Uri.parse('$_apiBase/api/auth/github/exchange'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': _oauthCode.text.trim()}),
    );
    if (r.statusCode >= 400) {
      setState(() => _status = 'Auth failed: ${r.body}');
      return;
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    setState(() {
      _jwt = body['accessToken'] as String;
      _status = 'Logged in as ${body['username']}';
    });
  }

  Future<void> _startGame() async {
    final names = _players.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final r = await http.post(
      Uri.parse('$_apiBase/api/gameplay/start'),
      headers: {'Authorization': 'Bearer $_jwt', 'Content-Type': 'application/json'},
      body: jsonEncode({'playerNames': names}),
    );
    if (r.statusCode >= 400) {
      setState(() => _status = 'Start failed: ${r.body}');
      return;
    }
    final state = jsonDecode(r.body) as Map<String, dynamic>;
    setState(() {
      _state = state;
      _sessionId = state['sessionId'] as String;
      _status = 'Game started.';
    });
  }

  Future<void> _reloadState() async {
    if (_sessionId == null) return;
    final r = await http.get(
      Uri.parse('$_apiBase/api/gameplay/$_sessionId'),
      headers: {'Authorization': 'Bearer $_jwt'},
    );
    if (r.statusCode < 400) {
      setState(() => _state = jsonDecode(r.body) as Map<String, dynamic>);
    }
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
      appBar: AppBar(title: const Text('Encore! Companion')),
      body: Row(
        children: [
          SizedBox(
            width: 370,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                CommonCard(
                  child: Column(
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
                        ElevatedButton(onPressed: _githubLoginUrl, child: const Text('GitHub Login URL')),
                        ElevatedButton(onPressed: _exchange, child: const Text('Exchange Code')),
                        ElevatedButton(onPressed: _startGame, child: const Text('Start Game')),
                        ElevatedButton(onPressed: _reloadState, child: const Text('Refresh')),
                      ]),
                      TextField(controller: _oauthCode, decoration: const InputDecoration(labelText: 'OAuth code')),
                      const SizedBox(height: 8),
                      Text(_status),
                      if (_sessionId != null) Text('Session: $_sessionId'),
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
