import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/router.dart';
import '../config/backend_config.dart';
import '../services/api_client.dart';
import '../state/auth_session_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';
import '../widgets/ui_kit.dart';

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
        _status =
            opened
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1060),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 860;
              if (compact) {
                return ListView(
                  shrinkWrap: true,
                  children: [
                    _HeroPanel(status: _status),
                    const SizedBox(height: AppSpacing.md),
                    _AuthPanel(
                      busy: _busy,
                      status: _status,
                      codeController: _codeController,
                      lastAuthUrl: _lastAuthUrl,
                      onStartOAuth: _startOAuth,
                      onExchangeCode: _exchangeCode,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 11, child: _HeroPanel(status: _status)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 12,
                    child: _AuthPanel(
                      busy: _busy,
                      status: _status,
                      codeController: _codeController,
                      lastAuthUrl: _lastAuthUrl,
                      onStartOAuth: _startOAuth,
                      onExchangeCode: _exchangeCode,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Encore Control Deck', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Authenticate with GitHub and enter the multiplayer relay.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: const [
              AppMetaPill(text: 'OAuth 2.0', emphasis: true),
              AppMetaPill(text: 'JWT Session'),
              AppMetaPill(text: 'SignalR Ready'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppPalette.surfaceInset,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppPalette.borderLight),
            ),
            child: Text(status, style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    required this.busy,
    required this.status,
    required this.codeController,
    required this.lastAuthUrl,
    required this.onStartOAuth,
    required this.onExchangeCode,
  });

  final bool busy;
  final String status;
  final TextEditingController codeController;
  final String? lastAuthUrl;
  final Future<void> Function() onStartOAuth;
  final Future<void> Function() onExchangeCode;

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('GitHub Sign-In', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: busy ? null : onStartOAuth,
            icon: const Icon(Icons.rocket_launch),
            label: const Text('Start GitHub OAuth'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: codeController,
            decoration: const InputDecoration(
              labelText: 'OAuth code',
              hintText: 'Paste code from callback URL',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: busy ? null : onExchangeCode,
            icon: const Icon(Icons.login),
            label: const Text('Complete Login'),
          ),
          if (lastAuthUrl != null) ...[
            const SizedBox(height: AppSpacing.md),
            SelectableText(lastAuthUrl!, style: AppTextStyles.bodyMuted),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: lastAuthUrl!));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Auth URL copied')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy auth URL'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
