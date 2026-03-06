import 'package:encore_frontend/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameController rule flow', () {
    test(
      'resolving player index advances from active through unresolved players',
      () {
        final controller = GameController();
        controller.sessionId = 's1';
        controller.state = {
          'phase': 'PlayersResolving',
          'activePlayerIndex': 1,
          'resolvedPlayers': [1],
          'players': [
            {
              'name': 'A',
              'checkedCells': ['c1'],
              'jokerMarksRemaining': 8,
            },
            {
              'name': 'B',
              'checkedCells': ['c2'],
              'jokerMarksRemaining': 8,
            },
            {
              'name': 'C',
              'checkedCells': ['c3'],
              'jokerMarksRemaining': 7,
            },
          ],
          'board': _board(),
        };

        expect(controller.currentResolvingPlayerIndex, 2);
        expect(controller.currentResolvingPlayerJokers, 7);
        expect(controller.blockedCellIds, {'c3'});
      },
    );

    test('submit gate blocks invalid opening move outside column H', () {
      final controller = GameController();
      controller.sessionId = 's1';
      controller.state = {
        'phase': 'PlayersResolving',
        'activePlayerIndex': 0,
        'resolvedPlayers': <int>[],
        'players': [
          {'name': 'A', 'checkedCells': <String>[], 'jokerMarksRemaining': 8},
        ],
        'board': _board(),
      };
      controller.availableColorDice = const ['Yellow'];
      controller.availableNumberDice = const ['One'];
      controller.selectedColorDie = 'Yellow';
      controller.selectedNumberDie = 'One';
      controller.selectedCellIds.add('c2');

      expect(controller.currentMoveValidation?.ok, false);
      expect(controller.canSubmitMove, false);
    });

    test('submit gate allows valid opening move in column H', () {
      final controller = GameController();
      controller.sessionId = 's1';
      controller.state = {
        'phase': 'PlayersResolving',
        'activePlayerIndex': 0,
        'resolvedPlayers': <int>[],
        'players': [
          {'name': 'A', 'checkedCells': <String>[], 'jokerMarksRemaining': 8},
        ],
        'board': _board(),
      };
      controller.availableColorDice = const ['Yellow'];
      controller.availableNumberDice = const ['One'];
      controller.selectedColorDie = 'Yellow';
      controller.selectedNumberDie = 'One';
      controller.selectedCellIds.add('c1');

      expect(controller.currentMoveValidation?.ok, true);
      expect(controller.canSubmitMove, true);
    });
  });
}

List<Map<String, dynamic>> _board() => const [
  {
    'id': 'c1',
    'x': 0,
    'y': 0,
    'column': 'H',
    'color': 'Yellow',
    'starred': false,
  },
  {
    'id': 'c2',
    'x': 1,
    'y': 0,
    'column': 'I',
    'color': 'Yellow',
    'starred': false,
  },
  {
    'id': 'c3',
    'x': 2,
    'y': 0,
    'column': 'J',
    'color': 'Blue',
    'starred': false,
  },
  {
    'id': 'c4',
    'x': 0,
    'y': 1,
    'column': 'H',
    'color': 'Yellow',
    'starred': false,
  },
];
