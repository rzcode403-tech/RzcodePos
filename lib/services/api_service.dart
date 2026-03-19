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
}
