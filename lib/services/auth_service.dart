import 'package:flutter/foundation.dart';

/// Lightweight session & authentication service.
/// Provides current user identity without requiring a full remote auth server.
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  String _currentUserId = 'user_alex_101';
  String _currentUserName = 'Alex (You)';
  bool _isLoggedIn = true;

  String get currentUserId => _currentUserId;
  String get currentUserName => _currentUserName;
  bool get isLoggedIn => _isLoggedIn;

  /// Log in with specific user credentials
  void login({required String userId, required String userName}) {
    _currentUserId = userId.trim();
    _currentUserName = userName.trim();
    _isLoggedIn = true;
    notifyListeners();
  }

  /// Log out (used to test unauthenticated edge cases)
  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  /// Switch user session (useful for simulating 2 different friends on the same device)
  void switchUser({required String userId, required String userName}) {
    _currentUserId = userId.trim();
    _currentUserName = userName.trim();
    _isLoggedIn = true;
    notifyListeners();
  }

  /// Helper to toggle login state for test convenience
  void setLoggedIn(bool loggedIn) {
    _isLoggedIn = loggedIn;
    notifyListeners();
  }
}
