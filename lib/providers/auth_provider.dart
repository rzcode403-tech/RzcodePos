import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final APIService _apiService;

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;

  // ✅ إضافة: متغير يتتبع هل انتهى تحميل الحالة من الذاكرة
  bool _isInitialized = false;

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

  // ✅ إضافة: SplashScreen تنتظر هذا قبل الانتقال
  bool get isInitialized => _isInitialized;

  // ═══════════════════════════════════════════════
  // METHODS
  // ═══════════════════════════════════════════════

  Future<void> _checkAuthStatus() async {
    // ✅ الإصلاح الأساسي: initialize() تحمّل التوكن من SharedPreferences
    // بدونها _token يبقى null و isLoggedIn يرجع false دائماً
    await _apiService.initialize();

    _user = _apiService.getCachedUser();
    _isLoggedIn = _apiService.isLoggedIn();

    // ✅ أعلم SplashScreen أن التحميل انتهى
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.login(email, password);

      if (result['success'] == true) {
        // ✅ PHP يرجع token و user في المستوى الأعلى (بعد إصلاح API)
        final userData = result['data']?['user'] ?? result['user'];
        _user = User.fromJson(userData);
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
