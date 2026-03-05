import 'package:flutter/material.dart';

import '../app/router.dart';
import '../services/api_client.dart';
import '../state/lobby_controller.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';

class LobbyRoomScreen extends StatefulWidget {
  const LobbyRoomScreen({super.key});

  @override
  State<LobbyRoomScreen> createState() => _LobbyRoomScreenState();
}

class _LobbyRoomScreenState extends State<LobbyRoomScreen> {
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    lobbyController.refreshCurrentLobby();
  }

  Future<void> _startMatch() async {
    final code = lobbyController.lobbyCode;
    if (code == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await lobbyController.refreshSessionConfig();
      final api = ApiClient(baseUrl: lobbyController.backendUrl, jwt: lobbyController.jwt);
      final res = await api.startLobbyMatch(code, name: 'Lobby Match');
      final sessionId = (res['sessionId'] ?? '').toString();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.game, arguments: sessionId);
    } on ApiErrorException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: lobbyController,
      builder: (context, _) {
        final members = lobbyController.members;
        return AppShell(
          title: 'Lobby Room',
          child: Center(
            child: SizedBox(
              width: 760,
              child: CommonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lobbyController.lobbyName.isEmpty ? 'Untitled Lobby' : lobbyController.lobbyName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('Code: ${lobbyController.lobbyCode ?? '-'} • ${members.length}/${lobbyController.maxPlayers} players'),
                    const SizedBox(height: AppSpacing.md),
                    const Text('Players', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...members.map((m) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.person),
                          title: Text(m['displayName']?.toString() ?? 'Player'),
                          subtitle: Text((m['isHost'] as bool? ?? false) ? 'Host' : 'Member'),
                        )),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _busy ? null : _startMatch,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(_busy ? 'Starting...' : 'Start Match'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () async {
                                  await lobbyController.refreshCurrentLobby();
                                },
                          child: const Text('Refresh lobby'),
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
