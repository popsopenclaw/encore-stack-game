import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class BoardSheet extends StatelessWidget {
  const BoardSheet({super.key, required this.board, required this.colorFor});

  final List<Map<String, dynamic>> board;
  final Color Function(String) colorFor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppPalette.boardFrame,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: AppPalette.boardFrameShadow, blurRadius: 14, offset: Offset(0, 8)),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: BoardGrid(board: board, colorFor: colorFor)),
                    const SizedBox(width: 12),
                    const SideScoreLegend(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const BottomRulesStrip(),
            ],
          ),
        ),
        const Positioned(left: -10, top: 80, child: _FrameNotch()),
        const Positioned(right: -10, top: 80, child: _FrameNotch()),
      ],
    );
  }
}

class _FrameNotch extends StatelessWidget {
  const _FrameNotch();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 64,
      decoration: BoxDecoration(
        color: AppPalette.boardNotch,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class SideScoreLegend extends StatelessWidget {
  const SideScoreLegend({super.key});

  @override
  Widget build(BuildContext context) {
    Widget row(Color c, String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black54)),
            ),
            const SizedBox(width: 6),
            _pill(a),
            const SizedBox(width: 3),
            _pill(b),
          ]),
        );

    return SizedBox(
      width: 136,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          row(AppPalette.tileGreen, '5', '3'),
          row(AppPalette.tileYellow, '5', '3'),
          row(AppPalette.tileBlue, '5', '3'),
          row(AppPalette.tilePurple, '5', '3'),
          row(AppPalette.tileOrange, '5', '3'),
          const SizedBox(height: 8),
          const Text('BONUS =', style: TextStyle(color: AppPalette.white, fontWeight: FontWeight.w700, fontSize: 20)),
          const SizedBox(height: 8),
          const _RuleLine('A-O', '+', Colors.lightGreenAccent),
          const _RuleLine('!', '+1', Colors.lightGreenAccent),
          const _RuleLine('★', '-2', Colors.redAccent),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppPalette.white, borderRadius: BorderRadius.circular(8)),
            child: const Text('TOTAL =', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26)),
          ),
        ],
      ),
    );
  }

  Widget _pill(String t) => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppPalette.white, borderRadius: BorderRadius.circular(6)),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
}

class _RuleLine extends StatelessWidget {
  const _RuleLine(this.label, this.value, this.valueColor);

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(color: AppPalette.white, borderRadius: BorderRadius.circular(8)),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            ),
          ),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w900, fontSize: 26)),
        ],
      ),
    );
  }
}

class BottomRulesStrip extends StatelessWidget {
  const BottomRulesStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppPalette.stripBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _capsule('?'),
          const SizedBox(width: 6),
          _capsule('✖'),
          const SizedBox(width: 6),
          const Text('=', style: TextStyle(color: AppPalette.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          ...List.generate(
            8,
            (i) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _circle('!'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _capsule(String t) => Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppPalette.white, borderRadius: BorderRadius.circular(10)),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
      );

  Widget _circle(String t) => Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppPalette.white, shape: BoxShape.circle),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
      );
}

class BoardGrid extends StatelessWidget {
  const BoardGrid({super.key, required this.board, required this.colorFor});

  final List<Map<String, dynamic>> board;
  final Color Function(String) colorFor;

  @override
  Widget build(BuildContext context) {
    final maxX = board.map((e) => e['x'] as int).reduce((a, b) => a > b ? a : b);
    final maxY = board.map((e) => e['y'] as int).reduce((a, b) => a > b ? a : b);
    final grid = <String, Map<String, dynamic>>{for (final c in board) '${c['x']}_${c['y']}': c};

    const topPts = [5, 3, 3, 3, 2, 2, 2, 1, 2, 2, 2, 3, 3, 3, 5];
    const lowPts = [3, 2, 2, 2, 1, 1, 1, 0, 1, 1, 1, 2, 2, 2, 3];
    const letters = 'ABCDEFGHIJKLMNO';

    Widget pill(String t, {Color? bg, Color? fg}) => Container(
          width: 30,
          height: 26,
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: bg ?? AppPalette.white,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.black26),
          ),
          alignment: Alignment.center,
          child: Text(t, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: fg ?? Colors.black87)),
        );

    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(15, (i) => pill(letters[i], fg: i == 7 ? AppPalette.red : Colors.black87)),
          ),
          ...List.generate(maxY + 1, (y) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(maxX + 1, (x) {
                final c = grid['${x}_$y'];
                if (c == null) return const SizedBox(width: 30, height: 30);
                return Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: colorFor((c['color'] as String)),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: Colors.black38),
                  ),
                  child: (c['starred'] as bool) ? const Icon(Icons.star, size: 16, color: AppPalette.white) : null,
                );
              }),
            );
          }),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(15, (i) => pill('${topPts[i]}', fg: i == 7 ? AppPalette.red : Colors.black87)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(15, (i) => pill('${lowPts[i]}', fg: i == 7 ? AppPalette.red : Colors.black87)),
          ),
        ],
      ),
    );
  }
}
