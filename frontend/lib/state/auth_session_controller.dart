import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/backend_config.dart';
import '../services/api_client.dart';

final authSessionController = AuthSessionController();
typedef SessionValidator =
    Future<bool?> Function(String jwt, String backendUrl);

class AuthSessionController extends ChangeNotifier {
  bool _initialized = false;
  bool _hasSession = false;
  SessionValidator? _sessionValidator;

  bool get initialized => _initialized;
  bool get hasSession => _hasSession;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final backendUrl = prefs.getString(kBackendPrefKey) ?? kBackendUrlFromBuild;
    final jwt = prefs.getString(kJwtPrefKey);
    _hasSession = jwt != null && jwt.isNotEmpty;

    if (_hasSession) {
      final validator = _sessionValidator ?? _defaultSessionValidator;
      final isValid = await validator(jwt!, backendUrl);
      if (isValid == false) {
        await prefs.remove(kJwtPrefKey);
        _hasSession = false;
      }
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> markLoggedIn(String jwt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kJwtPrefKey, jwt);
    _hasSession = true;
    _initialized = true;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kJwtPrefKey);
    _hasSession = false;
    _initialized = true;
    notifyListeners();
  }

  @visibleForTesting
  void setSessionValidator(SessionValidator? validator) {
    _sessionValidator = validator;
  }

  @visibleForTesting
  void resetForTest() {
    _initialized = false;
    _hasSession = false;
    _sessionValidator = null;
  }

  Future<bool?> _defaultSessionValidator(String jwt, String backendUrl) async {
    try {
      final api = ApiClient(baseUrl: backendUrl, jwt: jwt);
      await api.getProfile();
      return true;
    } on UnauthorizedApiException {
      return false;
    } on ApiErrorException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
