import 'dart:convert';

import 'package:encore_frontend/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameController reachable cells', () {
    test('opening move only highlights playable H anchors for fixed color', () {
      final controller = _controller(colorDie: 'Yellow', numberDie: 'Three');

      expect(controller.reachableCellIds, {'c1'});
    });

    test('opening move expands beyond H after selecting an H anchor', () {
      final controller = _controller(colorDie: 'Yellow', numberDie: 'Three');
      controller.selectedCellIds.add('c1');

      expect(controller.reachableCellIds, {'c1', 'c2'});
    });

    test('opening move keeps expanding across connected yellows', () {
      final controller = _controller(colorDie: 'Yellow', numberDie: 'Three');
      controller.selectedCellIds.addAll({'c1', 'c2'});

      expect(controller.reachableCellIds, {'c1', 'c2', 'c3', 'c5'});
    });

    test('reachable cells stop expanding after the die count is met', () {
      final controller = _controller(colorDie: 'Yellow', numberDie: 'Two');
      controller.selectedCellIds.addAll({'c1', 'c2'});

      expect(controller.reachableCellIds, {'c1', 'c2'});
    });

    test('color joker locks future candidates to the selected color', () {
      final controller = _controller(colorDie: 'Joker', numberDie: 'Three');
      controller.selectedCellIds.add('c1');

      expect(controller.reachableCellIds, {'c1', 'c2'});
    });

    test('toggleCellSelection ignores non-reachable cells', () {
      final controller = _controller(colorDie: 'Yellow', numberDie: 'Three');

      controller.toggleCellSelection('c2');

      expect(controller.selectedCellIds, isEmpty);
      expect(controller.reachableCellIds, {'c1'});
    });
  });
}

GameController _controller({
  required String colorDie,
  required String numberDie,
}) {
  final controller = GameController();
  controller.jwt = _jwtWithSub('11111111-1111-1111-1111-111111111111');
  controller.sessionId = 's1';
  controller.state = {
    'phase': 'PlayersResolving',
    'activePlayerIndex': 0,
    'resolvedPlayers': <int>[],
    'players': [
      {
        'accountId': '11111111-1111-1111-1111-111111111111',
        'name': 'A',
        'checkedCells': <String>[],
        'jokerMarksRemaining': 8,
      },
    ],
    'board': _board(),
  };
  controller.availableColorDice = [colorDie];
  controller.availableNumberDice = [numberDie];
  controller.selectedColorDie = colorDie;
  controller.selectedNumberDie = numberDie;
  return controller;
}

String _jwtWithSub(String sub) {
  final payload = base64Url.encode(utf8.encode(jsonEncode({'sub': sub})));
  return 'header.$payload.signature';
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
    'color': 'Yellow',
    'starred': false,
  },
  {
    'id': 'c4',
    'x': 0,
    'y': 1,
    'column': 'H',
    'color': 'Green',
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
];
