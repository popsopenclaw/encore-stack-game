import 'package:flutter/material.dart';

import '../app/router.dart';
import '../state/lobby_controller.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';

class CreateLobbyScreen extends StatefulWidget {
  const CreateLobbyScreen({super.key});

  @override
  State<CreateLobbyScreen> createState() => _CreateLobbyScreenState();
}

class _CreateLobbyScreenState extends State<CreateLobbyScreen> {
  final _name = TextEditingController(text: 'Encore Lobby');
  final _displayName = TextEditingController(text: 'Host');
  int _maxPlayers = 4;
  bool _creating = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final lobbyName = _name.text.trim();
    final displayName = _displayName.text.trim();

    if (lobbyName.isEmpty) {
      setState(() => _error = 'Lobby name is required.');
      return;
    }
    if (displayName.isEmpty) {
      setState(() => _error = 'Display name is required.');
      return;
    }

    setState(() {
      _creating = true;
      _error = null;
    });

    await lobbyController.createLobby(
      name: lobbyName,
      max: _maxPlayers,
      hostDisplayName: displayName,
    );

    if (!mounted) return;
    setState(() => _creating = false);

    if (lobbyController.lobbyCode == null) {
      setState(() => _error = lobbyController.status);
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.game);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Create Lobby',
      child: Center(
        child: SizedBox(
          width: 560,
          child: CommonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create a new multiplayer lobby', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs),
                const Text('Set the basics and invite friends using the generated lobby code.'),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Lobby name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _displayName,
                  decoration: const InputDecoration(
                    labelText: 'Your display name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Max players'),
                Slider(
                  value: _maxPlayers.toDouble(),
                  min: 2,
                  max: 6,
                  divisions: 4,
                  label: '$_maxPlayers',
                  onChanged: _creating ? null : (v) => setState(() => _maxPlayers = v.round()),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('$_maxPlayers players'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _creating ? null : _create,
                        icon: const Icon(Icons.group_add),
                        label: Text(_creating ? 'Creating...' : 'Create Lobby'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
