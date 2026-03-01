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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF292929)),
        useMaterial3: true,
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
        return const Color(0xFFF6D65E);
      case 'orange':
        return const Color(0xFFF29A42);
      case 'blue':
        return const Color(0xFF72B9F4);
      case 'green':
        return const Color(0xFF9ED86E);
      case 'purple':
        return const Color(0xFFE77CB3);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = (_state?['board'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D8),
      appBar: AppBar(
        title: const Text('Encore! Companion'),
        backgroundColor: const Color(0xFFD8CCB1),
      ),
      body: Row(
        children: [
          SizedBox(
            width: 370,
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
                  : BoardSheet(board: board, colorFor: _cellColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Card(
        color: const Color(0xFFFFFAEE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
        child: Padding(padding: const EdgeInsets.all(12), child: child),
      );
}

class BoardSheet extends StatelessWidget {
  const BoardSheet({super.key, required this.board, required this.colorFor});

  final List<Map<String, dynamic>> board;
  final Color Function(String) colorFor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF202020),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 8)),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: BoardWidget(board: board, colorFor: colorFor)),
                    const SizedBox(width: 12),
                    const SideScoreLegend(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const BottomRulesStrip(),
            ],
          ),
        ),
        const Positioned(left: -10, top: 80, child: _FrameNotch()),
        const Positioned(right: -10, top: 80, child: _FrameNotch()),
      ],
    );
  }
}

class _FrameNotch extends StatelessWidget {
  const _FrameNotch();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class SideScoreLegend extends StatelessWidget {
  const SideScoreLegend({super.key});

  @override
  Widget build(BuildContext context) {
    Widget row(Color c, String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black54)),
            ),
            const SizedBox(width: 6),
            _pill(a),
            const SizedBox(width: 3),
            _pill(b),
          ]),
        );

    return SizedBox(
      width: 136,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          row(const Color(0xFF9ED86E), '5', '3'),
          row(const Color(0xFFF6D65E), '5', '3'),
          row(const Color(0xFF72B9F4), '5', '3'),
          row(const Color(0xFFE77CB3), '5', '3'),
          row(const Color(0xFFF29A42), '5', '3'),
          const SizedBox(height: 8),
          const Text('BONUS =', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
          const SizedBox(height: 8),
          const _RuleLine('A-O', '+', Colors.lightGreenAccent),
          const _RuleLine('!', '+1', Colors.lightGreenAccent),
          const _RuleLine('★', '-2', Colors.redAccent),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: const Text('TOTAL =', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26)),
          ),
        ],
      ),
    );
  }

  Widget _pill(String t) => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
}

class _RuleLine extends StatelessWidget {
  const _RuleLine(this.label, this.value, this.valueColor);

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            ),
          ),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w900, fontSize: 26)),
        ],
      ),
    );
  }
}

class BottomRulesStrip extends StatelessWidget {
  const BottomRulesStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _capsule('?'),
          const SizedBox(width: 6),
          _capsule('✖'),
          const SizedBox(width: 6),
          const Text('=', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          ...List.generate(8, (i) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _circle('!'),
          )),
        ],
      ),
    );
  }

  Widget _capsule(String t) => Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
      );

  Widget _circle(String t) => Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
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

    const topPts = [5, 3, 3, 3, 2, 2, 2, 1, 2, 2, 2, 3, 3, 3, 5];
    const lowPts = [3, 2, 2, 2, 1, 1, 1, 0, 1, 1, 1, 2, 2, 2, 3];
    const letters = 'ABCDEFGHIJKLMNO';

    Widget pill(String t, {Color? bg, Color? fg}) => Container(
          width: 30,
          height: 26,
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: bg ?? Colors.white,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.black26),
          ),
          alignment: Alignment.center,
          child: Text(t, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: fg ?? Colors.black87)),
        );

    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(15, (i) => pill(letters[i], fg: i == 7 ? Colors.red : Colors.black87)),
          ),
          ...List.generate(maxY + 1, (y) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(maxX + 1, (x) {
                final c = grid['${x}_$y'];
                if (c == null) return const SizedBox(width: 30, height: 30);
                return Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: colorFor((c['color'] as String)),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: Colors.black38),
                  ),
                  child: (c['starred'] as bool)
                      ? const Icon(Icons.star, size: 16, color: Colors.white)
                      : null,
                );
              }),
            );
          }),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(15, (i) => pill('${topPts[i]}', fg: i == 7 ? Colors.red : Colors.black87)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(15, (i) => pill('${lowPts[i]}', fg: i == 7 ? Colors.red : Colors.black87)),
          ),
        ],
      ),
    );
  }
}
