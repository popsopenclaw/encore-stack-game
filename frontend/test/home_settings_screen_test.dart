import 'package:encore_frontend/app/router.dart';
import 'package:encore_frontend/config/backend_config.dart';
import 'package:encore_frontend/screens/create_lobby_screen.dart';
import 'package:encore_frontend/screens/home_screen.dart';
import 'package:encore_frontend/screens/join_lobby_screen.dart';
import 'package:encore_frontend/screens/login_screen.dart';
import 'package:encore_frontend/screens/settings_screen.dart';
import 'package:encore_frontend/services/lobby_realtime_service.dart';
import 'package:encore_frontend/state/auth_session_controller.dart';
import 'package:encore_frontend/state/lobby_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    authSessionController.resetForTest();
    lobbyController.lobbyCode = null;
    lobbyController.lobbyName = '';
    lobbyController.activeSessionId = null;
    lobbyController.hasActiveGame = false;
    lobbyController.realtimeStatus = RealtimeStatus.disconnected;
    lobbyController.lobbies = const [];
    lobbyController.members = const [];
    lobbyController.readyByAccountId.clear();
  });

  testWidgets('home screen hides realtime status and resume game', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {AppRoutes.home: (_) => const HomeScreen()},
        initialRoute: AppRoutes.home,
      ),
    );
    await tester.pump();

    expect(find.text('Realtime status'), findsNothing);
    expect(find.text('Resume Game'), findsNothing);
    expect(find.text('Create Lobby'), findsOneWidget);
    expect(find.text('Join Lobby'), findsOneWidget);
  });

  testWidgets('open lobby routes to active game when lobby already started', (
    tester,
  ) async {
    lobbyController.lobbyCode = 'ABC123';
    lobbyController.lobbyName = 'Friday Match';
    lobbyController.activeSessionId = 'session-42';
    lobbyController.hasActiveGame = true;

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.home: (_) => const HomeScreen(),
          AppRoutes.game: (_) => const Scaffold(body: Text('Game Destination')),
          AppRoutes.lobbyRoom:
              (_) => const Scaffold(body: Text('Lobby Destination')),
        },
        initialRoute: AppRoutes.home,
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Open Lobby'));
    await tester.pumpAndSettle();

    expect(find.text('Game Destination'), findsOneWidget);
    expect(find.text('Lobby Destination'), findsNothing);
  });

  testWidgets('settings screen shows realtime status', (tester) async {
    lobbyController.realtimeStatus = RealtimeStatus.connected;

    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pump();

    expect(find.text('Realtime status'), findsOneWidget);
    expect(find.text('connected'), findsOneWidget);
  });

  testWidgets('lobby create and join screens no longer ask for display names', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CreateLobbyScreen())),
    );
    await tester.pump();
    expect(find.text('Your display name'), findsNothing);
    expect(find.textContaining('saved player name'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: JoinLobbyScreen())),
    );
    await tester.pump();
    expect(find.text('Display name'), findsNothing);
    expect(find.textContaining('saved player name'), findsOneWidget);
  });

  testWidgets('router redirects unauthenticated create-lobby route to login', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({kJwtPrefKey: 'stale.jwt.token'});
    authSessionController.setSessionValidator((jwt, backendUrl) async => false);

    await tester.pumpWidget(
      MaterialApp(
        routes: AppRouter.routes,
        initialRoute: AppRoutes.createLobby,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Create Lobby'), findsNothing);
  });

  testWidgets('router redirects unauthenticated join-lobby route to login', (
    tester,
  ) async {
    authSessionController.setSessionValidator((jwt, backendUrl) async => false);

    await tester.pumpWidget(
      MaterialApp(routes: AppRouter.routes, initialRoute: AppRoutes.joinLobby),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Join Lobby'), findsNothing);
  });
}
