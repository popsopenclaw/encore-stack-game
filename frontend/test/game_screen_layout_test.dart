import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encore_frontend/config/backend_config.dart';
import 'package:encore_frontend/screens/game_screen.dart';
import 'package:encore_frontend/widgets/board_sheet.dart';
import 'package:encore_frontend/widgets/match_hud_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameScreen layout', () {
    setUp(() {
      HttpOverrides.global = _FakeHttpOverrides(_responseFor);
    });

    tearDown(() {
      HttpOverrides.global = null;
    });

    testWidgets(
      'wide layout places controls beside the board and opens audit sheet',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          kBackendPrefKey: 'http://encore.test',
          kJwtPrefKey: 'jwt-token',
        });

        await _pumpGameScreen(tester, size: const Size(1400, 1000));
        await tester.pumpAndSettle();

        final boardRect = tester.getRect(find.byType(BoardSheet));
        final controlsRect = tester.getRect(find.byType(MatchHudPanel));

        expect(find.byType(MatchHudPanel), findsOneWidget);
        expect(find.text('Open Scores / Timeline'), findsOneWidget);
        expect(
          find.text('Scoreboard loads after opening timeline.'),
          findsNothing,
        );
        expect(controlsRect.left, greaterThan(boardRect.right - 24));
        expect((controlsRect.top - boardRect.top).abs(), lessThan(24));

        await tester.tap(find.text('Open Scores / Timeline'));
        await tester.pumpAndSettle();

        expect(find.text('Match Log'), findsOneWidget);
        expect(find.text('Timeline'), findsOneWidget);
        expect(find.text('Info'), findsOneWidget);
      },
    );

    testWidgets('narrow layout stacks controls beneath the board', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        kBackendPrefKey: 'http://encore.test',
        kJwtPrefKey: 'jwt-token',
      });

      await _pumpGameScreen(tester, size: const Size(900, 1000));
      await tester.pumpAndSettle();

      final boardRect = tester.getRect(find.byType(BoardSheet));
      final controlsRect = tester.getRect(find.byType(MatchHudPanel));

      expect(find.byType(MatchHudPanel), findsOneWidget);
      expect(find.text('Open Scores / Timeline'), findsOneWidget);
      expect(
        find.text('Scoreboard loads after opening timeline.'),
        findsNothing,
      );
      expect(controlsRect.top, greaterThan(boardRect.bottom - 24));
    });
  });
}

Future<void> _pumpGameScreen(WidgetTester tester, {required Size size}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    const MaterialApp(onGenerateRoute: _buildGameRoute, initialRoute: '/game'),
  );
}

Route<dynamic> _buildGameRoute(RouteSettings settings) {
  return MaterialPageRoute<void>(
    settings: const RouteSettings(name: '/game', arguments: 'session01'),
    builder: (_) => const GameScreen(),
  );
}

_FakeResponse _responseFor(String method, Uri uri, List<int> bodyBytes) {
  if (method == 'GET' && uri.path == '/api/gameplay/session01') {
    return _FakeResponse.ok({
      'sessionId': 'session01',
      'phase': 'NeedActiveSelection',
      'activePlayerIndex': 0,
      'players': [
        {
          'name': 'PopAndBoom',
          'checkedCells': const [],
          'jokerMarksRemaining': 8,
        },
      ],
      'board': [
        {'id': 'c1', 'x': 0, 'y': 0, 'color': 'Green', 'starred': false},
      ],
      'currentRoll': {
        'colorDice': [0, 1, 2],
        'numberDice': [0, 1, 2],
      },
    });
  }

  if (method == 'GET' && uri.path == '/api/gameplay/session01/score') {
    return _FakeResponse.ok([
      {
        'player': 'PopAndBoom',
        'columns': 1,
        'colors': 1,
        'jokerBonus': 0,
        'starPenalty': 0,
        'rank': 1,
        'tiebreakExclamationMarks': 0,
        'isWinner': true,
        'total': 6,
      },
    ]);
  }

  if (method == 'GET' && uri.path == '/api/gameplay/session01/events') {
    return _FakeResponse.ok([
      {
        'turn': 1,
        'type': 'game_started',
        'playerIndex': 0,
        'data': 'Match opened',
      },
    ]);
  }

  return _FakeResponse.notFound({
    'code': 'not_found',
    'message': 'Unhandled path: ${uri.path}',
  });
}

class _FakeHttpOverrides extends HttpOverrides {
  _FakeHttpOverrides(this._resolver);

  final _ResponseResolver _resolver;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient(_resolver);
  }
}

typedef _ResponseResolver =
    _FakeResponse Function(String method, Uri uri, List<int> bodyBytes);

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this._resolver);

  final _ResponseResolver _resolver;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _FakeHttpClientRequest(method, url, _resolver);
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest(this.method, this.uri, this._resolver);

  @override
  final String method;
  @override
  final Uri uri;
  final _ResponseResolver _resolver;
  final BytesBuilder _body = BytesBuilder();

  @override
  final headers = _FakeHttpHeaders();

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = -1;

  @override
  bool persistentConnection = true;

  @override
  Encoding encoding = utf8;

  @override
  void add(List<int> data) {
    _body.add(data);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      _body.add(chunk);
    }
  }

  @override
  void write(Object? object) {
    add(encoding.encode('$object'));
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {
    write(objects.join(separator));
  }

  @override
  void writeln([Object? object = '']) {
    write('$object\n');
  }

  @override
  void writeCharCode(int charCode) {
    write(String.fromCharCode(charCode));
  }

  @override
  Future<HttpClientResponse> close() async {
    final response = _resolver(method, uri, _body.takeBytes());
    return _FakeHttpClientResponse(response);
  }

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse(this._response)
    : _bytes = utf8.encode(jsonEncode(_response.body));

  final _FakeResponse _response;
  final List<int> _bytes;

  @override
  int get statusCode => _response.statusCode;

  @override
  int get contentLength => _bytes.length;

  @override
  bool get persistentConnection => false;

  @override
  bool get isRedirect => false;

  @override
  String get reasonPhrase => _response.reasonPhrase;

  @override
  final headers = _FakeHttpHeaders.json();

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  List<Cookie> get cookies => const [];

  @override
  Future<Socket> detachSocket() {
    throw UnimplementedError();
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_bytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  _FakeHttpHeaders() : _values = <String, List<String>>{};

  _FakeHttpHeaders.json()
    : _values = <String, List<String>>{
        HttpHeaders.contentTypeHeader: <String>['application/json'],
      };

  final Map<String, List<String>> _values;

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name.toLowerCase()] = <String>['$value'];
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _values.forEach(action);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeResponse {
  const _FakeResponse(this.statusCode, this.reasonPhrase, this.body);

  factory _FakeResponse.ok(Object body) => _FakeResponse(200, 'OK', body);

  factory _FakeResponse.notFound(Object body) =>
      _FakeResponse(404, 'Not Found', body);

  final int statusCode;
  final String reasonPhrase;
  final Object body;
}
