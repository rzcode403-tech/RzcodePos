import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/constants.dart';

class APIService {
  late http.Client _client;
  String? _token;
  late SharedPreferences _prefs;

  APIService() {
    _client = http.Client();
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs.getString('auth_token');
  }

  // ═══════════════════════════════════════════════
  // AUTHENTICATION
  // ═══════════════════════════════════════════════

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${AppAPI.baseURL}${AppAPI.login}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));

      // ✅ نحاول فك تشفير الـ JSON في جميع الحالات
      Map<String, dynamic>? data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        data = null;
      }

      if (response.statusCode == 200) {
        // ✅ نتعامل مع تنسيقات مختلفة للـ response
        // Format 1: { token: "...", user: {...} }
        // Format 2: { success: true, data: { token: "...", user: {...} } }
        // Format 3: { success: true, token: "...", user: {...} }
        final token = data?['token'] ??
            data?['data']?['token'] ??
            data?['access_token'] ??
            data?['data']?['access_token'];

        final user = data?['user'] ??
            data?['data']?['user'] ??
            data?['data'];

        if (token == null) {
          return {'success': false, 'error': 'الخادم لم يُرجع توكن المصادقة'};
        }

        _token = token.toString();
        await _prefs.setString('auth_token', _token!);
        if (user != null) {
          await _prefs.setString('user_data', jsonEncode(user));
        }
        return {'success': true, 'data': data ?? {}};

      } else {
        // ✅ نستخرج رسالة الخطأ الحقيقية من الـ response
        final errorMessage = data?['message'] ??
            data?['error'] ??
            data?['errors']?.toString() ??
            'خطأ ${response.statusCode}';

        if (response.statusCode == 401) {
          return {'success': false, 'error': 'بيانات غير صحيحة'};
        } else if (response.statusCode == 422) {
          // Laravel validation errors
          if (data?['errors'] is Map) {
            final errors = data!['errors'] as Map;
            final firstError = errors.values.first;
            final msg = firstError is List ? firstError.first : firstError.toString();
            return {'success': false, 'error': msg};
          }
          return {'success': false, 'error': errorMessage.toString()};
        } else if (response.statusCode >= 500) {
          return {'success': false, 'error': 'خطأ في الخادم (${response.statusCode}): $errorMessage'};
        } else {
          return {'success': false, 'error': errorMessage.toString()};
        }
      }
    } on TimeoutException {
      return {'success': false, 'error': 'انتهت مهلة الاتصال، تحقق من الإنترنت'};
    } catch (e) {
      return {'success': false, 'error': 'خطأ في الاتصال: $e'};
    }
  }

  Future<bool> logout() async {
    try {
      await _client.post(
        Uri.parse('${AppAPI.baseURL}${AppAPI.logout}'),
        headers: _getHeaders(),
      );
      _token = null;
      await _prefs.remove('auth_token');
      await _prefs.remove('user_data');
      return true;
    } catch (e) {
      return false;
    }
  }

  User? getCachedUser() {
    final userData = _prefs.getString('user_data');
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  bool isLoggedIn() => _token != null && _token!.isNotEmpty;

  // ═══════════════════════════════════════════════
  // PRODUCTS
  // ═══════════════════════════════════════════════

  Future<Map<String, dynamic>> getProducts({int? categoryId}) async {
    try {
      String url = '${AppAPI.baseURL}${AppAPI.products}';
      if (categoryId != null) {
        url += '?category_id=$categoryId';
      }

      final response =
          await _client.get(Uri.parse(url), headers: _getHeaders()).timeout(
                const Duration(seconds: 30),
              );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = (data['data'] as List)
            .map((p) => Product.fromJson(p))
            .toList();
        return {'success': true, 'data': products};
      } else {
        return {'success': false, 'error': 'فشل جلب المنتجات'};
      }
    } catch (e) {
      return {'success': false, 'error': 'خطأ في الاتصال: $e'};
    }
  }

  Future<Map<String, dynamic>> searchProducts(String query) async {
    try {
      final response = await _client
          .get(Uri.parse('${AppAPI.baseURL}${AppAPI.products}?search=$query'),
              headers: _getHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = (data['data'] as List)
            .map((p) => Product.fromJson(p))
            .toList();
        return {'success': true, 'data': products};
      } else {
        return {'success': false, 'error': 'فشلت البحث'};
      }
    } catch (e) {
      return {'success': false, 'error': 'خطأ في الاتصال: $e'};
    }
  }

  Future<Map<String, dynamic>> getProductByBarcode(String barcode) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${AppAPI.baseURL}${AppAPI.products}/barcode/$barcode'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': Product.fromJson(data['data'])};
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'المنتج غير موجود'};
      } else {
        return {'success': false, 'error': 'خطأ'};
      }
    } catch (e) {
      return {'success': false, 'error': 'خطأ في الاتصال: $e'};
    }
  }

  // ═══════════════════════════════════════════════
  // CATEGORIES
  // ═══════════════════════════════════════════════

  Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await _client
          .get(
            Uri.parse('${AppAPI.baseURL}${AppAPI.categories}'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final categories = (data['data'] as List)
            .map((c) => Category.fromJson(c))
            .toList();
        return {'success': true, 'data': categories};
      } else {
        return {'success': false, 'error': 'فشل جلب الفئات'};
      }
    } catch (e) {
      return {'success': false, 'error': 'خطأ في الاتصال: $e'};
    }
  }

  // ═══════════════════════════════════════════════
  // SALES
  // ═══════════════════════════════════════════════

  Future<Map<String, dynamic>> createSale(Sale sale) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${AppAPI.baseURL}${AppAPI.sales}'),
            headers: _getHeaders(),
            body: jsonEncode(sale.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'فشل إنشاء البيع'};
      }
    } catch (e) {
      return {'success': false, 'error': 'خطأ في الاتصال: $e'};
    }
  }

  Future<Map<String, dynamic>> getSales(
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      String url = '${AppAPI.baseURL}${AppAPI.sales}';
      if (startDate != null && endDate != null) {
        url += '?start_date=${startDate.toIso8601String()}&end_date=${endDate.toIso8601String()}';
      }

      final response = await _client
          .get(Uri.parse(url), headers: _getHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sales =
            (data['data'] as List).map((s) => Sale.fromJson(s)).toList();
        return {'success': true, 'data': sales};
      } else {
        return {'success': false, 'error': 'فشل جلب البيع'};
      }
    } catch (e) {
      return {'success': false, 'error': 'خطأ في الاتصال: $e'};
    }
  }

  // ═══════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _client
          .get(
            Uri.parse('${AppAPI.baseURL}${AppAPI.settings}'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': AppSettings.fromJson(data['data'])};
      } else {
        return {'success': false, 'error': 'فشل جلب الإعدادات'};
      }
    } catch (e) {
      return {'success': false, 'error': 'خطأ في الاتصال: $e'};
    }
  }

  Future<Map<String, dynamic>> updateSettings(AppSettings settings) async {
    try {
      final response = await _client
          .put(
            Uri.parse('${AppAPI.baseURL}${AppAPI.settings}'),
            headers: _getHeaders(),
            body: jsonEncode(settings.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'error': 'فشل تحديث الإعدادات'};
      }
    } catch (e) {
      return {'success': false, 'error': 'خطأ في الاتصال: $e'};
    }
  }

  // ═══════════════════════════════════════════════
  // USERS
  // ═══════════════════════════════════════════════

  Future<Map<String, dynamic>> getUsers() async {
    try {
      final response = await _client
          .get(
            Uri.parse('${AppAPI.baseURL}${AppAPI.users}'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final users =
            (data['data'] as List).map((u) => User.fromJson(u)).toList();
        return {'success': true, 'data': users};
      } else {
        return {'success': false, 'error': 'فشل جلب المستخدمين'};
      }
    } catch (e) {
      return {'success': false, 'error': 'خطأ في الاتصال: $e'};
    }
  }

  // ═══════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  String? getToken() => _token;

  void setToken(String token) {
    _token = token;
  }

  @override
  String toString() => 'APIService(token: ${_token != null ? 'present' : 'null'})';
}
