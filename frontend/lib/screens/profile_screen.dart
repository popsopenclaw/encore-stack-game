import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/router.dart';
import '../config/backend_config.dart';
import '../services/api_client.dart';
import '../state/auth_session_controller.dart';
import '../state/lobby_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';
import '../widgets/ui_kit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _playerNameController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _notice;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    super.dispose();
  }

  Future<ApiClient> _client() async {
    final prefs = await SharedPreferences.getInstance();
    final backendUrl = prefs.getString(kBackendPrefKey) ?? kBackendUrlFromBuild;
    final jwt = prefs.getString(kJwtPrefKey);
    return ApiClient(baseUrl: backendUrl, jwt: jwt);
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });

    try {
      final api = await _client();
      final profile = await api.getProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _playerNameController.text = profile['playerName']?.toString() ?? '';
        _loading = false;
      });
    } on UnauthorizedApiException {
      await _handleExpiredSession();
    } on ApiErrorException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _saveProfile() async {
    final nextName = _playerNameController.text.trim();
    if (nextName.isEmpty) {
      setState(() => _error = 'Player name is required.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
      _notice = null;
    });

    try {
      final api = await _client();
      final profile = await api.updateProfile(playerName: nextName);
      if (lobbyController.lobbyCode != null) {
        await lobbyController.refreshCurrentLobby();
      }
      await lobbyController.refreshLobbies();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _playerNameController.text =
            profile['playerName']?.toString() ?? nextName;
        _saving = false;
        _notice = 'Profile updated.';
      });
    } on UnauthorizedApiException {
      await _handleExpiredSession();
    } on ApiErrorException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
  }

  Future<void> _handleExpiredSession() async {
    await lobbyController.resetForLogout();
    await authSessionController.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return AppShell(
      title: 'Profile',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            children: [
              CommonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Profile', style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Your saved player name is used automatically in lobbies and games.',
                      style: AppTextStyles.bodyMuted,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: const [
                        AppMetaPill(text: 'Saved Identity', emphasis: true),
                        AppMetaPill(text: 'Provider Ready'),
                        AppMetaPill(text: 'Lobby Ready'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              CommonCard(
                child:
                    _loading
                        ? const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Center(child: CircularProgressIndicator()),
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Player Name',
                              style: AppTextStyles.subtitle,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            const Text(
                              'Letters, numbers, hyphens, and underscores only.',
                              style: AppTextStyles.bodyMuted,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextField(
                              controller: _playerNameController,
                              enabled: !_saving,
                              decoration: const InputDecoration(
                                labelText: 'Player name',
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppPalette.danger,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            if (_notice != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                _notice!,
                                style: const TextStyle(
                                  color: AppPalette.neonCyan,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            FilledButton.icon(
                              onPressed: _saving ? null : _saveProfile,
                              icon: const Icon(Icons.save),
                              label: Text(
                                _saving ? 'Saving...' : 'Save Player Name',
                              ),
                            ),
                          ],
                        ),
              ),
              const SizedBox(height: AppSpacing.sm),
              CommonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connected Account',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ProfileRow(
                      label: 'Username',
                      value: profile?['username']?.toString() ?? 'Loading...',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ProfileRow(
                      label: 'Email',
                      value: profile?['email']?.toString() ?? 'Not provided',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ProfileRow(
                      label: 'Avatar URL',
                      value: profile?['avatarUrl']?.toString() ?? 'Loading...',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyMuted),
        const SizedBox(height: AppSpacing.xxs),
        SelectableText(value, style: AppTextStyles.body),
      ],
    );
  }
}
