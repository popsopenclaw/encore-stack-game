import 'package:encore_frontend/app/router.dart';
import 'package:encore_frontend/screens/create_lobby_screen.dart';
import 'package:encore_frontend/screens/game_screen.dart';
import 'package:encore_frontend/screens/home_screen.dart';
import 'package:encore_frontend/screens/join_lobby_screen.dart';
import 'package:encore_frontend/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navigation flow: login -> home -> create/join routes are reachable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.home: (_) => const HomeScreen(),
          AppRoutes.createLobby: (_) => const CreateLobbyScreen(),
          AppRoutes.joinLobby: (_) => const JoinLobbyScreen(),
          AppRoutes.game: (_) => const GameScreen(),
        },
        initialRoute: AppRoutes.login,
      ),
    );

    expect(find.text('Login'), findsOneWidget);

    final context = tester.element(find.byType(LoginScreen));
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.text('Create Lobby'));
    await tester.pumpAndSettle();
    expect(find.text('Create Lobby'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.text('Join Lobby'));
    await tester.pumpAndSettle();
    expect(find.text('Join Lobby'), findsOneWidget);
  });
}
