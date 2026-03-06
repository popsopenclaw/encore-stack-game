import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/router.dart';
import '../services/api_client.dart';
import '../state/lobby_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';
import '../widgets/ui_kit.dart';

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
    _hydrateLobby();
  }

  Future<void> _hydrateLobby() async {
    if (lobbyController.hasResumableCurrentGame) {
      _openActiveMatch();
      return;
    }

    await lobbyController.refreshCurrentLobby();
    if (!mounted || !lobbyController.hasResumableCurrentGame) return;
    _openActiveMatch();
  }

  void _openActiveMatch() {
    final sessionId = lobbyController.activeSessionId;
    if (sessionId == null || sessionId.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.game,
        arguments: sessionId,
      );
    });
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
      final api = ApiClient(
        baseUrl: lobbyController.backendUrl,
        jwt: lobbyController.jwt,
      );
      final res = await api.startLobbyMatch(code, name: 'Lobby Match');
      final sessionId = (res['sessionId'] ?? '').toString();
      lobbyController.markCurrentLobbyStarted(sessionId);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.game,
        arguments: sessionId,
      );
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lobby code copied')));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: lobbyController,
      builder: (context, _) {
        final members = lobbyController.members;
        final name =
            lobbyController.lobbyName.isEmpty
                ? 'Untitled Lobby'
                : lobbyController.lobbyName;
        final code = lobbyController.lobbyCode ?? '-';
        final isHost = lobbyController.isCurrentUserHost;
        final myId = lobbyController.currentAccountId;
        final myReady =
            myId != null
                ? (lobbyController.readyByAccountId[myId] ?? false)
                : false;

        return AppShell(
          title: 'Lobby Room',
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                children: [
                  AppPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.title.copyWith(fontSize: 30),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            AppMetaPill(text: 'CODE $code', emphasis: true),
                            AppMetaPill(
                              text:
                                  'Players ${members.length}/${lobbyController.maxPlayers}',
                            ),
                            AppMetaPill(
                              text: _busy ? 'Starting...' : 'Waiting in lobby',
                            ),
                            AppMetaPill(
                              text:
                                  isHost ? 'You are host' : 'Waiting for host',
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            Tooltip(
                              message:
                                  isHost
                                      ? 'Start when everyone is ready'
                                      : 'Only host can start the match',
                              child: FilledButton.icon(
                                onPressed:
                                    (_busy || !isHost) ? null : _startMatch,
                                icon: const Icon(Icons.play_arrow),
                                label: Text(
                                  _busy ? 'Starting match...' : 'Start Match',
                                ),
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed:
                                  _busy ? null : lobbyController.toggleMyReady,
                              icon: Icon(
                                myReady
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                              ),
                              label: Text(myReady ? 'Ready' : 'Mark Ready'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _copyCode,
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy Code'),
                            ),
                            OutlinedButton.icon(
                              onPressed:
                                  _busy
                                      ? null
                                      : lobbyController.refreshCurrentLobby,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 900;
                        if (compact) {
                          return ListView(
                            children: [
                              SizedBox(
                                height: 420,
                                child: _PlayersPanel(members: members),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _RulesPanel(error: _error),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(
                              flex: 7,
                              child: _PlayersPanel(members: members),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              flex: 4,
                              child: _RulesPanel(error: _error),
                            ),
                          ],
                        );
                      },
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
}

class _PlayersPanel extends StatelessWidget {
  const _PlayersPanel({required this.members});

  final List<Map<String, dynamic>> members;

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Players', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child:
                members.isEmpty
                    ? const Center(child: Text('No players joined yet.'))
                    : ListView.separated(
                      itemCount: members.length,
                      separatorBuilder:
                          (_, __) => const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, i) {
                        final m = members[i];
                        final host = m['isHost'] as bool? ?? false;
                        final ready = m['isReady'] as bool? ?? false;
                        final displayName =
                            (m['displayName']?.toString() ?? 'Player');

                        return Container(
                          decoration: BoxDecoration(
                            color:
                                host
                                    ? AppPalette.hostHighlightBg
                                    : AppPalette.surfaceInset,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppPalette.borderLight),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor:
                                  host
                                      ? AppPalette.tileOrange
                                      : AppPalette.tileBlue,
                              child: Text(
                                displayName.substring(0, 1).toUpperCase(),
                              ),
                            ),
                            title: Text(displayName),
                            trailing: Wrap(
                              spacing: AppSpacing.xs,
                              children: [
                                if (host)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppPalette.surfaceRaised,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: AppPalette.borderLight,
                                      ),
                                    ),
                                    child: const Text(
                                      'HOST',
                                      style: TextStyle(
                                        color: AppPalette.textOnDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        ready
                                            ? AppPalette.success.withValues(
                                              alpha: 0.2,
                                            )
                                            : AppPalette.surfaceRaised,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppPalette.borderLight,
                                    ),
                                  ),
                                  child: Text(
                                    ready ? 'READY' : 'NOT READY',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class _RulesPanel extends StatelessWidget {
  const _RulesPanel({required this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ready Check Protocol', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '1) Share the lobby code with players.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            '2) Everyone joins and marks ready.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            '3) Host starts match when all are ready.',
            style: AppTextStyles.body,
          ),
          const Spacer(),
          if (error != null)
            Text(
              error!,
              style: const TextStyle(
                color: AppPalette.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
