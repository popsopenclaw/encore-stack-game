import 'dart:convert';

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
  int? _selectedBoardPlayerIndex;

  String get apiBase => backendUrl.text.trim();
  ApiClient get client => ApiClient(baseUrl: apiBase, jwt: jwt);
  String? get currentAccountId => jwt == null ? null : _readSubFromJwt(jwt!);

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
      final body = await client.getOAuthLoginUrl('github');
      await openUrl(body['url'] as String);
    });
  }

  Future<void> exchange() async => _run('OAuth exchange', () async {
    final body = await client.exchangeOAuthCode(
      'github',
      oauthCode.text.trim(),
    );
    jwt = body['accessToken'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kJwtPrefKey, jwt!);
    await authSessionController.markLoggedIn(jwt!);
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
        _selectedBoardPlayerIndex = null;
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

  Future<void> loadScoreAndEvents() async {
    if (sessionId == null) return;
    await _run('Load score/events', () async {
      scores = await client.getScore(sessionId!);
      events = await client.getEvents(sessionId!);
    });
  }

  Future<void> loadAvailableDiceForCurrentPlayer({bool quiet = false}) async {
    if (!canLoadAvailableDice) {
      availableColorDice = const [];
      availableNumberDice = const [];
      selectedColorDie = null;
      selectedNumberDie = null;
      _refreshValidationMessage();
      return;
    }

    Future<void> fn() async {
      final playerIndex = myPlayerIndex!;
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

  void selectPreviousBoard() {
    if (playersState.length < 2) return;
    final current = selectedBoardPlayerIndex ?? 0;
    final next = (current - 1 + playersState.length) % playersState.length;
    _setSelectedBoardPlayerIndex(next);
  }

  void selectNextBoard() {
    if (playersState.length < 2) return;
    final current = selectedBoardPlayerIndex ?? 0;
    final next = (current + 1) % playersState.length;
    _setSelectedBoardPlayerIndex(next);
  }

  void toggleCellSelection(String cellId) {
    if (!canInteractWithBoard) return;
    if (blockedCellIds.contains(cellId)) return;
    if (!selectedCellIds.contains(cellId) &&
        !reachableCellIds.contains(cellId)) {
      return;
    }
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
      final idx = myPlayerIndex!;
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

  List<Map<String, dynamic>> get playersState =>
      ((state?['players'] as List<dynamic>?) ?? const [])
          .whereType<Map>()
          .map((row) => row.map((k, v) => MapEntry('$k', v)))
          .toList();

  int? get myPlayerIndex {
    final accountId = currentAccountId;
    if (accountId == null || accountId.isEmpty) return null;
    for (var i = 0; i < playersState.length; i++) {
      if ((playersState[i]['accountId']?.toString() ?? '') == accountId) {
        return i;
      }
    }
    return null;
  }

  int? get selectedBoardPlayerIndex {
    final idx =
        _selectedBoardPlayerIndex ??
        myPlayerIndex ??
        (playersState.isEmpty ? null : 0);
    if (idx == null || idx < 0 || idx >= playersState.length) return null;
    return idx;
  }

  Map<String, dynamic>? get selectedBoardPlayer {
    final idx = selectedBoardPlayerIndex;
    if (idx == null) return null;
    return playersState[idx];
  }

  String get selectedBoardPlayerName {
    final idx = selectedBoardPlayerIndex;
    final player = selectedBoardPlayer;
    return player?['name']?.toString() ??
        (idx == null ? 'Player' : 'P${idx + 1}');
  }

  String get turnPlayerName {
    final idx = (state?['activePlayerIndex'] as int?) ?? 0;
    if (idx < 0 || idx >= playersState.length) return '-';
    final player = playersState[idx];
    return player['name']?.toString() ?? 'P${idx + 1}';
  }

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

  bool get isViewingOwnBoard =>
      selectedBoardPlayerIndex != null &&
      myPlayerIndex != null &&
      selectedBoardPlayerIndex == myPlayerIndex;

  bool get isActiveTurnOwner =>
      sessionId != null &&
      myPlayerIndex != null &&
      phase == 'NeedRoll' &&
      (state?['activePlayerIndex'] as int?) == myPlayerIndex;

  bool get isActiveSelectionOwner =>
      sessionId != null &&
      myPlayerIndex != null &&
      phase == 'NeedActiveSelection' &&
      (state?['activePlayerIndex'] as int?) == myPlayerIndex;

  bool get isAwaitingMyMove =>
      sessionId != null &&
      myPlayerIndex != null &&
      phase == 'PlayersResolving' &&
      currentResolvingPlayerIndex == myPlayerIndex;

  bool get canPickDice => isActiveSelectionOwner || isAwaitingMyMove;
  bool get canRoll => isActiveTurnOwner;
  bool get canActivePass => isActiveSelectionOwner;
  bool get canSubmitActiveSelection =>
      isActiveSelectionOwner &&
      selectedColorDie != null &&
      selectedNumberDie != null;
  bool get canLoadAvailableDice => isAwaitingMyMove;
  bool get canInteractWithBoard => isViewingOwnBoard && isAwaitingMyMove;

  bool get canSubmitMove =>
      canInteractWithBoard &&
      selectedColorDie != null &&
      selectedNumberDie != null &&
      selectedCellIds.isNotEmpty &&
      (currentMoveValidation?.ok ?? false);

  Set<String> get displayedCheckedCellIds =>
      ((selectedBoardPlayer?['checkedCells'] as List<dynamic>?) ?? const [])
          .map((e) => '$e')
          .toSet();

  Set<String> get boardSelectedCellIds =>
      isViewingOwnBoard ? selectedCellIds : <String>{};

  Set<String> get blockedCellIds =>
      isViewingOwnBoard ? displayedCheckedCellIds : <String>{};

  Set<String> get reachableCellIds {
    if (!canInteractWithBoard) return {};
    final board =
        (state?['board'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((row) => row.map((k, v) => MapEntry('$k', v)))
            .toList();
    if (board.isEmpty) return {};

    final checked = displayedCheckedCellIds;
    final byId = <String, Map<String, dynamic>>{
      for (final cell in board) _cellId(cell): cell,
    };
    final selectedCells =
        selectedCellIds
            .map((id) => byId[id])
            .whereType<Map<String, dynamic>>()
            .toList();

    if (!_selectionCanExpand(
      selectedCells: selectedCells,
      checkedIds: checked,
      boardById: byId,
    )) {
      return Set<String>.from(selectedCellIds);
    }

    final maxSelectableCount = _maxSelectableCountForDie(selectedNumberDie);
    if (maxSelectableCount != null &&
        selectedCellIds.length >= maxSelectableCount) {
      return Set<String>.from(selectedCellIds);
    }

    final candidateIds =
        checked.isEmpty && selectedCellIds.isEmpty
            ? board
                .where((cell) => (cell['column'] ?? '').toString() == 'H')
                .map(_cellId)
                .where((id) => !checked.contains(id))
                .toSet()
            : _adjacentUncheckedCellIds(
              board: board,
              checkedIds: checked,
              selectedIds: selectedCellIds,
            );

    final reachable = Set<String>.from(selectedCellIds);
    for (final id in candidateIds) {
      final cell = byId[id];
      if (cell == null || selectedCellIds.contains(id)) continue;
      if (_cellMatchesCurrentMove(cell, selectedCells)) {
        reachable.add(id);
      }
    }
    return reachable;
  }

  Set<String> _adjacentUncheckedCellIds({
    required List<Map<String, dynamic>> board,
    required Set<String> checkedIds,
    required Set<String> selectedIds,
  }) {
    final byCoord = <(int, int), String>{};
    for (final cell in board) {
      byCoord[(_cellX(cell), _cellY(cell))] = _cellId(cell);
    }

    final frontier = <(int, int)>{};
    for (final cell in board) {
      final id = _cellId(cell);
      if (checkedIds.contains(id) || selectedIds.contains(id)) {
        frontier.add((_cellX(cell), _cellY(cell)));
      }
    }

    final reachable = <String>{};
    for (final (x, y) in frontier) {
      for (final n in [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]) {
        final id = byCoord[n];
        if (id == null || checkedIds.contains(id) || selectedIds.contains(id)) {
          continue;
        }
        reachable.add(id);
      }
    }
    return reachable;
  }

  bool _selectionCanExpand({
    required List<Map<String, dynamic>> selectedCells,
    required Set<String> checkedIds,
    required Map<String, Map<String, dynamic>> boardById,
  }) {
    if (selectedCells.isEmpty) return true;
    if (!_isConnected(selectedCells)) return false;
    if (_hasColorConflict(selectedCells)) return false;
    if (checkedIds.isEmpty) {
      return selectedCells.any(
        (cell) => (cell['column'] ?? '').toString() == 'H',
      );
    }
    return _touchesExisting(selectedCells, checkedIds, boardById);
  }

  bool _cellMatchesCurrentMove(
    Map<String, dynamic> cell,
    List<Map<String, dynamic>> selectedCells,
  ) {
    if (selectedColorDie == null) return true;

    final cellColor = (cell['color'] ?? '').toString();
    if (selectedColorDie != 'Joker') {
      return cellColor == selectedColorDie;
    }

    final colors =
        selectedCells
            .map((selected) => (selected['color'] ?? '').toString())
            .toSet();
    if (colors.isEmpty) return true;
    if (colors.length > 1) return false;
    return cellColor == colors.first;
  }

  bool _hasColorConflict(List<Map<String, dynamic>> selectedCells) {
    if (selectedColorDie == null || selectedCells.isEmpty) return false;

    final colors =
        selectedCells.map((cell) => (cell['color'] ?? '').toString()).toSet();
    if (selectedColorDie == 'Joker') return colors.length > 1;
    return colors.any((color) => color != selectedColorDie);
  }

  int? _maxSelectableCountForDie(String? die) {
    switch (die) {
      case 'One':
        return 1;
      case 'Two':
        return 2;
      case 'Three':
        return 3;
      case 'Four':
        return 4;
      case 'Five':
        return 5;
      case 'Joker':
        return 5;
      default:
        return null;
    }
  }

  bool _isConnected(List<Map<String, dynamic>> cells) {
    if (cells.isEmpty) return false;

    final coordSet = cells.map((cell) => (_cellX(cell), _cellY(cell))).toSet();
    final queue = <(int, int)>[coordSet.first];
    final seen = <(int, int)>{coordSet.first};
    var i = 0;

    while (i < queue.length) {
      final (x, y) = queue[i++];
      for (final n in [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]) {
        if (coordSet.contains(n) && !seen.contains(n)) {
          seen.add(n);
          queue.add(n);
        }
      }
    }

    return seen.length == coordSet.length;
  }

  bool _touchesExisting(
    List<Map<String, dynamic>> selectedCells,
    Set<String> checkedIds,
    Map<String, Map<String, dynamic>> boardById,
  ) {
    final existingCoords =
        checkedIds
            .map((id) => boardById[id])
            .whereType<Map<String, dynamic>>()
            .map((cell) => (_cellX(cell), _cellY(cell)))
            .toSet();

    for (final cell in selectedCells) {
      final x = _cellX(cell);
      final y = _cellY(cell);
      for (final n in [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]) {
        if (existingCoords.contains(n)) {
          return true;
        }
      }
    }

    return false;
  }

  String _cellId(Map<String, dynamic> cell) => (cell['id'] ?? '').toString();

  int _cellX(Map<String, dynamic> cell) => (cell['x'] as int?) ?? -1;

  int _cellY(Map<String, dynamic> cell) => (cell['y'] as int?) ?? -1;

  MoveValidationResult? get currentMoveValidation {
    if (!canInteractWithBoard) return null;
    return MoveValidator.validate(
      state: state,
      playerIndex: myPlayerIndex,
      selectedCellIds: selectedCellIds,
      colorDie: selectedColorDie,
      numberDie: selectedNumberDie,
      availableColorDice: availableColorDice,
      availableNumberDice: availableNumberDice,
    );
  }

  String? get boardInteractionHint {
    if (boardHintMessage != null && boardHintMessage!.isNotEmpty) {
      return boardHintMessage;
    }
    if (playersState.isEmpty) return null;
    if (!isViewingOwnBoard) return 'Viewing $selectedBoardPlayerName\'s board.';
    if (phase != 'PlayersResolving') {
      return 'Viewing your board. It becomes interactive during Players Resolving.';
    }
    if (!isAwaitingMyMove) {
      return 'Viewing your board. Wait for your resolve turn.';
    }
    return validationMessage;
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
    _syncSelectedBoardAfterStateChange();

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
    } else if (phase == 'PlayersResolving') {
      if (!canLoadAvailableDice) {
        availableColorDice = const [];
        availableNumberDice = const [];
        selectedColorDie = null;
        selectedNumberDie = null;
      }
      if (!canInteractWithBoard) {
        selectedCellIds.clear();
      }
    } else {
      selectedCellIds.clear();
      availableColorDice = const [];
      availableNumberDice = const [];
      selectedColorDie = null;
      selectedNumberDie = null;
    }
    _refreshValidationMessage();
  }

  void _syncSelectedBoardAfterStateChange() {
    if (playersState.isEmpty) {
      _selectedBoardPlayerIndex = null;
      return;
    }

    if (_selectedBoardPlayerIndex != null &&
        _selectedBoardPlayerIndex! >= 0 &&
        _selectedBoardPlayerIndex! < playersState.length) {
      return;
    }

    _selectedBoardPlayerIndex = myPlayerIndex ?? 0;
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

  void _setSelectedBoardPlayerIndex(int nextIndex) {
    if (nextIndex < 0 || nextIndex >= playersState.length) return;
    _selectedBoardPlayerIndex = nextIndex;
    boardHintMessage = null;
    notifyListeners();
  }

  String hintForBlockedCellTap(String cellId) {
    if (!isViewingOwnBoard) {
      return 'You can only play on your own board.';
    }
    if (phase != 'PlayersResolving') {
      return 'You can only mark cells during Players Resolving.';
    }
    if (!isAwaitingMyMove) {
      return 'It is not your resolve turn.';
    }
    if (blockedCellIds.contains(cellId)) {
      return 'You already checked this cell.';
    }
    return validationMessage ?? 'That cell is not selectable right now.';
  }

  void showBoardHint(String message) {
    boardHintMessage = message;
    notifyListeners();
  }

  String? _readSubFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return map['sub']?.toString();
    } catch (_) {
      return null;
    }
  }
}
