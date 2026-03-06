import 'package:encore_frontend/state/move_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoveValidator', () {
    test('first move must include column H', () {
      final result = MoveValidator.validate(
        state: _state(),
        playerIndex: 0,
        selectedCellIds: {'c2'},
        colorDie: 'Yellow',
        numberDie: 'One',
        availableColorDice: const ['Yellow', 'Blue'],
        availableNumberDice: const ['One', 'Two'],
      );

      expect(result.ok, false);
      expect(result.reason, contains('column H'));
    });

    test('selected count must match number die', () {
      final result = MoveValidator.validate(
        state: _state(),
        playerIndex: 0,
        selectedCellIds: {'c1'},
        colorDie: 'Yellow',
        numberDie: 'Two',
        availableColorDice: const ['Yellow'],
        availableNumberDice: const ['Two'],
      );

      expect(result.ok, false);
      expect(result.reason, contains('match the die count'));
    });

    test('number joker cannot resolve to six', () {
      final result = MoveValidator.validate(
        state: _state(),
        playerIndex: 0,
        selectedCellIds: {'c1', 'c2', 'c4', 'c5', 'c8', 'c9'},
        colorDie: 'Yellow',
        numberDie: 'Joker',
        availableColorDice: const ['Yellow'],
        availableNumberDice: const ['Joker'],
      );

      expect(result.ok, false);
      expect(result.reason, contains('1..5'));
    });

    test('move must keep one color', () {
      final result = MoveValidator.validate(
        state: _state(),
        playerIndex: 0,
        selectedCellIds: {'c1', 'c3'},
        colorDie: 'Yellow',
        numberDie: 'Two',
        availableColorDice: const ['Yellow'],
        availableNumberDice: const ['Two'],
      );

      expect(result.ok, false);
      expect(result.reason, contains('same color'));
    });

    test('move must be one connected clump', () {
      final result = MoveValidator.validate(
        state: _state(),
        playerIndex: 0,
        selectedCellIds: {'c1', 'c9'},
        colorDie: 'Yellow',
        numberDie: 'Two',
        availableColorDice: const ['Yellow'],
        availableNumberDice: const ['Two'],
      );

      expect(result.ok, false);
      expect(result.reason, contains('connected clump'));
    });

    test('later moves must touch existing checks orthogonally', () {
      final result = MoveValidator.validate(
        state: _state(playerChecked: ['c1']),
        playerIndex: 0,
        selectedCellIds: {'c5'},
        colorDie: 'Yellow',
        numberDie: 'One',
        availableColorDice: const ['Yellow'],
        availableNumberDice: const ['One'],
      );

      expect(result.ok, false);
      expect(result.reason, contains('orthogonally'));
    });

    test('joker usage requires remaining exclamation marks', () {
      final result = MoveValidator.validate(
        state: _state(jokers: 0),
        playerIndex: 0,
        selectedCellIds: {'c1'},
        colorDie: 'Joker',
        numberDie: 'One',
        availableColorDice: const ['Joker'],
        availableNumberDice: const ['One'],
      );

      expect(result.ok, false);
      expect(result.reason, contains('exclamation'));
    });

    test('valid move passes and returns resolved metadata', () {
      final result = MoveValidator.validate(
        state: _state(),
        playerIndex: 0,
        selectedCellIds: {'c1', 'c4'},
        colorDie: 'Yellow',
        numberDie: 'Two',
        availableColorDice: const ['Yellow'],
        availableNumberDice: const ['Two'],
      );

      expect(result.ok, true);
      expect(result.resolvedCount, 2);
      expect(result.resolvedColor, 'Yellow');
      expect(result.jokersUsed, 0);
    });
  });
}

Map<String, dynamic> _state({
  List<String> playerChecked = const [],
  int jokers = 8,
}) {
  return {
    'board': _board(),
    'players': [
      {
        'name': 'A',
        'checkedCells': playerChecked,
        'jokerMarksRemaining': jokers,
      },
    ],
  };
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
  {
    'id': 'c5',
    'x': 1,
    'y': 1,
    'column': 'I',
    'color': 'Yellow',
    'starred': false,
  },
  {
    'id': 'c6',
    'x': 2,
    'y': 1,
    'column': 'J',
    'color': 'Blue',
    'starred': false,
  },
  {
    'id': 'c7',
    'x': 0,
    'y': 2,
    'column': 'H',
    'color': 'Green',
    'starred': false,
  },
  {
    'id': 'c8',
    'x': 1,
    'y': 2,
    'column': 'I',
    'color': 'Yellow',
    'starred': false,
  },
  {
    'id': 'c9',
    'x': 2,
    'y': 2,
    'column': 'J',
    'color': 'Yellow',
    'starred': false,
  },
];
