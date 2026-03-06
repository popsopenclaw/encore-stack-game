import 'package:encore_frontend/state/die_face_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DieFaceCodec', () {
    test(
      'normalizes color die faces from ints, numeric strings, and names',
      () {
        final result = DieFaceCodec.colorFaces([1, '2', 'joker', 'Blue']);
        expect(result, ['Orange', 'Blue', 'Joker', 'Blue']);
      },
    );

    test(
      'normalizes number die faces from ints, numeric strings, and names',
      () {
        final result = DieFaceCodec.numberFaces([4, '0', 'two', 'Five']);
        expect(result, ['Four', 'Joker', 'Two', 'Five']);
      },
    );

    test(
      'filters unknown values and preserves unique order when requested',
      () {
        final result = DieFaceCodec.numberFaces([
          4,
          '4',
          'bogus',
          2,
        ], unique: true);
        expect(result, ['Four', 'Two']);
      },
    );
  });
}
