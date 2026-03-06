class DieFaceCodec {
  const DieFaceCodec._();

  static const List<String> _colorByIndex = <String>[
    'Yellow',
    'Orange',
    'Blue',
    'Green',
    'Purple',
    'Joker',
  ];

  static const List<String> _numberByIndex = <String>[
    'Joker',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
  ];

  static const Map<String, String> _colorByLower = <String, String>{
    'yellow': 'Yellow',
    'orange': 'Orange',
    'blue': 'Blue',
    'green': 'Green',
    'purple': 'Purple',
    'joker': 'Joker',
  };

  static const Map<String, String> _numberByLower = <String, String>{
    'one': 'One',
    'two': 'Two',
    'three': 'Three',
    'four': 'Four',
    'five': 'Five',
    'joker': 'Joker',
  };

  static String? colorFace(dynamic raw) =>
      _canonical(raw, byIndex: _colorByIndex, byLower: _colorByLower);

  static String? numberFace(dynamic raw) =>
      _canonical(raw, byIndex: _numberByIndex, byLower: _numberByLower);

  static List<String> colorFaces(dynamic rawFaces, {bool unique = false}) =>
      _faces(rawFaces, colorFace, unique: unique);

  static List<String> numberFaces(dynamic rawFaces, {bool unique = false}) =>
      _faces(rawFaces, numberFace, unique: unique);

  static List<String> _faces(
    dynamic rawFaces,
    String? Function(dynamic raw) mapper, {
    required bool unique,
  }) {
    final list = (rawFaces as List<dynamic>?) ?? const <dynamic>[];
    final out = <String>[];
    final seen = <String>{};
    for (final raw in list) {
      final mapped = mapper(raw);
      if (mapped == null) continue;
      if (!unique || seen.add(mapped)) out.add(mapped);
    }
    return out;
  }

  static String? _canonical(
    dynamic raw, {
    required List<String> byIndex,
    required Map<String, String> byLower,
  }) {
    final intValue = _asInt(raw);
    if (intValue != null && intValue >= 0 && intValue < byIndex.length) {
      return byIndex[intValue];
    }
    final text = raw?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return byLower[text.toLowerCase()];
  }

  static int? _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) {
      final value = raw.toInt();
      return value == raw ? value : null;
    }
    if (raw is String) return int.tryParse(raw.trim());
    return null;
  }
}
