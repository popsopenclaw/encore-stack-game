import 'package:flutter/material.dart';

import '../screens/create_lobby_screen.dart';
import '../screens/game_screen.dart';
import '../screens/home_screen.dart';
import '../screens/join_lobby_screen.dart';
import '../screens/login_screen.dart';
import '../screens/lobby_room_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/session_gate_screen.dart';
import '../widgets/authenticated_route.dart';

class AppRoutes {
  static const gate = '/';
  static const login = '/login';
  static const home = '/home';
  static const createLobby = '/lobby/create';
  static const joinLobby = '/lobby/join';
  static const lobbyRoom = '/lobby/room';
  static const game = '/game';
  static const settings = '/settings';
  static const profile = '/profile';
}

class AppRouter {
  static Map<String, WidgetBuilder> get routes => {
    AppRoutes.gate: (_) => const SessionGateScreen(),
    AppRoutes.login: (_) => const LoginScreen(),
    AppRoutes.home: (_) => const AuthenticatedRoute(child: HomeScreen()),
    AppRoutes.createLobby:
        (_) => const AuthenticatedRoute(child: CreateLobbyScreen()),
    AppRoutes.joinLobby:
        (_) => const AuthenticatedRoute(child: JoinLobbyScreen()),
    AppRoutes.lobbyRoom:
        (_) => const AuthenticatedRoute(child: LobbyRoomScreen()),
    AppRoutes.game: (_) => const AuthenticatedRoute(child: GameScreen()),
    AppRoutes.settings:
        (_) => const AuthenticatedRoute(child: SettingsScreen()),
    AppRoutes.profile: (_) => const AuthenticatedRoute(child: ProfileScreen()),
  };
}
