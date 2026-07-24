import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/user.dart';

/// Holds auth state for the whole app (ChangeNotifier so widgets can
/// listen and rebuild -- e.g. switch between login screen and home screen
/// -- without passing tokens through every constructor by hand).
class AuthService extends ChangeNotifier {
  AppUser? currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<void> register(String name, String email, String password) async {
    final result = await apiService.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    _applyAuthResult(result);
  }

  Future<void> login(String email, String password) async {
    final result = await apiService.post('/auth/login', {
      'email': email,
      'password': password,
    });
    _applyAuthResult(result);
  }

  void _applyAuthResult(Map<String, dynamic> result) {
    apiService.setToken(result['token']);
    currentUser = AppUser.fromJson(result['user']);
    notifyListeners();
  }

  void logout() {
    apiService.clearToken();
    currentUser = null;
    notifyListeners();
  }
}

final authService = AuthService();
