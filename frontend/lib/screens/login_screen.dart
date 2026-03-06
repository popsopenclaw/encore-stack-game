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

enum _LocalAuthMode { signIn, register }

class _AuthProviderOption {
  const _AuthProviderOption({
    required this.id,
    required this.label,
    required this.kind,
    required this.icon,
    required this.description,
  });

  final String id;
  final String label;
  final String kind;
  final IconData icon;
  final String description;

  bool get isOAuth => kind == 'oauth';
}

class _LoginScreenState extends State<LoginScreen> {
  static const List<_AuthProviderOption> _providerOptions = [
    _AuthProviderOption(
      id: 'github',
      label: 'GitHub',
      kind: 'oauth',
      icon: Icons.code,
      description: 'Open GitHub in the browser and paste the callback code.',
    ),
    _AuthProviderOption(
      id: 'local',
      label: 'Email',
      kind: 'credentials',
      icon: Icons.alternate_email,
      description: 'Use your stored email address and password.',
    ),
  ];

  final _oauthCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _status = 'Choose a provider and sign in.';
  String? _lastAuthUrl;
  bool _busy = false;
  _AuthProviderOption _selectedProvider = _providerOptions.first;
  _LocalAuthMode _localMode = _LocalAuthMode.signIn;

  @override
  void dispose() {
    _oauthCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
      _status = 'Requesting ${_selectedProvider.label} authorization URL...';
    });

    try {
      final api = await _client();
      final res = await api.getOAuthLoginUrl(_selectedProvider.id);
      final url = (res['url'] ?? '').toString();
      if (url.isEmpty) throw Exception('Backend did not return auth URL');
      _lastAuthUrl = url;

      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      setState(() {
        _status =
            opened
                ? '${_selectedProvider.label} opened in browser. Paste the callback code below.'
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
    final code = _oauthCodeController.text.trim();
    if (code.isEmpty) {
      setState(() => _status = 'Paste the OAuth callback code first.');
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Exchanging ${_selectedProvider.label} code...';
    });

    try {
      final api = await _client();
      final res = await api.exchangeOAuthCode(_selectedProvider.id, code);
      await _finishLogin(res);
    } on ApiErrorException catch (e) {
      setState(() => _status = 'OAuth exchange failed: ${e.message}');
    } catch (e) {
      setState(() => _status = 'OAuth exchange failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitLocal() async {
    if (_busy) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _status = 'Email and password are required.');
      return;
    }

    setState(() {
      _busy = true;
      _status =
          _localMode == _LocalAuthMode.signIn
              ? 'Signing in with email...'
              : 'Creating your local account...';
    });

    try {
      final api = await _client();
      final res =
          _localMode == _LocalAuthMode.signIn
              ? await api.loginLocal(email: email, password: password)
              : await api.registerLocal(email: email, password: password);
      await _finishLogin(res);
    } on ApiErrorException catch (e) {
      setState(() => _status = 'Email auth failed: ${e.message}');
    } catch (e) {
      setState(() => _status = 'Email auth failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishLogin(Map<String, dynamic> res) async {
    final token = (res['accessToken'] ?? '').toString();
    if (token.isEmpty) throw Exception('Backend returned no access token');

    await authSessionController.markLoggedIn(token);
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
  }

  void _selectProvider(_AuthProviderOption provider) {
    if (_busy || provider.id == _selectedProvider.id) return;
    setState(() {
      _selectedProvider = provider;
      _status = 'Ready for ${provider.label}.';
      _lastAuthUrl = null;
      _oauthCodeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Login',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 900;
              if (compact) {
                return ListView(
                  shrinkWrap: true,
                  children: [
                    _ProviderPanel(
                      providers: _providerOptions,
                      selectedProviderId: _selectedProvider.id,
                      status: _status,
                      busy: _busy,
                      onSelect: _selectProvider,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AuthPanel(
                      provider: _selectedProvider,
                      busy: _busy,
                      oauthCodeController: _oauthCodeController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      lastAuthUrl: _lastAuthUrl,
                      localMode: _localMode,
                      onLocalModeChanged:
                          (mode) => setState(() => _localMode = mode),
                      onStartOAuth: _startOAuth,
                      onExchangeCode: _exchangeCode,
                      onSubmitLocal: _submitLocal,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 10,
                    child: _ProviderPanel(
                      providers: _providerOptions,
                      selectedProviderId: _selectedProvider.id,
                      status: _status,
                      busy: _busy,
                      onSelect: _selectProvider,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 13,
                    child: _AuthPanel(
                      provider: _selectedProvider,
                      busy: _busy,
                      oauthCodeController: _oauthCodeController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      lastAuthUrl: _lastAuthUrl,
                      localMode: _localMode,
                      onLocalModeChanged:
                          (mode) => setState(() => _localMode = mode),
                      onStartOAuth: _startOAuth,
                      onExchangeCode: _exchangeCode,
                      onSubmitLocal: _submitLocal,
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

class _ProviderPanel extends StatelessWidget {
  const _ProviderPanel({
    required this.providers,
    required this.selectedProviderId,
    required this.status,
    required this.busy,
    required this.onSelect,
  });

  final List<_AuthProviderOption> providers;
  final String selectedProviderId;
  final String status;
  final bool busy;
  final ValueChanged<_AuthProviderOption> onSelect;

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sign-In Methods', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Pick a provider on the left. The login form on the right updates to match it.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: const [
              AppMetaPill(text: 'JWT Session', emphasis: true),
              AppMetaPill(text: 'OAuth + Email'),
              AppMetaPill(text: 'SignalR Ready'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final provider in providers) ...[
            _ProviderTile(
              provider: provider,
              selected: provider.id == selectedProviderId,
              busy: busy,
              onTap: () => onSelect(provider),
            ),
            if (provider != providers.last)
              const SizedBox(height: AppSpacing.sm),
          ],
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

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.provider,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final _AuthProviderOption provider;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppPalette.surfaceInset : AppPalette.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppPalette.neonCyan : AppPalette.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(provider.icon, color: AppPalette.neonCyan),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider.label, style: AppTextStyles.subtitle),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(provider.description, style: AppTextStyles.bodyMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    required this.provider,
    required this.busy,
    required this.oauthCodeController,
    required this.emailController,
    required this.passwordController,
    required this.lastAuthUrl,
    required this.localMode,
    required this.onLocalModeChanged,
    required this.onStartOAuth,
    required this.onExchangeCode,
    required this.onSubmitLocal,
  });

  final _AuthProviderOption provider;
  final bool busy;
  final TextEditingController oauthCodeController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? lastAuthUrl;
  final _LocalAuthMode localMode;
  final ValueChanged<_LocalAuthMode> onLocalModeChanged;
  final Future<void> Function() onStartOAuth;
  final Future<void> Function() onExchangeCode;
  final Future<void> Function() onSubmitLocal;

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child:
          provider.isOAuth
              ? _OAuthForm(
                provider: provider,
                busy: busy,
                codeController: oauthCodeController,
                lastAuthUrl: lastAuthUrl,
                onStartOAuth: onStartOAuth,
                onExchangeCode: onExchangeCode,
              )
              : _LocalForm(
                busy: busy,
                emailController: emailController,
                passwordController: passwordController,
                localMode: localMode,
                onLocalModeChanged: onLocalModeChanged,
                onSubmit: onSubmitLocal,
              ),
    );
  }
}

class _OAuthForm extends StatelessWidget {
  const _OAuthForm({
    required this.provider,
    required this.busy,
    required this.codeController,
    required this.lastAuthUrl,
    required this.onStartOAuth,
    required this.onExchangeCode,
  });

  final _AuthProviderOption provider;
  final bool busy;
  final TextEditingController codeController;
  final String? lastAuthUrl;
  final Future<void> Function() onStartOAuth;
  final Future<void> Function() onExchangeCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${provider.label} OAuth', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Start the OAuth flow in your browser, then paste the callback code here to finish sign-in.',
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: busy ? null : onStartOAuth,
          icon: const Icon(Icons.rocket_launch),
          label: Text('Start ${provider.label} OAuth'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: codeController,
          enabled: !busy,
          decoration: const InputDecoration(
            labelText: 'Callback code',
            hintText: 'Paste the code from the callback URL',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          onPressed: busy ? null : onExchangeCode,
          icon: const Icon(Icons.login),
          label: const Text('Complete Sign In'),
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
    );
  }
}

class _LocalForm extends StatelessWidget {
  const _LocalForm({
    required this.busy,
    required this.emailController,
    required this.passwordController,
    required this.localMode,
    required this.onLocalModeChanged,
    required this.onSubmit,
  });

  final bool busy;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final _LocalAuthMode localMode;
  final ValueChanged<_LocalAuthMode> onLocalModeChanged;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Email Access', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Use email and password to sign in, or create a local account for this device profile.',
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<_LocalAuthMode>(
          segments: const [
            ButtonSegment(value: _LocalAuthMode.signIn, label: Text('Sign In')),
            ButtonSegment(
              value: _LocalAuthMode.register,
              label: Text('Create Account'),
            ),
          ],
          selected: {localMode},
          onSelectionChanged:
              busy ? null : (selection) => onLocalModeChanged(selection.first),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: emailController,
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'name@example.com',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: passwordController,
          enabled: !busy,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: 'At least 8 characters',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: busy ? null : onSubmit,
          icon: Icon(
            localMode == _LocalAuthMode.signIn ? Icons.login : Icons.person_add,
          ),
          label: Text(
            localMode == _LocalAuthMode.signIn
                ? 'Sign In with Email'
                : 'Create Local Account',
          ),
        ),
      ],
    );
  }
}
