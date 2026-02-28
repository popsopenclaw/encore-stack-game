import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const EncoreApp());

class EncoreApp extends StatelessWidget {
  const EncoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Encore',
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF355C7D)),
      ),
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
  final _api = TextEditingController(text: 'http://localhost:8080');
  final _oauthCode = TextEditingController();
  final _players = TextEditingController(text: 'pop,bot2');

  String? _jwt;
  String? _sessionId;
  String _status = 'Ready';
  Map<String, dynamic>? _state;

  Future<void> _githubLoginUrl() async {
    final r = await http.get(Uri.parse('${_api.text}/api/auth/github/url?state=encore-app'));
    final url = (jsonDecode(r.body) as Map<String, dynamic>)['url'] as String;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    setState(() => _status = 'Browser opened. Paste OAuth code from callback URL.');
  }

  Future<void> _exchange() async {
    final r = await http.post(
      Uri.parse('${_api.text}/api/auth/github/exchange'),
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
      Uri.parse('${_api.text}/api/gameplay/start'),
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
      Uri.parse('${_api.text}/api/gameplay/$_sessionId'),
      headers: {'Authorization': 'Bearer $_jwt'},
    );
    if (r.statusCode < 400) {
      setState(() => _state = jsonDecode(r.body) as Map<String, dynamic>);
    }
  }

  Color _cellColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'yellow':
        return const Color(0xFFF6D55C);
      case 'orange':
        return const Color(0xFFF28D35);
      case 'blue':
        return const Color(0xFF4A90E2);
      case 'green':
        return const Color(0xFF7ED37F);
      case 'purple':
        return const Color(0xFFB084F5);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = (_state?['board'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F1E1),
      appBar: AppBar(
        title: const Text('Encore! Companion'),
        backgroundColor: const Color(0xFFE6D7B8),
      ),
      body: Row(
        children: [
          SizedBox(
            width: 380,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _card(
                  child: Column(
                    children: [
                      TextField(controller: _api, decoration: const InputDecoration(labelText: 'API URL')),
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
            child: _card(
              child: board.isEmpty
                  ? const Center(child: Text('Start a game to render board'))
                  : BoardWidget(board: board, colorFor: _cellColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Card(
        color: const Color(0xFFFFFBF2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
        child: Padding(padding: const EdgeInsets.all(12), child: child),
      );
}

class BoardWidget extends StatelessWidget {
  const BoardWidget({super.key, required this.board, required this.colorFor});
  final List<Map<String, dynamic>> board;
  final Color Function(String) colorFor;

  @override
  Widget build(BuildContext context) {
    final maxX = board.map((e) => e['x'] as int).reduce((a, b) => a > b ? a : b);
    final maxY = board.map((e) => e['y'] as int).reduce((a, b) => a > b ? a : b);
    final grid = <String, Map<String, dynamic>>{for (final c in board) '${c['x']}_${c['y']}': c};

    return SingleChildScrollView(
      child: Column(
        children: List.generate(maxY + 1, (y) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(maxX + 1, (x) {
              final c = grid['${x}_$y'];
              if (c == null) {
                return const SizedBox(width: 30, height: 30);
              }
              return Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  color: colorFor((c['color'] as String)),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black26),
                ),
                child: (c['starred'] as bool)
                    ? const Icon(Icons.star, size: 12, color: Colors.black54)
                    : null,
              );
            }),
          );
        }),
      ),
    );
  }
}
