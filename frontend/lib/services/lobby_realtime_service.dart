import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/ihub_protocol.dart';
import 'package:signalr_netcore/json_hub_protocol.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';

enum RealtimeStatus { disconnected, connecting, connected, reconnecting }

class LobbyRealtimeService {
  HubConnection? _conn;

  Future<void> connect({
    required String backendUrl,
    required String? jwt,
    required void Function(Map<String, dynamic> lobby) onLobbyUpdated,
    void Function(RealtimeStatus status)? onStatusChanged,
    Future<void> Function()? onReconnected,
  }) async {
    await disconnect();

    final hubUrl = '$backendUrl/hubs/lobby';
    final protocol = JsonHubProtocol();

    onStatusChanged?.call(RealtimeStatus.connecting);

    _conn =
        HubConnectionBuilder()
            .withUrl(
              hubUrl,
              options: HttpConnectionOptions(
                accessTokenFactory: () async => jwt ?? '',
              ),
            )
            .withHubProtocol(protocol as IHubProtocol)
            .withAutomaticReconnect(
              retryDelays: [0, 1000, 2000, 4000, 8000, 16000],
            )
            .build();

    _conn!.onclose(({error}) {
      onStatusChanged?.call(RealtimeStatus.disconnected);
    });

    _conn!.onreconnecting(({error}) {
      onStatusChanged?.call(RealtimeStatus.reconnecting);
    });

    _conn!.onreconnected(({connectionId}) async {
      onStatusChanged?.call(RealtimeStatus.connected);
      if (onReconnected != null) await onReconnected();
    });

    _conn!.on('lobbyUpdated', (args) {
      if (args == null || args.isEmpty) return;
      final raw = args.first;
      if (raw is Map<String, dynamic>) {
        onLobbyUpdated(raw);
      } else if (raw is Map) {
        onLobbyUpdated(raw.map((k, v) => MapEntry('$k', v)));
      }
    });

    await _conn!.start();
    onStatusChanged?.call(RealtimeStatus.connected);
  }

  Future<void> joinLobbyGroup(String code) async {
    if (_conn == null) return;
    await _conn!.invoke('JoinLobby', args: [code]);
  }

  Future<void> leaveLobbyGroup(String code) async {
    if (_conn == null) return;
    await _conn!.invoke('LeaveLobby', args: [code]);
  }

  Future<void> disconnect() async {
    if (_conn != null) {
      await _conn!.stop();
      _conn = null;
    }
  }
}
