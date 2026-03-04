import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/ihub_protocol.dart';
import 'package:signalr_netcore/json_hub_protocol.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';

class LobbyRealtimeService {
  HubConnection? _conn;

  Future<void> connect({
    required String backendUrl,
    required String? jwt,
    required void Function(Map<String, dynamic> lobby) onLobbyUpdated,
  }) async {
    await disconnect();

    final hubUrl = '$backendUrl/hubs/lobby';
    final protocol = JsonHubProtocol();

    _conn = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => jwt ?? '',
          ),
        )
        .withHubProtocol(protocol as IHubProtocol)
        .build();

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
