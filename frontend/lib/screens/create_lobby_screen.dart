import 'package:flutter/material.dart';

import '../app/router.dart';
import '../state/lobby_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';
import '../widgets/ui_kit.dart';

class CreateLobbyScreen extends StatefulWidget {
  const CreateLobbyScreen({super.key});

  @override
  State<CreateLobbyScreen> createState() => _CreateLobbyScreenState();
}

class _CreateLobbyScreenState extends State<CreateLobbyScreen> {
  int _maxPlayers = 4;
  bool _creating = false;
  String? _error;

  Future<void> _create() async {
    setState(() {
      _creating = true;
      _error = null;
    });

    await lobbyController.createLobby(max: _maxPlayers);

    if (!mounted) return;
    setState(() => _creating = false);

    if (lobbyController.lobbyCode == null) {
      setState(() => _error = lobbyController.status);
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.lobbyRoom);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Create Lobby',
      child: ListView(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: CommonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Create Lobby', style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Configure your room and launch a multiplayer session. The lobby name will be generated from your saved player name automatically.',
                      style: AppTextStyles.bodyMuted,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: const [
                        AppMetaPill(text: 'Host Controls', emphasis: true),
                        AppMetaPill(text: '2 to 6 Players'),
                        AppMetaPill(text: 'Realtime Lobby'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text('Max players', style: AppTextStyles.subtitle),
                    Slider(
                      value: _maxPlayers.toDouble(),
                      min: 2,
                      max: 6,
                      divisions: 4,
                      label: '$_maxPlayers',
                      onChanged:
                          _creating
                              ? null
                              : (v) => setState(() => _maxPlayers = v.round()),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppMetaPill(text: '$_maxPlayers players'),
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
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _creating ? null : _create,
                            icon: const Icon(Icons.group_add),
                            label: Text(
                              _creating ? 'Creating...' : 'Create Lobby',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
