import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/backend_config.dart';
import '../services/api_client.dart';
import 'auth_session_controller.dart';
import 'die_face_codec.dart';
import 'lobby_controller.dart';
import 'move_validator.dart';

class GameController extends ChangeNotifier {
  final backendUrl = TextEditingController(text: kBackendUrlFromBuild);
  final oauthCode = TextEditingController();
  final players = TextEditingController(text: 'pop,bot2');

  String? jwt;
  String? sessionId;
  String status = 'Ready';
  Map<String, dynamic>? state;
  List<dynamic> scores = const [];
  List<dynamic> events = const [];

  List<String> availableColorDice = const [];
  List<String> availableNumberDice = const [];
  String? selectedColorDie;
  String? selectedNumberDie;
  final Set<String> selectedCellIds = <String>{};
  String? validationMessage;
  String? boardHintMessage;
  bool attemptedAutoResume = false;
  ApiErrorCode? lastLoadErrorCode;

  String get apiBase => backendUrl.text.trim();
  ApiClient get client => ApiClient(baseUrl: apiBase, jwt: jwt);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(kBackendPrefKey);
    if (saved != null && saved.isNotEmpty) backendUrl.text = saved;
    final savedJwt = prefs.getString(kJwtPrefKey);
    if (savedJwt != null && savedJwt.isNotEmpty) jwt = savedJwt;
    notifyListeners();
  }

  Future<void> saveActiveSessionId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kActiveGameSessionPrefKey, id);
  }

  Future<String?> readActiveSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(kActiveGameSessionPrefKey);
    if (id == null || id.isEmpty) return null;
    return id;
  }

  Future<void> clearActiveSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kActiveGameSessionPrefKey);
  }

  Future<void> disposeController() async {
    backendUrl.dispose();
    oauthCode.dispose();
    players.dispose();
  }

  Future<void> saveBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kBackendPrefKey, apiBase);
    _setStatus('Backend URL saved: $apiBase');
  }

  Future<void> setLocalBackend() async {
    backendUrl.text = 'http://localhost:8080';
    await saveBackendUrl();
  }

  Future<void> setProductionBackend() async {
    backendUrl.text = kBackendUrlFromBuild;
    await saveBackendUrl();
  }

  Future<void> githubLoginUrl(Future<void> Function(String url) openUrl) async {
    await _run('OAuth URL', () async {
      final body = await client.getGitHubLoginUrl();
      await openUrl(body['url'] as String);
    });
  }

  Future<void> exchange() async => _run('OAuth exchange', () async {
    final body = await client.exchangeGitHubCode(oauthCode.text.trim());
    jwt = body['accessToken'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kJwtPrefKey, jwt!);
    await authSessionController.markLoggedIn(jwt!);
  });

  Future<void> startGame() async => _run('Start game', () async {
    final names =
        players.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
    final game = await client.startGame(names);
    state = game;
    sessionId = game['sessionId'] as String;
    await saveActiveSessionId(sessionId!);
    _syncSelectionAfterStateChange();
  });

  Future<void> startMatchFromLobby(String lobbyCode) async => _run(
    'Start match',
    () async {
      final res = await client.startLobbyMatch(lobbyCode, name: 'Lobby Match');
      final id = (res['sessionId'] ?? '').toString();
      if (id.isEmpty) throw Exception('Lobby start did not return sessionId');
      await _loadSessionData(id);
      await saveActiveSessionId(id);
    },
  );

  Future<void> loadSession(String id) async {
    attemptedAutoResume = false;
    lastLoadErrorCode = null;
    await _run('Load game', () async {
      await _loadSessionData(id);
      await saveActiveSessionId(id);
    });
  }

  Future<bool> restoreLastSessionIfAny() async {
    attemptedAutoResume = true;
    lastLoadErrorCode = null;
    final id = await readActiveSessionId();
    if (id == null) {
      _setStatus('No recent game session found.');
      return false;
    }

    _setStatus('Resuming last game...');
    try {
      await _loadSessionData(id);
      await saveActiveSessionId(id);
      _setStatus('Resumed last game');
      return true;
    } on UnauthorizedApiException {
      await clearActiveSessionId();
      await authSessionController.logout();
      await lobbyController.resetForLogout();
      _setStatus('Session expired. Please login again.');
      return false;
    } on ApiErrorException catch (e) {
      lastLoadErrorCode = e.code;
      if (e.code == ApiErrorCode.notFound || e.code == ApiErrorCode.forbidden) {
        await clearActiveSessionId();
        sessionId = null;
        state = null;
        availableColorDice = const [];
        availableNumberDice = const [];
        selectedColorDie = null;
        selectedNumberDie = null;
        selectedCellIds.clear();
        validationMessage = null;
        boardHintMessage = null;
        _setStatus('Previous game session is no longer available.');
      } else {
        _setStatus('Resume failed: ${_messageForApiError(e)}');
      }
      return false;
    } catch (e) {
      _setStatus('Resume failed: $e');
      return false;
    }
  }

  Future<void> reloadState() async {
    if (sessionId == null) return;
    await _run('Reload state', () async {
      state = await client.getGame(sessionId!);
      await loadAvailableDiceForCurrentPlayer(quiet: true);
      _syncSelectionAfterStateChange();
    });
  }

  Future<void> roll() async {
    if (!canRoll) return;
    await _run('Roll', () async {
      await client.roll(sessionId!);
      state = await client.getGame(sessionId!);
      await loadAvailableDiceForCurrentPlayer(quiet: true);
      _syncSelectionAfterStateChange();
    });
  }

  Future<void> activePass() async {
    if (!canActivePass) return;
    await _run('Active pass', () async {
      final idx = (state?['activePlayerIndex'] as int?) ?? 0;
      await client.activeSelect(sessionId!, playerIndex: idx, pass: true);
      state = await client.getGame(sessionId!);
      await loadAvailableDiceForCurrentPlayer(quiet: true);
      _syncSelectionAfterStateChange();
    });
  }

  Future<void> allPassOnce() async {
    if (sessionId == null || state == null) return;
    await _run('Resolve pass round', () async {
      final count = (state!['players'] as List<dynamic>).length;
      for (var i = 0; i < count; i++) {
        await client.playerAction(sessionId!, playerIndex: i, pass: true);
      }
      state = await client.getGame(sessionId!);
      await loadAvailableDiceForCurrentPlayer(quiet: true);
      _syncSelectionAfterStateChange();
    });
  }

  Future<void> loadScoreAndEvents() async {
    if (sessionId == null) return;
    await _run('Load score/events', () async {
      scores = await client.getScore(sessionId!);
      events = await client.getEvents(sessionId!);
    });
  }

  Future<void> loadAvailableDiceForCurrentPlayer({bool quiet = false}) async {
    if (!canLoadAvailableDice) return;
    Future<void> fn() async {
      final playerIndex =
          currentResolvingPlayerIndex ??
          (state?['activePlayerIndex'] as int?) ??
          0;
      final dice = await client.getAvailableDice(
        sessionId!,
        playerIndex: playerIndex,
      );
      availableColorDice = DieFaceCodec.colorFaces(
        dice['colorDice'],
        unique: true,
      );
      availableNumberDice = DieFaceCodec.numberFaces(
        dice['numberDice'],
        unique: true,
      );
      selectedColorDie =
          availableColorDice.contains(selectedColorDie)
              ? selectedColorDie
              : (availableColorDice.isNotEmpty
                  ? availableColorDice.first
                  : null);
      selectedNumberDie =
          availableNumberDice.contains(selectedNumberDie)
              ? selectedNumberDie
              : (availableNumberDice.isNotEmpty
                  ? availableNumberDice.first
                  : null);
      _refreshValidationMessage();
    }

    if (quiet) {
      await fn();
      return;
    }
    await _run('Load available dice', fn);
  }

  void setSelectedColorDie(String? value) {
    selectedColorDie = value;
    _refreshValidationMessage();
    notifyListeners();
  }

  void setSelectedNumberDie(String? value) {
    selectedNumberDie = value;
    _refreshValidationMessage();
    notifyListeners();
  }

  void toggleCellSelection(String cellId) {
    if (!canInteractWithBoard) return;
    if (blockedCellIds.contains(cellId)) return;
    boardHintMessage = null;
    if (selectedCellIds.contains(cellId)) {
      selectedCellIds.remove(cellId);
    } else {
      selectedCellIds.add(cellId);
    }
    _refreshValidationMessage();
    notifyListeners();
  }

  Future<void> submitActiveSelection() async {
    if (!canSubmitActiveSelection) return;
    await _run('Active selection', () async {
      final idx = (state?['activePlayerIndex'] as int?) ?? 0;
      await client.activeSelect(
        sessionId!,
        playerIndex: idx,
        colorDie: selectedColorDie,
        numberDie: selectedNumberDie,
        pass: false,
      );
      state = await client.getGame(sessionId!);
      await loadAvailableDiceForCurrentPlayer(quiet: true);
      _syncSelectionAfterStateChange();
    });
  }

  Future<void> submitPlayerMove() async {
    if (!canSubmitMove) return;
    final validation = currentMoveValidation;
    if (validation == null || !validation.ok) {
      _setStatus(validation?.reason ?? 'Move is not valid.');
      return;
    }
    await _run('Submit move', () async {
      final idx =
          currentResolvingPlayerIndex ??
          (state?['activePlayerIndex'] as int?) ??
          0;
      await client.playerAction(
        sessionId!,
        playerIndex: idx,
        colorDie: selectedColorDie,
        numberDie: selectedNumberDie,
        cellIds: selectedCellIds.toList(),
        pass: false,
      );
      state = await client.getGame(sessionId!);
      await loadAvailableDiceForCurrentPlayer(quiet: true);
      _syncSelectionAfterStateChange();
    });
  }

  String get phase => (state?['phase']?.toString() ?? 'NeedRoll');

  bool get canRoll => sessionId != null && phase == 'NeedRoll';
  bool get canActivePass => sessionId != null && phase == 'NeedActiveSelection';
  bool get canSubmitActiveSelection =>
      sessionId != null &&
      phase == 'NeedActiveSelection' &&
      selectedColorDie != null &&
      selectedNumberDie != null;

  bool get canSubmitMove =>
      sessionId != null &&
      phase == 'PlayersResolving' &&
      selectedColorDie != null &&
      selectedNumberDie != null &&
      selectedCellIds.isNotEmpty &&
      (currentMoveValidation?.ok ?? false);

  bool get canLoadAvailableDice =>
      sessionId != null && phase == 'PlayersResolving';

  List<Map<String, dynamic>> get playersState =>
      ((state?['players'] as List<dynamic>?) ?? const [])
          .whereType<Map>()
          .map((row) => row.map((k, v) => MapEntry('$k', v)))
          .toList();

  Set<int> get resolvedPlayerIndices =>
      ((state?['resolvedPlayers'] as List<dynamic>?) ?? const [])
          .whereType<int>()
          .toSet();

  int? get currentResolvingPlayerIndex {
    if (playersState.isEmpty) return null;
    final active = (state?['activePlayerIndex'] as int?) ?? 0;
    if (phase != 'PlayersResolving') return active;

    final resolved = resolvedPlayerIndices;
    for (var offset = 0; offset < playersState.length; offset++) {
      final candidate = (active + offset) % playersState.length;
      if (!resolved.contains(candidate)) return candidate;
    }
    return null;
  }

  Map<String, dynamic>? get currentResolvingPlayer {
    final idx = currentResolvingPlayerIndex;
    if (idx == null || idx < 0 || idx >= playersState.length) return null;
    return playersState[idx];
  }

  int get openDraftTurnsRemaining =>
      (state?['initialOpenDraftTurnsRemaining'] as int?) ?? 0;
  bool get endTriggered => (state?['endTriggered'] as bool?) ?? false;
  bool get isFinished => (state?['isFinished'] as bool?) ?? false;
  int get currentResolvingPlayerJokers =>
      (currentResolvingPlayer?['jokerMarksRemaining'] as int?) ?? 0;

  bool get canInteractWithBoard =>
      sessionId != null && phase == 'PlayersResolving';

  Set<String> get blockedCellIds {
    if (phase != 'PlayersResolving') return {};
    final checked =
        ((currentResolvingPlayer?['checkedCells'] as List<dynamic>?) ??
                const [])
            .map((e) => '$e')
            .toSet();
    return checked;
  }

  MoveValidationResult? get currentMoveValidation {
    if (!canInteractWithBoard) return null;
    return MoveValidator.validate(
      state: state,
      playerIndex: currentResolvingPlayerIndex,
      selectedCellIds: selectedCellIds,
      colorDie: selectedColorDie,
      numberDie: selectedNumberDie,
      availableColorDice: availableColorDice,
      availableNumberDice: availableNumberDice,
    );
  }

  Future<void> _run(String action, Future<void> Function() fn) async {
    _setStatus('$action...');
    try {
      await fn();
      _setStatus('$action done');
    } on UnauthorizedApiException {
      await clearActiveSessionId();
      await authSessionController.logout();
      await lobbyController.resetForLogout();
      _setStatus('Session expired. Please login again.');
    } on ApiErrorException catch (e) {
      _setStatus('$action failed: ${_messageForApiError(e)}');
    } catch (e) {
      _setStatus('$action failed: $e');
    }
  }

  String _messageForApiError(ApiErrorException e) {
    switch (e.code) {
      case ApiErrorCode.forbidden:
        return 'You do not have permission for this action.';
      case ApiErrorCode.notFound:
        return 'Game session was not found.';
      case ApiErrorCode.invalidOperation:
      case ApiErrorCode.invalidRequest:
        return e.message;
      case ApiErrorCode.redisUnavailable:
        return 'Realtime/cache service is unavailable. Try again.';
      default:
        return e.message;
    }
  }

  void _setStatus(String value) {
    status = value;
    notifyListeners();
  }

  Future<void> _loadSessionData(String id) async {
    sessionId = id;
    state = await client.getGame(id);
    await loadAvailableDiceForCurrentPlayer(quiet: true);
    _syncSelectionAfterStateChange();
  }

  void _syncSelectionAfterStateChange() {
    boardHintMessage = null;
    if (phase == 'NeedActiveSelection') {
      final roll = state?['currentRoll'] as Map<String, dynamic>?;
      availableColorDice = DieFaceCodec.colorFaces(
        roll?['colorDice'],
        unique: true,
      );
      availableNumberDice = DieFaceCodec.numberFaces(
        roll?['numberDice'],
        unique: true,
      );
      selectedColorDie =
          availableColorDice.contains(selectedColorDie)
              ? selectedColorDie
              : (availableColorDice.isNotEmpty
                  ? availableColorDice.first
                  : null);
      selectedNumberDie =
          availableNumberDice.contains(selectedNumberDie)
              ? selectedNumberDie
              : (availableNumberDice.isNotEmpty
                  ? availableNumberDice.first
                  : null);
      selectedCellIds.clear();
    } else if (phase != 'PlayersResolving') {
      selectedCellIds.clear();
      availableColorDice = const [];
      availableNumberDice = const [];
      selectedColorDie = null;
      selectedNumberDie = null;
    }
    _refreshValidationMessage();
  }

  void _refreshValidationMessage() {
    if (!canInteractWithBoard ||
        selectedCellIds.isEmpty ||
        selectedColorDie == null ||
        selectedNumberDie == null) {
      validationMessage = null;
      return;
    }
    final result = currentMoveValidation;
    validationMessage = (result == null || result.ok) ? null : result.reason;
  }

  String hintForBlockedCellTap(String cellId) {
    if (!canInteractWithBoard) {
      return 'You can only mark cells during Players Resolving.';
    }
    if (blockedCellIds.contains(cellId)) {
      final name =
          currentResolvingPlayer?['name']?.toString() ?? 'Current player';
      return '$name already checked this cell.';
    }
    return validationMessage ?? 'That cell is not selectable right now.';
  }

  void showBoardHint(String message) {
    boardHintMessage = message;
    notifyListeners();
  }
}
