import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/router.dart';
import '../config/backend_config.dart';
import '../services/api_client.dart';
import '../state/auth_session_controller.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _codeController = TextEditingController();
  String _status = 'Ready';
  String? _lastAuthUrl;
  bool _busy = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<ApiClient> _client() async {
    final prefs = await SharedPreferences.getInstance();
    final backendUrl = prefs.getString(kBackendPrefKey) ?? kBackendUrlFromBuild;
    return ApiClient(baseUrl: backendUrl);
  }

  Future<void> _startOAuth() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'Requesting GitHub auth URL...';
    });

    try {
      final api = await _client();
      final res = await api.getGitHubLoginUrl();
      final url = (res['url'] ?? '').toString();
      if (url.isEmpty) throw Exception('Backend did not return auth URL');
      _lastAuthUrl = url;

      final uri = Uri.parse(url);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      setState(() {
        _status = opened
            ? 'GitHub opened in browser. After authorize, paste the returned code below.'
            : 'Could not open browser automatically. Use the URL below manually.';
      });
    } on ApiErrorException catch (e) {
      setState(() => _status = 'OAuth URL failed: ${e.message}');
    } catch (e) {
      setState(() => _status = 'OAuth URL failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exchangeCode() async {
    if (_busy) return;
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _status = 'Paste the OAuth code first.');
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Exchanging OAuth code...';
    });

    try {
      final api = await _client();
      final res = await api.exchangeGitHubCode(code);
      final token = (res['accessToken'] ?? '').toString();
      if (token.isEmpty) throw Exception('Backend returned no access token');

      await authSessionController.markLoggedIn(token);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } on ApiErrorException catch (e) {
      setState(() => _status = 'OAuth exchange failed: ${e.message}');
    } catch (e) {
      setState(() => _status = 'OAuth exchange failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Login',
      child: Center(
        child: SizedBox(
          width: 560,
          child: CommonCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_outline, size: 42),
                const SizedBox(height: 10),
                const Text('Login with GitHub OAuth to continue'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _busy ? null : _startOAuth,
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Start GitHub OAuth'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'OAuth code',
                    hintText: 'Paste code from callback URL',
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _busy ? null : _exchangeCode,
                  icon: const Icon(Icons.login),
                  label: const Text('Complete Login'),
                ),
                if (_lastAuthUrl != null) ...[
                  const SizedBox(height: 12),
                  SelectableText(_lastAuthUrl!),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _lastAuthUrl!));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Auth URL copied')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy auth URL'),
                  ),
                ],
                const SizedBox(height: 8),
                Text(_status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
