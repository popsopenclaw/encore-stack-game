class MoveValidationResult {
  const MoveValidationResult({
    required this.ok,
    this.reason,
    this.jokersUsed = 0,
    this.resolvedCount = 0,
    this.resolvedColor,
  });

  final bool ok;
  final String? reason;
  final int jokersUsed;
  final int resolvedCount;
  final String? resolvedColor;
}

class MoveValidator {
  const MoveValidator._();

  static MoveValidationResult validate({
    required Map<String, dynamic>? state,
    required int? playerIndex,
    required Set<String> selectedCellIds,
    required String? colorDie,
    required String? numberDie,
    required List<String> availableColorDice,
    required List<String> availableNumberDice,
  }) {
    if (state == null) {
      return const MoveValidationResult(
        ok: false,
        reason: 'No game state loaded.',
      );
    }
    if (playerIndex == null || playerIndex < 0) {
      return const MoveValidationResult(
        ok: false,
        reason: 'No active resolving player.',
      );
    }
    if (colorDie == null || numberDie == null) {
      return const MoveValidationResult(
        ok: false,
        reason: 'Select both color and number dice.',
      );
    }
    if (!availableColorDice.contains(colorDie) ||
        !availableNumberDice.contains(numberDie)) {
      return const MoveValidationResult(
        ok: false,
        reason: 'Selected dice are not available.',
      );
    }
    if (selectedCellIds.isEmpty) {
      return const MoveValidationResult(
        ok: false,
        reason: 'Select at least one cell.',
      );
    }

    final boardList =
        (state['board'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((row) => row.map((k, v) => MapEntry('$k', v)))
            .toList();
    final playersList =
        (state['players'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((row) => row.map((k, v) => MapEntry('$k', v)))
            .toList();

    if (playerIndex >= playersList.length) {
      return const MoveValidationResult(
        ok: false,
        reason: 'Resolving player is out of range.',
      );
    }

    final byId = <String, Map<String, dynamic>>{
      for (final c in boardList) (c['id'] ?? '').toString(): c,
    };

    final selectedCells = <Map<String, dynamic>>[];
    for (final id in selectedCellIds) {
      final cell = byId[id];
      if (cell == null) {
        return MoveValidationResult(
          ok: false,
          reason: 'Unknown selected cell: $id',
        );
      }
      selectedCells.add(cell);
    }

    final selectedCount = selectedCells.length;
    final numberValue = _numberFromFace(numberDie);
    final resolvedCount = numberValue == 0 ? selectedCount : numberValue;
    if (resolvedCount < 1 || resolvedCount > 5) {
      return const MoveValidationResult(
        ok: false,
        reason: 'Number die must resolve to 1..5.',
      );
    }
    if (selectedCount != resolvedCount) {
      return const MoveValidationResult(
        ok: false,
        reason: 'Selected cells must match the die count exactly.',
      );
    }

    final colors =
        selectedCells.map((c) => (c['color'] ?? '').toString()).toSet();
    final resolvedColor =
        colorDie == 'Joker'
            ? (colors.length == 1 ? colors.first : null)
            : colorDie;
    if (resolvedColor == null) {
      return const MoveValidationResult(
        ok: false,
        reason: 'Color joker must resolve to exactly one color.',
      );
    }
    if (colors.any((c) => c != resolvedColor)) {
      return const MoveValidationResult(
        ok: false,
        reason: 'All selected cells must be the same color.',
      );
    }

    final player = playersList[playerIndex];
    final checked =
        ((player['checkedCells'] as List<dynamic>? ?? const []))
            .map((e) => '$e')
            .toSet();
    if (selectedCellIds.any(checked.contains)) {
      return const MoveValidationResult(
        ok: false,
        reason: 'Cannot select a cell that is already checked.',
      );
    }

    if (!_isConnected(selectedCells)) {
      return const MoveValidationResult(
        ok: false,
        reason: 'Selected cells must form one orthogonally connected clump.',
      );
    }

    if (checked.isEmpty) {
      final touchesColumnH = selectedCells.any(
        (c) => (c['column'] ?? '').toString() == 'H',
      );
      if (!touchesColumnH) {
        return const MoveValidationResult(
          ok: false,
          reason: 'First move must include at least one cell in column H.',
        );
      }
    } else {
      if (!_touchesExisting(selectedCells, checked, byId)) {
        return const MoveValidationResult(
          ok: false,
          reason: 'Move must touch your existing checks orthogonally.',
        );
      }
    }

    final jokersUsed =
        (colorDie == 'Joker' ? 1 : 0) + (numberDie == 'Joker' ? 1 : 0);
    final jokersRemaining = (player['jokerMarksRemaining'] as int?) ?? 0;
    if (jokersUsed > jokersRemaining) {
      return const MoveValidationResult(
        ok: false,
        reason: 'Not enough exclamation marks for joker usage.',
      );
    }

    return MoveValidationResult(
      ok: true,
      jokersUsed: jokersUsed,
      resolvedCount: resolvedCount,
      resolvedColor: resolvedColor,
    );
  }

  static int _numberFromFace(String die) {
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
        return 0;
      default:
        return -1;
    }
  }

  static bool _isConnected(List<Map<String, dynamic>> cells) {
    if (cells.isEmpty) return false;
    final coordSet =
        cells
            .map((c) => ((c['x'] as int?) ?? -1, (c['y'] as int?) ?? -1))
            .toSet();
    final queue = <(int x, int y)>[coordSet.first];
    final seen = <(int x, int y)>{coordSet.first};
    var i = 0;

    while (i < queue.length) {
      final (x, y) = queue[i++];
      final neighbors = <(int x, int y)>[
        (x + 1, y),
        (x - 1, y),
        (x, y + 1),
        (x, y - 1),
      ];
      for (final n in neighbors) {
        if (coordSet.contains(n) && !seen.contains(n)) {
          seen.add(n);
          queue.add(n);
        }
      }
    }
    return seen.length == coordSet.length;
  }

  static bool _touchesExisting(
    List<Map<String, dynamic>> selectedCells,
    Set<String> checkedIds,
    Map<String, Map<String, dynamic>> boardById,
  ) {
    final existingCoords =
        checkedIds
            .map((id) => boardById[id])
            .whereType<Map<String, dynamic>>()
            .map((c) => ((c['x'] as int?) ?? -1, (c['y'] as int?) ?? -1))
            .toSet();

    for (final c in selectedCells) {
      final x = (c['x'] as int?) ?? -1;
      final y = (c['y'] as int?) ?? -1;
      if (existingCoords.contains((x + 1, y)) ||
          existingCoords.contains((x - 1, y)) ||
          existingCoords.contains((x, y + 1)) ||
          existingCoords.contains((x, y - 1))) {
        return true;
      }
    }

    return false;
  }
}
