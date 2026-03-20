<<<<<<< HEAD
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
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        await _prefs.setString('auth_token', _token!);
        await _prefs.setString('user_data', jsonEncode(data['user']));
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'بيانات غير صحيحة'};
      } else {
        return {'success': false, 'error': 'خطأ الخادم'};
      }
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
=======
import 'api_client.dart';

class ApiService {
  // Auth
  static Future<Map<String, dynamic>> login(String username, String password) {
    return ApiClient.post('auth', {
      'username': username,
      'password': password,
    });
  }

  // Settings
  static Future<Map<String, dynamic>> getSettings() {
    return ApiClient.get('settings');
  }

  static Future<Map<String, dynamic>> updateSetting(String key, String value) {
    return ApiClient.put('settings', {'key': key, 'value': value});
  }

  // Categories
  static Future<Map<String, dynamic>> getCategories() {
    return ApiClient.get('categories');
  }

  static Future<Map<String, dynamic>> getCategory(int id) {
    return ApiClient.get('categories/$id');
  }

  static Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) {
    return ApiClient.post('categories', data);
  }

  static Future<Map<String, dynamic>> updateCategory(int id, Map<String, dynamic> data) {
    return ApiClient.put('categories/$id', data);
  }

  static Future<Map<String, dynamic>> deleteCategory(int id) {
    return ApiClient.delete('categories/$id');
  }

  // Products
  static Future<Map<String, dynamic>> getProducts({int? categoryId, String? search}) {
    String endpoint = 'products';
    if (categoryId != null) endpoint += '?category_id=$categoryId';
    if (search != null) endpoint += '${categoryId != null ? '&' : '?'}search=$search';
    return ApiClient.get(endpoint);
  }

  static Future<Map<String, dynamic>> getProduct(int id) {
    return ApiClient.get('products/$id');
  }

  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) {
    return ApiClient.post('products', data);
  }

  static Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> data) {
    return ApiClient.put('products/$id', data);
  }

  static Future<Map<String, dynamic>> deleteProduct(int id) {
    return ApiClient.delete('products/$id');
  }

  // Users
  static Future<Map<String, dynamic>> getUsers() {
    return ApiClient.get('users');
  }

  static Future<Map<String, dynamic>> getUser(int id) {
    return ApiClient.get('users/$id');
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) {
    return ApiClient.post('users', data);
  }

  static Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) {
    return ApiClient.put('users/$id', data);
  }

  static Future<Map<String, dynamic>> deleteUser(int id) {
    return ApiClient.delete('users/$id');
  }

  // Sales
  static Future<Map<String, dynamic>> getSales({String? dateFrom, String? dateTo}) {
    String endpoint = 'sales';
    if (dateFrom != null) endpoint += '?date_from=$dateFrom';
    if (dateTo != null) endpoint += '${dateFrom != null ? '&' : '?'}date_to=$dateTo';
    return ApiClient.get(endpoint);
  }

  static Future<Map<String, dynamic>> getSale(int id) {
    return ApiClient.get('sales/$id');
  }

  static Future<Map<String, dynamic>> createSale(Map<String, dynamic> data) {
    return ApiClient.post('sales', data);
  }

  // Logs
  static Future<Map<String, dynamic>> getLogs({String? action}) {
    String endpoint = 'logs';
    if (action != null) endpoint += '?action=$action';
    return ApiClient.get(endpoint);
  }

  static Future<Map<String, dynamic>> addLog(Map<String, dynamic> data) {
    return ApiClient.post('logs', data);
  }
>>>>>>> 238d0439ff13f5d62eca002becd754815d1488a2
}
