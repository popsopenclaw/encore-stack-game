import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/router.dart';
import '../services/api_client.dart';
import '../state/lobby_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
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

  Future<void> _copyCode() async {
    final code = lobbyController.lobbyCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lobby code copied')));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: lobbyController,
      builder: (context, _) {
        final members = lobbyController.members;
        final name = lobbyController.lobbyName.isEmpty ? 'Untitled Lobby' : lobbyController.lobbyName;
        final code = lobbyController.lobbyCode ?? '-';

        return AppShell(
          title: 'Lobby Room',
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppPalette.boardFrame,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: AppPalette.boardFrameShadow, blurRadius: 14, offset: Offset(0, 8))],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AppTextStyles.boardLabel.copyWith(color: AppPalette.textOnDark, fontSize: 30)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _pill('CODE', code, emphasize: true),
                            _pill('PLAYERS', '${members.length}/${lobbyController.maxPlayers}'),
                            _pill('STATUS', _busy ? 'Starting...' : 'Waiting in lobby'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FilledButton.icon(
                              onPressed: _busy ? null : _startMatch,
                              icon: const Icon(Icons.play_arrow),
                              label: Text(_busy ? 'Starting match...' : 'Start Match'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _copyCode,
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy Code'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _busy ? null : lobbyController.refreshCurrentLobby,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: CommonCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Players', style: AppTextStyles.title),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: members.isEmpty
                                      ? const Center(child: Text('No players joined yet.'))
                                      : ListView.separated(
                                          itemCount: members.length,
                                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                                          itemBuilder: (context, i) {
                                            final m = members[i];
                                            final host = m['isHost'] as bool? ?? false;
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: host ? const Color(0xFFFFF3CD) : AppPalette.cardBg,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: AppPalette.borderLight),
                                              ),
                                              child: ListTile(
                                                dense: true,
                                                leading: CircleAvatar(
                                                  backgroundColor: host ? AppPalette.tileOrange : AppPalette.tileBlue,
                                                  child: Text((m['displayName']?.toString() ?? '?').substring(0, 1).toUpperCase()),
                                                ),
                                                title: Text(m['displayName']?.toString() ?? 'Player'),
                                                trailing: host
                                                    ? Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: AppPalette.boardFrame,
                                                          borderRadius: BorderRadius.circular(999),
                                                        ),
                                                        child: const Text('HOST', style: TextStyle(color: AppPalette.textOnDark, fontWeight: FontWeight.w700, fontSize: 11)),
                                                      )
                                                    : const Text('READY'),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CommonCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('How this works', style: AppTextStyles.title),
                                const SizedBox(height: 8),
                                const Text('1) Share the lobby code'),
                                const SizedBox(height: 6),
                                const Text('2) Wait for players to join'),
                                const SizedBox(height: 6),
                                const Text('3) Start Match when everyone is ready'),
                                const Spacer(),
                                if (_error != null)
                                  Text(_error!, style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pill(String label, String value, {bool emphasize = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: emphasize ? AppPalette.white : AppPalette.stripBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppPalette.borderDark),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: emphasize ? AppPalette.textPrimary : AppPalette.textOnDark),
          children: [
            TextSpan(text: '$label  ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
