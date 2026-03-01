import 'package:flutter/foundation.dart';

final lobbyState = LobbyState();

class LobbyState extends ChangeNotifier {
  String? lobbyCode;
  String lobbyName = '';
  int maxPlayers = 6;
  String displayName = '';

  void createLobby({required String name, required int max}) {
    lobbyName = name;
    maxPlayers = max.clamp(1, 6);
    lobbyCode = _generateCode();
    notifyListeners();
  }

  void joinLobby({required String code, required String name}) {
    lobbyCode = code.trim().toUpperCase();
    displayName = name.trim();
    notifyListeners();
  }

  String _generateCode() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
    return ts.substring(ts.length - 6);
  }
}
