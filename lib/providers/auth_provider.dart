import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final APIService _apiService;
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;

  AuthProvider(this._apiService) {
    _checkAuthStatus();
  }

  // ═══════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;

  // ═══════════════════════════════════════════════
  // METHODS
  // ═══════════════════════════════════════════════

  Future<void> _checkAuthStatus() async {
    _user = _apiService.getCachedUser();
    _isLoggedIn = _apiService.isLoggedIn();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.login(email, password);
      
      if (result['success']) {
        _user = User.fromJson(result['data']['user']);
        _isLoggedIn = true;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = result['error'] ?? 'فشل تسجيل الدخول';
        _isLoggedIn = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'حدث خطأ: $e';
      _isLoggedIn = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.logout();
      if (result) {
        _user = null;
        _isLoggedIn = false;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = 'فشل تسجيل الخروج';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'حدث خطأ: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
