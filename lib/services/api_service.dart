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

  APIService() { _client = http.Client(); }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs.getString('auth_token');
  }

  Map<String, String> _headers() {
    final h = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (_token != null && _token!.isNotEmpty) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final r = await _client.get(Uri.parse('${AppAPI.baseURL}$path'), headers: _headers()).timeout(const Duration(seconds: 30));
      return _parse(r);
    } on TimeoutException { return {'success': false, 'error': 'انتهت مهلة الاتصال'}; }
    catch (e) { return {'success': false, 'error': e.toString()}; }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final r = await _client.post(Uri.parse('${AppAPI.baseURL}$path'), headers: _headers(), body: jsonEncode(body)).timeout(const Duration(seconds: 30));
      return _parse(r);
    } on TimeoutException { return {'success': false, 'error': 'انتهت مهلة الاتصال'}; }
    catch (e) { return {'success': false, 'error': e.toString()}; }
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    try {
      final r = await _client.put(Uri.parse('${AppAPI.baseURL}$path'), headers: _headers(), body: jsonEncode(body)).timeout(const Duration(seconds: 30));
      return _parse(r);
    } on TimeoutException { return {'success': false, 'error': 'انتهت مهلة الاتصال'}; }
    catch (e) { return {'success': false, 'error': e.toString()}; }
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    try {
      final r = await _client.delete(Uri.parse('${AppAPI.baseURL}$path'), headers: _headers()).timeout(const Duration(seconds: 30));
      return _parse(r);
    } on TimeoutException { return {'success': false, 'error': 'انتهت مهلة الاتصال'}; }
    catch (e) { return {'success': false, 'error': e.toString()}; }
  }

  Map<String, dynamic> _parse(http.Response r) {
    Map<String, dynamic>? data;
    try { data = jsonDecode(r.body) as Map<String, dynamic>; } catch (_) {}
    if (r.statusCode == 200 || r.statusCode == 201) {
      return {'success': true, 'data': data?['data'] ?? data};
    }
    final msg = data?['message'] ?? data?['error'] ?? 'خطأ ${r.statusCode}';
    return {'success': false, 'error': msg};
  }

  // ── Auth ─────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final r = await _client.post(
        Uri.parse('${AppAPI.baseURL}${AppAPI.login}'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      ).timeout(const Duration(seconds: 30));

      Map<String, dynamic>? data;
      try { data = jsonDecode(r.body) as Map<String, dynamic>; } catch (_) {}

      if (r.statusCode == 200) {
        final token = data?['token'] ?? data?['data']?['token'] ?? data?['access_token'];
        final user  = data?['user']  ?? data?['data']?['user']  ?? data?['data'];
        if (token == null) return {'success': false, 'error': 'لم يُرجع الخادم توكن'};
        _token = token.toString();
        await _prefs.setString('auth_token', _token!);
        if (user != null) await _prefs.setString('user_data', jsonEncode(user));
        return {'success': true, 'data': data ?? {}};
      }
      final rawBody = r.body.length > 300 ? r.body.substring(0, 300) : r.body;
      final detail  = data?['message'] ?? data?['error'] ?? rawBody;
      if (r.statusCode == 401) return {'success': false, 'error': 'بيانات غير صحيحة'};
      if (r.statusCode == 422) {
        if (data?['errors'] is Map) {
          final errors = data!['errors'] as Map;
          final first  = errors.values.first;
          return {'success': false, 'error': first is List ? first.first : first.toString()};
        }
        return {'success': false, 'error': detail.toString()};
      }
      return {'success': false, 'error': 'خطأ ${r.statusCode}: $detail'};
    } on TimeoutException { return {'success': false, 'error': 'انتهت مهلة الاتصال'}; }
    catch (e) { return {'success': false, 'error': 'خطأ في الاتصال: $e'}; }
  }

  Future<bool> logout() async {
    try {
      await _client.post(Uri.parse('${AppAPI.baseURL}${AppAPI.logout}'), headers: _headers()).timeout(const Duration(seconds: 10));
    } catch (_) {}
    _token = null;
    await _prefs.remove('auth_token');
    await _prefs.remove('user_data');
    return true;
  }

  User? getCachedUser() {
    final d = _prefs.getString('user_data');
    if (d == null) return null;
    try { return User.fromJson(jsonDecode(d) as Map<String, dynamic>); } catch (_) { return null; }
  }

  bool isLoggedIn() => _token != null && _token!.isNotEmpty;
  String? getToken() => _token;

  // ── Products ─────────────────────────────────
  Future<Map<String, dynamic>> getProducts({int? categoryId}) async {
    final q = categoryId != null ? '?category_id=$categoryId' : '';
    final r = await _get('${AppAPI.products}$q');
    if (r['success'] == true) {
      final raw = r['data'];
      List<dynamic> list = raw is List ? raw : (raw?['data'] ?? raw?['products'] ?? []);
      return {'success': true, 'data': list.map((p) => Product.fromJson(p as Map<String, dynamic>)).toList()};
    }
    return r;
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) => _post(AppAPI.products, data);
  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> data) => _put('${AppAPI.products}/$id', data);
  Future<Map<String, dynamic>> deleteProduct(int id) => _delete('${AppAPI.products}/$id');

  Future<Product?> getByBarcode(String code) async {
    final r = await _get('${AppAPI.products}/barcode/$code');
    if (r['success'] == true && r['data'] != null) {
      return Product.fromJson(r['data'] as Map<String, dynamic>);
    }
    return null;
  }

  // ── Categories ───────────────────────────────
  Future<Map<String, dynamic>> getCategories() async {
    final r = await _get(AppAPI.categories);
    if (r['success'] == true) {
      final raw = r['data'];
      List<dynamic> list = raw is List ? raw : (raw?['data'] ?? raw?['categories'] ?? []);
      return {'success': true, 'data': list.map((c) => Category.fromJson(c as Map<String, dynamic>)).toList()};
    }
    return r;
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data)         => _post(AppAPI.categories, data);
  Future<Map<String, dynamic>> updateCategory(int id, Map<String, dynamic> data) => _put('${AppAPI.categories}/$id', data);
  Future<Map<String, dynamic>> deleteCategory(int id)                            => _delete('${AppAPI.categories}/$id');

  // ── Sales ─────────────────────────────────────
  Future<Map<String, dynamic>> getSales() async {
    final r = await _get(AppAPI.sales);
    if (r['success'] == true) {
      final raw = r['data'];
      List<dynamic> list = raw is List ? raw : (raw?['data'] ?? raw?['sales'] ?? []);
      return {'success': true, 'data': list.map((s) => Sale.fromJson(s as Map<String, dynamic>)).toList()};
    }
    return r;
  }

  Future<Map<String, dynamic>> createSale(Map<String, dynamic> data) => _post(AppAPI.sales, data);

  // ── Settings ─────────────────────────────────
  Future<Map<String, dynamic>> getSettings() => _get(AppAPI.settings);
  Future<Map<String, dynamic>> updateSettings(AppSettings s) => _put(AppAPI.settings, s.toJson());
}
