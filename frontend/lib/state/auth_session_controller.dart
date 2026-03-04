import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/backend_config.dart';

final authSessionController = AuthSessionController();

class AuthSessionController extends ChangeNotifier {
  bool _initialized = false;
  bool _hasSession = false;

  bool get initialized => _initialized;
  bool get hasSession => _hasSession;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString(kJwtPrefKey);
    _hasSession = jwt != null && jwt.isNotEmpty;
    _initialized = true;
    notifyListeners();
  }

  Future<void> markLoggedIn(String jwt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kJwtPrefKey, jwt);
    _hasSession = true;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kJwtPrefKey);
    _hasSession = false;
    notifyListeners();
  }
}
