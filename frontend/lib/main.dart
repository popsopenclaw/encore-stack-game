import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const EncoreApp());
}

class EncoreApp extends StatelessWidget {
  const EncoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Encore Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
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
  final _apiBaseController = TextEditingController(text: 'http://localhost:8080');
  final _codeController = TextEditingController();

  String? _jwt;
  String _status = 'Ready';
  String? _sessionId;

  Future<void> _openGitHubOAuth() async {
    setState(() => _status = 'Fetching GitHub auth URL...');

    final uri = Uri.parse('${_apiBaseController.text}/api/auth/github/url?state=desktop-client');
    final res = await http.get(uri);
    if (res.statusCode >= 400) {
      setState(() => _status = 'Failed: ${res.statusCode}');
      return;
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final url = body['url'] as String;

    final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    setState(() => _status = launched
        ? 'GitHub login opened. Paste returned code below.'
        : 'Could not open browser. URL: $url');
  }

  Future<void> _exchangeCode() async {
    if (_codeController.text.trim().isEmpty) return;

    setState(() => _status = 'Exchanging code...');

    final uri = Uri.parse('${_apiBaseController.text}/api/auth/github/exchange');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': _codeController.text.trim()}),
    );

    if (res.statusCode >= 400) {
      setState(() => _status = 'Auth failed: ${res.body}');
      return;
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    setState(() {
      _jwt = body['accessToken'] as String;
      _status = 'Logged in as ${body['username']}';
    });
  }

  Future<void> _createSession() async {
    if (_jwt == null) return;

    setState(() => _status = 'Creating game session...');

    final uri = Uri.parse('${_apiBaseController.text}/api/gamesessions');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_jwt',
      },
      body: jsonEncode({
        'name': 'Mobile Session',
        'initialStateJson': jsonEncode({'turn': 1, 'players': []}),
      }),
    );

    if (res.statusCode >= 400) {
      setState(() => _status = 'Create failed: ${res.body}');
      return;
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    setState(() {
      _sessionId = body['id'] as String;
      _status = 'Session created: $_sessionId';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Encore Stack Game')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _apiBaseController,
              decoration: const InputDecoration(
                labelText: 'Backend API Base URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _openGitHubOAuth,
              child: const Text('1) Open GitHub OAuth Login'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'OAuth code from callback URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _exchangeCode,
              child: const Text('2) Exchange Code for JWT'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _createSession,
              child: const Text('3) Create Game Session (Valkey)'),
            ),
            const SizedBox(height: 20),
            Text('Status: $_status'),
            if (_jwt != null) const Text('JWT acquired ✅'),
            if (_sessionId != null) Text('Current Session: $_sessionId'),
          ],
        ),
      ),
    );
  }
}
