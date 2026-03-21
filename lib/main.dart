import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

// ─────────────────────────────────────────────
// COULEURS & CONSTANTES
// ─────────────────────────────────────────────
const kPrimary  = Color(0xFF1b3a5c);
const kPrimary2 = Color(0xFF234d7a);
const kAccent   = Color(0xFFe8a020);
const kGreen    = Color(0xFF16a34a);
const kRed      = Color(0xFFdc2626);
const kBlue     = Color(0xFF2563eb);
const kPurple   = Color(0xFF7c3aed);
const kOrange   = Color(0xFFea580c);
const kTeal     = Color(0xFF0891b2);

const Map<String, List<String>> kPerms = {
  'Admin':       ['caisse','dashboard','produits','categories','utilisateurs','rapports','logs','parametres','stocks','backup'],
  'Superviseur': ['caisse','dashboard','produits','categories','rapports','logs','stocks'],
  'Vendeur':     ['caisse'],
};

const kPayMethods = ['Espèces','Carte','Chèque','Mobile Pay'];

final kAvColors = [kPrimary, kGreen, kRed, kBlue, kPurple, kOrange, kTeal,
  const Color(0xFF0f766e), const Color(0xFFbe185d)];

Color hexColor(String hex) {
  try {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  } catch (_) { return kPrimary; }
}

String fmtDT(DateTime d) =>
  '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year} '
  '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

String fmtD(DateTime d) =>
  '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

// ═══════════════════════════════════════════════
// MODÈLES
// ═══════════════════════════════════════════════

class AppSettings {
  String name, slogan, addr, city, tel, email, mf, rne, msg, logo, cur;
  int tva;
  AppSettings({
    this.name    = 'Mon SuperMarché',
    this.slogan  = 'Qualité & Fraîcheur',
    this.addr    = 'Avenue Habib Bourguiba',
    this.city    = 'Tunis',
    this.tel     = '+216 71 000 000',
    this.email   = 'contact@supermarche.tn',
    this.mf      = '1234567/A/M/000',
    this.rne     = 'J0123456',
    this.msg     = 'Merci de votre visite !',
    this.logo    = '🛒',
    this.cur     = 'DT',
    this.tva     = 19,
  });
  // API key-value map
  Map<String, String> toApiMap() => {
    'shop_name':name,'shop_slogan':slogan,'shop_address':addr,'shop_city':city,
    'shop_phone':tel,'shop_email':email,'shop_mf':mf,'shop_rne':rne,
    'welcome_message':msg,'logo':logo,'currency':cur,'tax_rate':'$tva',
  };
  factory AppSettings.fromApiMap(Map<String, dynamic> m) => AppSettings(
    name:   m['shop_name']       ?? m['name']   ?? 'Mon SuperMarché',
    slogan: m['shop_slogan']     ?? m['slogan']  ?? 'Qualité & Fraîcheur',
    addr:   m['shop_address']    ?? m['addr']    ?? '',
    city:   m['shop_city']       ?? m['city']    ?? 'Tunis',
    tel:    m['shop_phone']      ?? m['tel']     ?? '',
    email:  m['shop_email']      ?? m['email']   ?? '',
    mf:     m['shop_mf']         ?? m['mf']      ?? '',
    rne:    m['shop_rne']        ?? m['rne']     ?? '',
    msg:    m['welcome_message'] ?? m['msg']     ?? 'Merci de votre visite !',
    logo:   m['logo']            ?? '🛒',
    cur:    m['currency']        ?? m['cur']     ?? 'DT',
    tva:    int.tryParse((m['tax_rate'] ?? m['tva'] ?? '19').toString()) ?? 19,
  );
}

class Category {
  int id, status;
  String name, emoji, color;
  Category({required this.id, required this.name,
    this.emoji = '🏷️', this.color = '#1b3a5c', this.status = 1});
  Color get colorVal => hexColor(color);
  Map<String, dynamic> toMap() =>
    {'id':id,'name':name,'emoji':emoji,'color':color,'is_active':status};
  factory Category.fromMap(Map<String, dynamic> m) => Category(
    id:     (m['id']     as int?)    ?? 0,
    name:   (m['name']   as String?) ?? '',
    emoji:  (m['emoji']  as String?) ?? '🏷️',
    color:  (m['color']  as String?) ?? '#1b3a5c',
    status: m['is_active'] == true || (m['is_active'] as int?) == 1 ? 1 : (m['status'] as int? ?? 1),
  );
}

class Product {
  int id, cat, tva, stock, status, minStock;
  String name, emoji, barcode;
  double price, costPrice;
  Product({required this.id, required this.name, required this.cat,
    required this.price, this.tva=0, this.stock=0, this.minStock=5,
    this.emoji='📦', this.barcode='', this.status=1, this.costPrice=0});
  double get priceTTC => price * (1 + tva / 100);
  Map<String, dynamic> toMap() => {
    'id':id,'name':name,'category_id':cat,'price':price,'tva':tva,
    'stock':stock,'min_stock':minStock,'emoji':emoji,'barcode':barcode,
    'is_active':status,'cost_price':costPrice,
  };
  factory Product.fromMap(Map<String, dynamic> m) => Product(
    id:        (m['id']          as int?)    ?? 0,
    name:      (m['name']        as String?) ?? '',
    cat:       (m['category_id'] as int?)    ?? (m['cat'] as int?) ?? 1,
    price:     ((m['price']      as num?)    ?? 0).toDouble(),
    tva:       (m['tva']         as int?)    ?? 0,
    stock:     (m['stock']       as int?)    ?? 0,
    minStock:  (m['min_stock']   as int?)    ?? 5,
    emoji:     (m['emoji']       as String?) ?? '📦',
    barcode:   (m['barcode']     as String?) ?? '',
    costPrice: ((m['cost_price'] as num?)    ?? 0).toDouble(),
    status:    m['is_active'] == true || (m['is_active'] as int?) == 1 ? 1
               : (m['status'] as int? ?? 1),
  );
}

class AppUser {
  int id, status;
  String username, password, prenom, nom, tel, email, role, lastLogin;
  AppUser({required this.id, required this.username, required this.password,
    required this.prenom, required this.nom, this.tel='', this.email='',
    required this.role, this.status=1, this.lastLogin=''});
  String get initials =>
    '${prenom.isNotEmpty ? prenom[0] : "?"}${nom.isNotEmpty ? nom[0] : "?"}'.toUpperCase();
  Color get avatarColor => kAvColors[id % kAvColors.length];
  List<String> get perms => kPerms[role] ?? [];
  Map<String, dynamic> toMap() => {
    'id':id,'username':username,'password':password,'prenom':prenom,'nom':nom,
    'tel':tel,'email':email,'role':role,'is_active':status,
    'last_login': lastLogin.isEmpty ? null : lastLogin,
  };
  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
    id:        (m['id']         as int?)    ?? 0,
    username:  (m['username']   as String?) ?? (m['email'] as String? ?? ''),
    password:  '',  // API لا يُرجع كلمة المرور
    prenom:    (m['prenom']     as String?) ?? '',
    nom:       (m['nom']        as String?) ?? '',
    tel:       (m['tel']        as String?) ?? '',
    email:     (m['email']      as String?) ?? '',
    role:      (m['role']       as String?) ?? 'Vendeur',
    status:    m['is_active'] == true || (m['is_active'] as int?) == 1 ? 1 : 0,
    lastLogin: (m['last_login'] as String?) ?? '',
  );
}

class CartItem {
  final Product product;
  int qty;
  CartItem({required this.product, this.qty = 1});
  double get lineTotal => product.priceTTC * qty;
}

class SaleItem {
  final int productId, tva, qty;
  final String name, emoji;
  final double price;
  SaleItem({required this.productId, required this.name, required this.emoji,
    required this.price, required this.tva, required this.qty});
  double get total => price * (1 + tva / 100) * qty;
  Map<String, dynamic> toMap() =>
    {'product_id':productId,'name':name,'emoji':emoji,'price':price,'tva':tva,'quantity':qty};
  factory SaleItem.fromMap(Map<String, dynamic> m) => SaleItem(
    productId: (m['product_id'] as int?)    ?? (m['id'] as int? ?? 0),
    name:      (m['product_name'] as String?) ?? (m['name'] as String? ?? ''),
    emoji:     (m['product_emoji'] as String?) ?? (m['emoji'] as String? ?? '📦'),
    price:     ((m['price']    as num?)   ?? 0).toDouble(),
    tva:       (m['tva']       as int?)   ?? 0,
    qty:       (m['quantity']  as int?)   ?? (m['qty'] as int? ?? 1),
  );
}

class Sale {
  final int id, userId;
  final DateTime date;
  final String cashier, method, saleNumber;
  final List<SaleItem> items;
  final double subtotal, tax, total, given, change;
  Sale({required this.id, required this.date, required this.cashier,
    required this.method, required this.userId, required this.items,
    required this.subtotal, required this.tax, required this.total,
    required this.given, required this.change, this.saleNumber = ''});
  int get totalQty => items.fold(0, (s, i) => s + i.qty);
  String get shortId => saleNumber.isNotEmpty ? saleNumber : '#${id.toString().padLeft(4,'0')}';
  factory Sale.fromMap(Map<String, dynamic> m) {
    List<SaleItem> items = [];
    final raw = m['items'];
    if (raw is List) {
      items = raw.map((i) => SaleItem.fromMap(i as Map<String,dynamic>)).toList();
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final lst = jsonDecode(raw) as List;
        items = lst.map((i) => SaleItem.fromMap(i as Map<String,dynamic>)).toList();
      } catch (_) {}
    }
    return Sale(
      id:         (m['id']           as int?)    ?? 0,
      userId:     (m['user_id']      as int?)    ?? 0,
      date:       DateTime.tryParse((m['created_at'] ?? m['sale_date'] ?? '') as String) ?? DateTime.now(),
      cashier:    (m['cashier']      as String?) ?? '',
      method:     (m['payment_method'] ?? m['method'] ?? 'Espèces') as String,
      items:      items,
      subtotal:   ((m['subtotal']    as num?)    ?? 0).toDouble(),
      tax:        ((m['tax']         as num?)    ?? 0).toDouble(),
      total:      ((m['total']       as num?)    ?? 0).toDouble(),
      given:      ((m['given_amount'] ?? m['given'] ?? 0) as num).toDouble(),
      change:     ((m['change_amount'] ?? m['change_am'] ?? 0) as num).toDouble(),
      saleNumber: (m['sale_number']  as String?) ?? '',
    );
  }
}

class AppLog {
  final int id, userId;
  final DateTime date;
  final String user, prenom, role, action, details;
  AppLog({required this.id, required this.userId, required this.date,
    required this.user, required this.prenom, required this.role,
    required this.action, required this.details});
  factory AppLog.fromMap(Map<String, dynamic> m) => AppLog(
    id:      (m['id']         as int?)    ?? 0,
    userId:  (m['user_id']   as int?)    ?? 0,
    date:    DateTime.tryParse((m['created_at'] ?? m['log_date'] ?? '') as String) ?? DateTime.now(),
    user:    (m['username']   as String?) ?? '',
    prenom:  (m['prenom']     as String?) ?? '',
    role:    (m['role']       as String?) ?? '',
    action:  (m['action']     as String?) ?? '',
    details: (m['details']    as String?) ?? '',
  );
}

// ═══════════════════════════════════════════════
// API SERVICE — بديل SQLite
// ═══════════════════════════════════════════════
class API {
  static const String base = 'https://rzcode.tn/pos/api';
  // fallback: استخدم ?r= إن كان .htaccess لا يعمل
  static bool _useQueryRoute = false;

  static Uri _uri(String path) {
    if (_useQueryRoute) {
      return Uri.parse('\$base/index.php?r=\${path.replaceAll(RegExp(r"^/"), "")}');
    }
    return Uri.parse('\$base\$path');
  }

  // اختبار الـ routing عند أول استخدام
  static Future<void> _checkRouting() async {
    if (_useQueryRoute) return;
    try {
      final r = await http.get(Uri.parse('\$base/index.php?r='), headers: {'Accept':'application/json'}).timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) _useQueryRoute = true;
    } catch (_) {}
  }
  static String? _token;
  static final _client = http.Client();

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('session_token');
  }

  static Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_token', token);
  }

  static Future<void> _clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');
    await prefs.remove('cached_user');
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Future<Map<String, dynamic>> _req(String method, String path, [Map? body]) async {
    try {
      final uri = Uri.parse('$base$path');
      http.Response res;
      switch (method) {
        case 'GET':    res = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 20)); break;
        case 'POST':   res = await _client.post(uri, headers: _headers, body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 20)); break;
        case 'PUT':    res = await _client.put(uri, headers: _headers, body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 20)); break;
        case 'DELETE': res = await _client.delete(uri, headers: _headers).timeout(const Duration(seconds: 20)); break;
        default: return {'ok': false, 'error': 'Method not supported'};
      }
      Map<String, dynamic>? json;
      try { json = jsonDecode(res.body) as Map<String, dynamic>; } catch (_) {}
      return {
        'ok':     res.statusCode >= 200 && res.statusCode < 300 && json?['success'] != false,
        'status': res.statusCode,
        'data':   json?['data'] ?? json,
        'error':  json?['error'] ?? json?['message'] ?? 'خطأ ${res.statusCode}',
        'raw':    json,
      };
    } on TimeoutException {
      return {'ok': false, 'error': 'انتهت مهلة الاتصال'};
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  // ── Auth ──────────────────────────────────
  static Future<Map<String, dynamic>> login(String emailOrUser, String pw) async {
    final r = await _req('POST', '/auth/login', {'email': emailOrUser, 'username': emailOrUser, 'password': pw});
    if (r['ok'] == true) {
      final d = r['data'] as Map<String, dynamic>? ?? {};
      final token = d['token'] ?? (r['raw'] as Map?)?['token'];
      final user  = d['user']  ?? d;
      if (token != null) await _saveToken(token.toString());
      if (user is Map<String, dynamic>) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user', jsonEncode(user));
      }
      return {'ok': true, 'user': user};
    }
    return r;
  }

  static Future<void> logout() async {
    try { await _req('POST', '/auth/logout'); } catch (_) {}
    await _clearToken();
  }

  static Future<AppUser?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('cached_user');
    if (s == null) return null;
    try { return AppUser.fromMap(jsonDecode(s) as Map<String, dynamic>); } catch (_) { return null; }
  }

  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  // ── Settings ─────────────────────────────
  static Future<AppSettings> getSettings() async {
    final r = await _req('GET', '/settings');
    if (r['ok'] == true && r['data'] is Map) return AppSettings.fromApiMap(r['data'] as Map<String, dynamic>);
    return AppSettings();
  }

  static Future<void> saveSettings(AppSettings s) async {
    await _req('PUT', '/settings', s.toApiMap());
  }

  // ── Categories ───────────────────────────
  static Future<List<Category>> getCategories() async {
    final r = await _req('GET', '/categories');
    if (r['ok'] == true && r['data'] is List) {
      return (r['data'] as List).map((c) => Category.fromMap(c as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<bool> saveCategory(Category c) async {
    final r = c.id == 0
      ? await _req('POST', '/categories', c.toMap())
      : await _req('PUT',  '/categories/${c.id}', c.toMap());
    return r['ok'] == true;
  }

  static Future<bool> deleteCategory(int id) async {
    final r = await _req('DELETE', '/categories/$id');
    return r['ok'] == true;
  }

  // ── Products ─────────────────────────────
  static Future<List<Product>> getProducts() async {
    final r = await _req('GET', '/products');
    if (r['ok'] == true && r['data'] is List) {
      return (r['data'] as List).map((p) => Product.fromMap(p as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<bool> saveProduct(Product p) async {
    final r = p.id == 0
      ? await _req('POST', '/products', p.toMap())
      : await _req('PUT',  '/products/${p.id}', p.toMap());
    return r['ok'] == true;
  }

  static Future<bool> deleteProduct(int id) async {
    final r = await _req('DELETE', '/products/$id');
    return r['ok'] == true;
  }

  static Future<bool> updateStock(int id, int stock) async {
    final r = await _req('PUT', '/products/$id', {'stock': stock});
    return r['ok'] == true;
  }

  static Future<Product?> getByBarcode(String code) async {
    final r = await _req('GET', '/products/barcode/${Uri.encodeComponent(code)}');
    if (r['ok'] == true && r['data'] is Map) return Product.fromMap(r['data'] as Map<String, dynamic>);
    return null;
  }

  // ── Users ─────────────────────────────────
  static Future<List<AppUser>> getUsers() async {
    final r = await _req('GET', '/users');
    if (r['ok'] == true && r['data'] is List) {
      return (r['data'] as List).map((u) => AppUser.fromMap(u as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<bool> saveUser(AppUser u) async {
    if (u.id == 0) {
      final body = u.toMap();
      if (u.password.isNotEmpty) body['password'] = u.password;
      final r = await _req('POST', '/auth/register', body);
      return r['ok'] == true;
    } else {
      final body = u.toMap();
      if (u.password.isNotEmpty) body['password'] = u.password;
      final r = await _req('PUT', '/users/${u.id}', body);
      return r['ok'] == true;
    }
  }

  static Future<bool> deleteUser(int id) async {
    final r = await _req('DELETE', '/users/$id');
    return r['ok'] == true;
  }

  // ── Sales ─────────────────────────────────
  static Future<List<Sale>> getSales() async {
    final r = await _req('GET', '/sales?limit=500');
    if (r['ok'] == true && r['data'] is List) {
      return (r['data'] as List).map((s) => Sale.fromMap(s as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<bool> saveSale(Map<String, dynamic> data) async {
    final r = await _req('POST', '/sales', data);
    return r['ok'] == true;
  }

  static Future<bool> clearSales() async {
    // API لا يدعم حذف جميع المبيعات مباشرة — نتجاهل
    return true;
  }

  // ── Logs ──────────────────────────────────
  static Future<List<AppLog>> getLogs() async {
    final r = await _req('GET', '/logs?limit=200');
    if (r['ok'] == true && r['data'] is List) {
      return (r['data'] as List).map((l) => AppLog.fromMap(l as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<bool> clearLogs() async {
    final r = await _req('DELETE', '/logs');
    return r['ok'] == true;
  }
}

// ═══════════════════════════════════════════════
// ÉTAT GLOBAL (Provider) — نفس الواجهة الأصلية
// ═══════════════════════════════════════════════
class AppState extends ChangeNotifier {
  AppUser?       currentUser;
  AppSettings    settings   = AppSettings();
  List<Category> categories = [];
  List<Product>  products   = [];
  List<AppUser>  users      = [];
  List<Sale>     sales      = [];
  List<AppLog>   logs       = [];
  List<CartItem> cart       = [];
  bool darkMode = false;
  bool loading  = true;
  String page   = 'caisse';
  String? _lastError;
  String? get lastError => _lastError;

  static int _ctr = 0;
  static int newId() { _ctr = (_ctr + 1) % 9999; return 0; } // API يولد الـ ID

  Future<void> init() async {
    await API.init();
    // استعادة المستخدم من الكاش
    if (API.isLoggedIn) {
      currentUser = await API.getCachedUser();
    }
    await _loadAll();
    loading = false;
    notifyListeners();
  }

  Future<void> _loadAll() async {
    settings   = await API.getSettings();
    categories = await API.getCategories();
    products   = await API.getProducts();
    if (currentUser != null) {
      sales = await API.getSales();
      logs  = await API.getLogs();
      if (currentUser!.perms.contains('utilisateurs')) {
        users = await API.getUsers();
      }
    }
    notifyListeners();
  }

  String fmtP(double n) {
    final s = n.toStringAsFixed(3).replaceAll('.', ',');
    return '$s ${settings.cur}';
  }

  // ── Auth ──────────────────────────────────
  Future<bool> doLogin(String un, String pw) async {
    _lastError = null;
    final r = await API.login(un, pw);
    if (r['ok'] == true) {
      final userMap = r['user'];
      if (userMap is Map<String, dynamic>) {
        currentUser = AppUser.fromMap(userMap);
      }
      await _loadAll();
      notifyListeners();
      return true;
    }
    _lastError = r['error']?.toString() ?? 'Identifiants incorrects';
    return false;
  }

  Future<void> doLogout() async {
    await API.logout();
    currentUser = null;
    cart.clear();
    page = 'caisse';
    sales = []; logs = []; users = [];
    notifyListeners();
  }

  bool hasPerm(String pg) => currentUser?.perms.contains(pg) ?? false;

  // ── Panier ────────────────────────────────
  void addToCart(Product pr) {
    final i = cart.indexWhere((c) => c.product.id == pr.id);
    if (i >= 0) cart[i].qty++;
    else cart.add(CartItem(product: pr));
    notifyListeners();
  }

  void updQty(int id, int d) {
    final i = cart.indexWhere((c) => c.product.id == id);
    if (i < 0) return;
    cart[i].qty += d;
    if (cart[i].qty <= 0) cart.removeAt(i);
    notifyListeners();
  }

  void removeItem(int id) { cart.removeWhere((c) => c.product.id == id); notifyListeners(); }
  void clearCart()        { cart.clear(); notifyListeners(); }

  double get subTotal   => cart.fold(0.0, (s, i) => s + i.product.price * i.qty);
  double get taxTotal   => cart.fold(0.0, (s, i) => s + i.product.price * i.qty * (i.product.tva / 100));
  double get grandTotal => subTotal + taxTotal;

  // ── Vente ─────────────────────────────────
  Future<Sale> processSale(String method, double given) async {
    final u = currentUser!;
    final items = cart.map((ci) => {
      'product_id': ci.product.id,
      'name':       ci.product.name,
      'emoji':      ci.product.emoji,
      'price':      ci.product.price,
      'tva':        ci.product.tva,
      'quantity':   ci.qty,
    }).toList();

    final data = {
      'items':          jsonEncode(items),
      'subtotal':       subTotal,
      'tax':            taxTotal,
      'total':          grandTotal,
      'payment_method': method,
      'given_amount':   given,
      'change_amount':  method == 'Espèces' ? (given - grandTotal).clamp(0, 1e9) : 0.0,
    };

    await API.saveSale(data);

    // تحديث المخزون محلياً
    for (final ci in cart) {
      final idx = products.indexWhere((p) => p.id == ci.product.id);
      if (idx >= 0) {
        products[idx].stock = (products[idx].stock - ci.qty).clamp(0, 999999);
      }
    }

    final fakeSale = Sale(
      id: DateTime.now().millisecondsSinceEpoch,
      date: DateTime.now(),
      cashier: u.username,
      method: method,
      userId: u.id,
      items: cart.map((ci) => SaleItem(
        productId: ci.product.id, name: ci.product.name, emoji: ci.product.emoji,
        price: ci.product.price, tva: ci.product.tva, qty: ci.qty)).toList(),
      subtotal: subTotal, tax: taxTotal, total: grandTotal,
      given: given,
      change: method == 'Espèces' ? (given - grandTotal).clamp(0.0, 1e9) : 0.0,
    );

    sales.insert(0, fakeSale);
    clearCart();
    // تحديث المبيعات والسجل من الـ API
    Future.microtask(() async {
      sales = await API.getSales();
      logs  = await API.getLogs();
      notifyListeners();
    });
    notifyListeners();
    return fakeSale;
  }

  // ── Produits ─────────────────────────────
  Future<void> saveProduct(Product pr) async {
    await API.saveProduct(pr);
    await _refreshProducts();
    logAct('PRODUCT_EDIT', pr.name);
  }

  Future<void> deleteProduct(int id) async {
    await API.deleteProduct(id);
    products.removeWhere((p) => p.id == id);
    notifyListeners();
    logAct('PRODUCT_DELETE', 'id=$id');
  }

  Future<void> _refreshProducts() async {
    products = await API.getProducts();
    notifyListeners();
  }

  // ── Catégories ───────────────────────────
  Future<void> saveCategory(Category c) async {
    await API.saveCategory(c);
    categories = await API.getCategories();
    notifyListeners();
    logAct(c.id == 0 ? 'CATEGORY_ADD' : 'CATEGORY_EDIT', c.name);
  }

  Future<void> deleteCategory(int id) async {
    await API.deleteCategory(id);
    categories.removeWhere((c) => c.id == id);
    notifyListeners();
    logAct('CATEGORY_DELETE', 'id=$id');
  }

  // ── Utilisateurs ─────────────────────────
  Future<void> saveUser(AppUser u) async {
    await API.saveUser(u);
    users = await API.getUsers();
    notifyListeners();
    logAct(u.id == 0 ? 'USER_ADD' : 'USER_EDIT', '${u.prenom} ${u.nom}');
  }

  Future<void> deleteUser(int id) async {
    await API.deleteUser(id);
    users.removeWhere((u) => u.id == id);
    notifyListeners();
    logAct('USER_DELETE', 'id=$id');
  }

  // ── Paramètres ───────────────────────────
  Future<void> saveSettings(AppSettings s) async {
    await API.saveSettings(s);
    settings = s;
    notifyListeners();
    logAct('SETTINGS_CHANGE', 'Paramètres mis à jour');
  }

  // ── Logs ─────────────────────────────────
  void logAct(String action, String details) {
    Future.microtask(() async {
      logs = await API.getLogs();
      notifyListeners();
    });
  }

  Future<void> clearLogs() async {
    await API.clearLogs();
    logs.clear();
    notifyListeners();
  }

  Future<void> clearSales() async {
    await API.clearSales();
    sales = await API.getSales();
    notifyListeners();
  }

  Future<void> updateStock(int id, int stock) async {
    await API.updateStock(id, stock);
    final idx = products.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      products[idx].stock = stock;
      notifyListeners();
    }
    logAct('STOCK_UPDATE', 'id=$id stock=$stock');
  }

  void toggleDark() { darkMode = !darkMode; notifyListeners(); }
  void setPage(String pg) { page = pg; notifyListeners(); }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await API.init();
  runApp(ChangeNotifierProvider(
    create: (_) => AppState()..init(),
    child: const PosApp(),
  ));
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});
  @override
  Widget build(BuildContext ctx) {
    final st = ctx.watch<AppState>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SuperMarché POS',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimary),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 2),
        drawerTheme: const DrawerThemeData(backgroundColor: kPrimary),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimary, brightness: Brightness.dark),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0f172a), foregroundColor: Colors.white),
        drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF1e293b)),
      ),
      themeMode: st.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: st.loading
        ? const _SplashScreen()
        : st.currentUser == null
          ? const LoginScreen()
          : const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// SPLASH
// ─────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: kPrimary,
    body: const Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('🛒', style: TextStyle(fontSize: 72)),
        SizedBox(height: 16),
        Text('SuperMarché POS',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        SizedBox(height: 8),
        Text('Chargement...', style: TextStyle(color: Colors.white54, fontSize: 13)),
        SizedBox(height: 32),
        CircularProgressIndicator(color: kAccent),
      ],
    )),
  );
}

// ═══════════════════════════════════════════════
// ÉCRAN CONNEXION
// ═══════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginState();
}
class _LoginState extends State<LoginScreen> {
  final _uc = TextEditingController();
  final _pc = TextEditingController();
  bool _loading = false, _showPw = false;
  String? _error;

  @override
  Widget build(BuildContext ctx) {
    final st = ctx.watch<AppState>();
    return Scaffold(
      backgroundColor: kPrimary,
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 30)],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(st.settings.logo, style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 8),
            Text(st.settings.name,
              style: const TextStyle(color: kPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
            Text(st.settings.slogan,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),
            // Error
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kRed)),
                child: Text(_error!,
                  style: const TextStyle(color: kRed, fontWeight: FontWeight.w700, fontSize: 13))),
              const SizedBox(height: 12),
            ],
            // Email / Username
            TextField(
              controller: _uc,
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                labelText: 'Email ou nom d\'utilisateur',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder()),
              onSubmitted: (_) => _doLogin(st)),
            const SizedBox(height: 12),
            // Password
            TextField(
              controller: _pc,
              obscureText: !_showPw,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_showPw ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showPw = !_showPw))),
              onSubmitted: (_) => _doLogin(st)),
            const SizedBox(height: 20),
            // Login button
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : () => _doLogin(st),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: _loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Se Connecter',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)))),
            const SizedBox(height: 20),
            // Demo accounts
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('🔑 Comptes de démonstration',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey)),
                const SizedBox(height: 8),
                _hintRow('Admin',       'admin',       'admin123',  kRed),
                _hintRow('Superviseur', 'superviseur', 'sup123',    kOrange),
                _hintRow('Vendeur',     'vendeur',     'vend123',   kBlue),
              ])),
          ]),
        ),
      ))),
    );
  }

  Widget _hintRow(String role, String un, String pw, Color c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: GestureDetector(
      onTap: () { _uc.text = un; _pc.text = pw; },
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: c.withOpacity(.15), borderRadius: BorderRadius.circular(20)),
          child: Text(role, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c))),
        const SizedBox(width: 8),
        Text('$un / $pw',
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey)),
        const SizedBox(width: 4),
        const Icon(Icons.touch_app, size: 12, color: Colors.grey),
      ]),
    ),
  );

  Future<void> _doLogin(AppState st) async {
    setState(() { _error = null; _loading = true; });
    if (_uc.text.trim().isEmpty || _pc.text.isEmpty) {
      setState(() { _error = 'Remplissez tous les champs.'; _loading = false; });
      return;
    }
    final ok = await st.doLogin(_uc.text.trim(), _pc.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) setState(() => _error = st.lastError ?? 'Identifiants incorrects ou compte inactif.');
  }
}

// ═══════════════════════════════════════════════
// HOME SCREEN + DRAWER
// ═══════════════════════════════════════════════
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _titles = {
    'caisse':'Point de Vente', 'dashboard':'Tableau de Bord',
    'produits':'Produits', 'categories':'Catégories',
    'utilisateurs':'Utilisateurs', 'rapports':'Rapports',
    'logs':"Journal d'Activité", 'parametres':'Paramètres',
    'stocks':'Gestion des Stocks', 'backup':'Sauvegarde',
  };

  @override
  Widget build(BuildContext ctx) {
    final st = ctx.watch<AppState>();
    final u  = st.currentUser!;

    Widget body;
    switch (st.page) {
      case 'dashboard':    body = const DashboardPage(); break;
      case 'produits':     body = const ProduitsPage(); break;
      case 'categories':   body = const CategoriesPage(); break;
      case 'utilisateurs': body = const UtilisateursPage(); break;
      case 'rapports':     body = const RapportsPage(); break;
      case 'logs':         body = const LogsPage(); break;
      case 'parametres':   body = const ParametresPage(); break;
      case 'stocks':       body = const StocksPage(); break;
      case 'backup':       body = const BackupPage(); break;
      default:             body = const CaissePage();
    }

    return Scaffold(
  resizeToAvoidBottomInset: true, 
      appBar: AppBar(
        title: Text(_titles[st.page] ?? 'POS',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        actions: [
          IconButton(
            icon: Icon(st.darkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: st.toggleDark, tooltip: 'Thème'),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: u.avatarColor, radius: 17,
              child: Text(u.initials,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)))),
        ],
      ),
      drawer: _AppDrawer(),

  body: SafeArea(

    child: body,

  ),

      floatingActionButton: st.page == 'caisse' ? const CalculatriceButton() : null,
    );
  }
}

class _AppDrawer extends StatelessWidget {
  static const _navItems = [
    {'id':'caisse',       'label':'Point de Vente', 'icon': Icons.point_of_sale_outlined},
    {'id':'dashboard',    'label':'Tableau de Bord','icon': Icons.dashboard_outlined},
    {'id':'produits',     'label':'Produits',       'icon': Icons.inventory_2_outlined},
    {'id':'categories',   'label':'Catégories',     'icon': Icons.label_outline},
    {'id':'utilisateurs', 'label':'Utilisateurs',   'icon': Icons.group_outlined},
    {'id':'rapports',     'label':'Rapports',       'icon': Icons.bar_chart_outlined},
    {'id':'logs',         'label':'Journal',        'icon': Icons.list_alt_outlined},
    {'id':'parametres',   'label':'Paramètres',     'icon': Icons.settings_outlined},
    {'id':'stocks',       'label':'Stock',          'icon': Icons.warehouse_outlined},
    {'id':'backup',       'label':'Sauvegarde',     'icon': Icons.backup_outlined},
  ];

  @override
  Widget build(BuildContext ctx) {
    final st = ctx.watch<AppState>();
    final u  = st.currentUser!;
    return Drawer(child: SafeArea(child: Column(children: [
      // Header
      Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(16,16,16,12),
        color: kPrimary,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(st.settings.logo, style: const TextStyle(fontSize: 38)),
          const SizedBox(height: 4),
          Text(st.settings.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
          Text('POS v3.0 • API',
            style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 10)),
        ])),
      // User box
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: kPrimary2,
        child: Row(children: [
          CircleAvatar(backgroundColor: u.avatarColor, radius: 19,
            child: Text(u.initials,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${u.prenom} ${u.nom}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            Text(u.role, style: TextStyle(color: Colors.white.withOpacity(.65), fontSize: 11)),
          ])),
        ])),
      // Nav
      Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 6), children: [
        for (final item in _navItems)
          if (st.hasPerm(item['id'] as String))
            _navTile(ctx, st, item),
      ])),
      Divider(color: Colors.white.withOpacity(.2), height: 1),
      // Logout
      ListTile(
        leading: Icon(Icons.logout, color: Colors.red.shade300, size: 20),
        title: Text('Déconnexion',
          style: TextStyle(color: Colors.red.shade300, fontWeight: FontWeight.w700, fontSize: 13)),
        onTap: () { Navigator.pop(ctx); st.doLogout(); }),
      const SizedBox(height: 6),
    ])));
  }

  Widget _navTile(BuildContext ctx, AppState st, Map item) {
    final id       = item['id'] as String;
    final isActive = st.page == id;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(.13) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? Border(left: BorderSide(color: kAccent, width: 3)) : null),
      child: ListTile(
        dense: true,
        leading: Icon(item['icon'] as IconData,
          color: isActive ? kAccent : Colors.white.withOpacity(.7), size: 20),
        title: Text(item['label'] as String,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(.75),
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        onTap: () { st.setPage(id); Navigator.pop(ctx); },
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// PAGE CAISSE
// ═══════════════════════════════════════════════
class CaissePage extends StatefulWidget {
  const CaissePage({super.key});
  @override State<CaissePage> createState() => _CaisseState();
}
class _CaisseState extends State<CaissePage> {
  final _srch = TextEditingController();
  String _cat = 'Tous';

  @override
  void dispose() { _srch.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext ctx) {
    final st          = ctx.watch<AppState>();
    final isLandscape = MediaQuery.of(ctx).orientation == Orientation.landscape;
    return isLandscape
      ? Row(children: [
          Expanded(flex: 3, child: _buildProducts(ctx, st)),
          const VerticalDivider(width: 1),
          SizedBox(width: 300, child: _buildCart(ctx, st)),
        ])
      : Column(children: [
          Expanded(flex: 3, child: _buildProducts(ctx, st)),
          const Divider(height: 1),
          SizedBox(height: MediaQuery.of(ctx).size.height * .44, child: _buildCart(ctx, st)),
        ]);
  }

  // ── Products panel ─────────────────────────
  Widget _buildProducts(BuildContext ctx, AppState st) {
    final cats = st.categories.where((c) => c.status == 1).toList();
    var prods  = st.products.where((p) => p.status == 1).toList();
    final q    = _srch.text.toLowerCase();
    if (q.isNotEmpty) {
      prods = prods.where((p) =>
        p.name.toLowerCase().contains(q) || p.barcode.contains(q)).toList();
    }
    if (_cat != 'Tous') {
      final c = cats.where((c) => c.name == _cat).firstOrNull;
      if (c != null) prods = prods.where((p) => p.cat == c.id).toList();
    }

    return Column(children: [
      // Search bar
      Padding(padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _srch,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher ou scanner...',
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30)))),
            onChanged: (_) => setState(() {}),
            onSubmitted: (v) {
              final code = v.trim();
              if (code.isEmpty) return;
              final prod = st.products.firstWhere(
                (p) => p.barcode == code && p.status == 1,
                orElse: () => Product(id: -1, name: '', cat: 0, price: 0));
              if (prod.id > 0) {
                st.addToCart(prod);
                _srch.clear(); setState(() {});
                _snack(ctx, '✅ ${prod.name} ajouté');
              } else {
                _snack(ctx, '⚠ Code non trouvé : $code');
              }
            })),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.qr_code_scanner),
            style: IconButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
            tooltip: 'Scanner code barres',
            onPressed: () => _openScanner(ctx, st)),
        ])),
      // Category chips
      SizedBox(height: 44, child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          _catChip('Tous'),
          ...cats.map((c) => _catChip(c.name)),
        ])),
      // Product grid
      Expanded(child: prods.isEmpty
        ? const Center(child: Text('Aucun produit trouvé', style: TextStyle(color: Colors.grey)))
        : GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 130, childAspectRatio: .75,
              crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: prods.length,
            itemBuilder: (ctx, i) {
              final pr  = prods[i];
              final oos = pr.stock <= 0;
              return GestureDetector(
                onTap: oos ? null : () { st.addToCart(pr); _snack(ctx, '${pr.emoji} ${pr.name}'); },
                child: Opacity(opacity: oos ? .4 : 1, child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 6)],
                    border: Border.all(color: Colors.grey.withOpacity(.15))),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(pr.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(pr.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                    const SizedBox(height: 4),
                    Text(st.fmtP(pr.priceTTC),
                      style: const TextStyle(color: kGreen, fontWeight: FontWeight.w900, fontSize: 11)),
                    Text(oos ? '⚠ Rupture' : '${pr.stock} en stock',
                      style: TextStyle(fontSize: 9, color: oos ? kRed : Colors.grey)),
                  ]),
                )),
              );
            })),
    ]);
  }

  Widget _catChip(String name) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: FilterChip(
      label: Text(name, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: _cat == name ? Colors.white : null)),
      selected: _cat == name,
      onSelected: (_) => setState(() => _cat = name),
      selectedColor: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 2)));

  // ── Cart panel ─────────────────────────────
  Widget _buildCart(BuildContext ctx, AppState st) {
    return Column(children: [
      // Header
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: kPrimary,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('🛒 Panier',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(20)),
            child: Text(
              '${st.cart.fold(0, (s, i) => s + i.qty)} art.',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
        ])),
      // Items
      Expanded(child: st.cart.isEmpty
        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('🛒', style: TextStyle(fontSize: 36)),
            Text('Panier vide', style: TextStyle(color: Colors.grey)),
          ]))
        : ListView.builder(
            itemCount: st.cart.length,
            itemBuilder: (ctx, i) {
              final ci = st.cart[i];
              return ListTile(
                dense: true,
                leading: Text(ci.product.emoji, style: const TextStyle(fontSize: 20)),
                title: Text(ci.product.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${st.fmtP(ci.product.priceTTC)} × ${ci.qty}',
                  style: const TextStyle(fontSize: 10)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(st.fmtP(ci.lineTotal),
                    style: const TextStyle(color: kGreen, fontWeight: FontWeight.w900, fontSize: 11)),
                  const SizedBox(width: 4),
                  _qBtn('−', () => st.updQty(ci.product.id, -1)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('${ci.qty}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13))),
                  _qBtn('+', () => st.updQty(ci.product.id,  1)),
                  const SizedBox(width: 2),
                  GestureDetector(
                    onTap: () => st.removeItem(ci.product.id),
                    child: const Icon(Icons.close, size: 16, color: kRed)),
                ]),
              );
            })),
      // Summary
      Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 8, offset: const Offset(0,-2))]),
        child: Column(children: [
          _sumRow('Sous-total HT', st.fmtP(st.subTotal)),
          _sumRow('TVA',           st.fmtP(st.taxTotal)),
          const Divider(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TOTAL TTC',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kPrimary)),
            Text(st.fmtP(st.grandTotal),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kPrimary)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline, size: 15),
              label: const Text('Vider', style: TextStyle(fontSize: 12)),
              onPressed: st.cart.isEmpty ? null : () => _confirmClear(ctx, st),
              style: OutlinedButton.styleFrom(
                foregroundColor: kRed, side: const BorderSide(color: kRed)))),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: ElevatedButton.icon(
              icon: const Icon(Icons.payment, size: 15),
              label: const Text('ENCAISSER',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              onPressed: st.cart.isEmpty ? null : () => _openPayment(ctx, st),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen, foregroundColor: Colors.white,
                minimumSize: const Size(0, 44)))),
          ]),
        ])),
    ]);
  }

  Widget _qBtn(String l, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: Container(width: 20, height: 20, alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4)),
      child: Text(l, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))));

  Widget _sumRow(String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      Text(val,   style: const TextStyle(fontSize: 12)),
    ]));

  void _snack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
  }

  void _confirmClear(BuildContext ctx, AppState st) => showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      title: const Text('Vider le panier ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        TextButton(
          onPressed: () { st.clearCart(); Navigator.pop(ctx); },
          style: TextButton.styleFrom(foregroundColor: kRed),
          child: const Text('Vider')),
      ]));

  void _openPayment(BuildContext ctx, AppState st) => showDialog(
    context: ctx, barrierDismissible: false,
    builder: (_) => PaymentDialog(state: st));

  Future<void> _openScanner(BuildContext ctx, AppState st) async {
    final code = await Navigator.push<String>(
      ctx, MaterialPageRoute(builder: (_) => const ScannerScreen()));
    if (code == null || !ctx.mounted) return;
    final prod = st.products.firstWhere(
      (p) => p.barcode == code && p.status == 1,
      orElse: () => Product(id: -1, name: '', cat: 0, price: 0));
    if (prod.id > 0) {
      st.addToCart(prod);
      _snack(ctx, '✅ ${prod.name} ajouté');
    } else {
      _srch.text = code; setState(() {});
      _snack(ctx, '⚠ Code non trouvé : $code');
    }
  }
}

// ═══════════════════════════════════════════════
// SCANNER
// ═══════════════════════════════════════════════
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override State<ScannerScreen> createState() => _ScannerState();
}
class _ScannerState extends State<ScannerScreen> {
  final _ctrl = MobileScannerController(detectionSpeed: DetectionSpeed.normal);
  bool _found = false;
  final _manualCtrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); _manualCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      title: const Text('📷 Scanner Code Barres'),
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      actions: [
        IconButton(icon: const Icon(Icons.flash_on), onPressed: () => _ctrl.toggleTorch()),
        IconButton(icon: const Icon(Icons.cameraswitch), onPressed: () => _ctrl.switchCamera()),
      ]),
      resizeToAvoidBottomInset: true, 
    body: SafeArea(
        child: Column(children: [
      Expanded(flex: 3, child: Stack(children: [
        MobileScanner(
          controller: _ctrl,
          onDetect: (capture) {
            if (_found) return;
            final code = capture.barcodes.firstOrNull?.rawValue ?? '';
            if (code.isNotEmpty) {
              _found = true;
              Navigator.pop(ctx, code);
            }
          }),
        // Scan overlay
        Center(child: Container(
          width: 250, height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: kAccent, width: 3),
            borderRadius: BorderRadius.circular(12)),
          child: const Center(
            child: Text('Centrez le code barres',
              style: TextStyle(color: Colors.white70, fontSize: 13))))),
      ])),
      // Manual input
      Container(
        color: Colors.grey.shade900,
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          const Text('Ou saisir manuellement',
            style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(
              controller: _manualCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Code barres...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true, fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              onSubmitted: (v) { if (v.trim().isNotEmpty) Navigator.pop(ctx, v.trim()); })),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final v = _manualCtrl.text.trim();
                if (v.isNotEmpty) Navigator.pop(ctx, v);
              },
              style: ElevatedButton.styleFrom(backgroundColor: kAccent, foregroundColor: Colors.white),
              child: const Text('✓')),
          ]),
        ])),
    ])),
  );
}

// ═══════════════════════════════════════════════
// DIALOGUE PAIEMENT
// ═══════════════════════════════════════════════
class PaymentDialog extends StatefulWidget {
  final AppState state;
  const PaymentDialog({super.key, required this.state});
  @override State<PaymentDialog> createState() => _PayState();
}
class _PayState extends State<PaymentDialog> {
  String _method = '';
  final _givenCtrl = TextEditingController();
  double _change = 0;

  @override
  Widget build(BuildContext ctx) {
    final st = widget.state;
    return AlertDialog(
      title: Text('💳 Encaissement\n${st.fmtP(st.grandTotal)}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Payment methods
        Wrap(spacing: 8, runSpacing: 8,
          children: kPayMethods.map((m) {
            final icons = {'Espèces':'💵','Carte':'💳','Chèque':'🧾','Mobile Pay':'📱'};
            return GestureDetector(
              onTap: () => setState(() => _method = m),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _method == m ? kGreen.withOpacity(.15) : Theme.of(ctx).cardColor,
                  border: Border.all(color: _method == m ? kGreen : Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(10)),
                child: Column(children: [
                  Text(icons[m] ?? '💳', style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(m, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: _method == m ? kGreen : null)),
                ])));
          }).toList()),
        // Cash change calculation
        if (_method == 'Espèces') ...[
          const SizedBox(height: 14),
          TextField(
            controller: _givenCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Montant remis (DT)',
              prefixIcon: Icon(Icons.payments_outlined),
              border: OutlineInputBorder()),
            onChanged: (v) {
              final g = double.tryParse(v.replaceAll(',', '.')) ?? 0;
              setState(() => _change = g - st.grandTotal);
            }),
          if (_givenCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _change >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Monnaie à rendre :',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(st.fmtP(_change.abs()),
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14,
                    color: _change >= 0 ? kGreen : kRed)),
              ])),
          ],
        ],
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _method.isEmpty ? null : () => _confirm(ctx, st),
          style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.white),
          child: const Text('✔ Confirmer', style: TextStyle(fontWeight: FontWeight.w900))),
      ],
    );
  }

  Future<void> _confirm(BuildContext ctx, AppState st) async {
    double given = 0;
    if (_method == 'Espèces') {
      given = double.tryParse(_givenCtrl.text.replaceAll(',', '.')) ?? 0;
      if (given > 0 && given < st.grandTotal) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('⚠ Montant insuffisant !'), backgroundColor: kRed));
        return;
      }
      if (given == 0) given = st.grandTotal;
    } else {
      given = st.grandTotal;
    }
    final sale = await st.processSale(_method, given);
    if (!ctx.mounted) return;
    Navigator.pop(ctx);
    showDialog(context: ctx, builder: (_) => ReceiptDialog(sale: sale, state: st));
  }
}
// ═══════════════════════════════════════════════
// DIALOGUE TICKET DE CAISSE (avec impression PDF)
// ═══════════════════════════════════════════════

// ── Génération PDF du ticket ─────────────────
Future<pw.Document> buildReceiptPdf(Sale sale, AppSettings s) async {
  final doc = pw.Document();
  final mmWidth = 80 * PdfPageFormat.mm;

  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat(mmWidth, double.infinity,
      marginLeft:   4 * PdfPageFormat.mm,
      marginRight:  4 * PdfPageFormat.mm,
      marginTop:    4 * PdfPageFormat.mm,
      marginBottom: 4 * PdfPageFormat.mm),
    build: (ctx) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // En-tête magasin
        pw.Text(s.name,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 15),
          textAlign: pw.TextAlign.center),
        pw.Text(s.slogan,
          style: const pw.TextStyle(fontSize: 9),
          textAlign: pw.TextAlign.center),
        pw.Text('${s.addr}, ${s.city}',
          style: const pw.TextStyle(fontSize: 8),
          textAlign: pw.TextAlign.center),
        pw.Text('Tel: ${s.tel}',
          style: const pw.TextStyle(fontSize: 8),
          textAlign: pw.TextAlign.center),
        if (s.mf.isNotEmpty)
          pw.Text('MF: ${s.mf}  RNE: ${s.rne}',
            style: const pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.center),
        pw.Divider(borderStyle: pw.BorderStyle.dashed),
        // Info ticket
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Ticket #${sale.shortId}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Text(fmtDT(sale.date),
            style: const pw.TextStyle(fontSize: 8)),
        ]),
        pw.Text('Caissier: ${sale.cashier}',
          style: const pw.TextStyle(fontSize: 8)),
        pw.Divider(borderStyle: pw.BorderStyle.dashed),
        // Articles
        pw.Table(columnWidths: {
          0: const pw.FlexColumnWidth(4),
          1: const pw.FixedColumnWidth(20),
          2: const pw.FlexColumnWidth(2),
        }, children: [
          pw.TableRow(children: [
            pw.Text('Désignation', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
            pw.Text('Qté', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center),
            pw.Text('Montant', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right),
          ]),
          ...sale.items.map((i) => pw.TableRow(children: [
            pw.Text(i.name, style: const pw.TextStyle(fontSize: 9)),
            pw.Text('x${i.qty}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center),
            pw.Text('${i.total.toStringAsFixed(3)}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right),
          ])),
        ]),
        pw.Divider(borderStyle: pw.BorderStyle.dashed),
        // Totaux
        _pdfRow('Sous-total HT', '${sale.subtotal.toStringAsFixed(3)} ${s.cur}'),
        _pdfRow('TVA (${s.tva}%)', '${sale.tax.toStringAsFixed(3)} ${s.cur}'),
        pw.Divider(),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('TOTAL TTC',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
          pw.Text('${sale.total.toStringAsFixed(3)} ${s.cur}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
        ]),
        if (sale.method == 'Espèces' && sale.given > 0) ...[
          pw.SizedBox(height: 4),
          _pdfRow('Remis', '${sale.given.toStringAsFixed(3)} ${s.cur}'),
          _pdfRow('Monnaie rendue', '${sale.change.toStringAsFixed(3)} ${s.cur}',
            bold: true),
        ],
        pw.Divider(borderStyle: pw.BorderStyle.dashed),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          child: pw.Text('Mode de paiement: ${sale.method}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            textAlign: pw.TextAlign.center)),
        pw.SizedBox(height: 8),
        pw.Text(s.msg,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          textAlign: pw.TextAlign.center),
        pw.Text('* * * * *',
          style: const pw.TextStyle(letterSpacing: 4, fontSize: 12),
          textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 6),
      ],
    ),
  ));
  return doc;
}

pw.Widget _pdfRow(String l, String v, {bool bold = false}) =>
  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
    pw.Text(l, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : null, fontSize: 10)),
    pw.Text(v, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : null, fontSize: 10)),
  ]);

// ── ReceiptDialog ────────────────────────────
class ReceiptDialog extends StatelessWidget {
  final Sale sale;
  final AppState state;
  const ReceiptDialog({super.key, required this.sale, required this.state});

  @override
  Widget build(BuildContext ctx) {
    final s = state.settings;
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(width: 340, child: SingleChildScrollView(child: Column(children: [
        // Store header
        Text(s.logo, style: const TextStyle(fontSize: 44)),
        Text(s.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        Text(s.slogan, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text('${s.addr}, ${s.city}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text('Tél: ${s.tel}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text('MF: ${s.mf}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Ticket #${sale.shortId}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          Text(fmtDT(sale.date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
        Text('Caissier: ${sale.cashier}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const Divider(),
        // Items
        ...sale.items.map((i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Text(i.emoji), const SizedBox(width: 6),
            Expanded(child: Text(i.name, style: const TextStyle(fontSize: 12))),
            Text('x${i.qty}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(width: 8),
            Text(state.fmtP(i.total),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ]))),
        const Divider(),
        _row('Sous-total HT', state.fmtP(sale.subtotal)),
        _row('TVA',           state.fmtP(sale.tax)),
        const Divider(),
        _row('TOTAL TTC', state.fmtP(sale.total), bold: true, large: true, color: kPrimary),
        if (sale.method == 'Espèces' && sale.given > 0) ...[
          _row('Remis',   state.fmtP(sale.given)),
          _row('Monnaie', state.fmtP(sale.change), color: kGreen, bold: true),
        ],
        const Divider(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: kBlue.withOpacity(.1), borderRadius: BorderRadius.circular(6)),
          child: Text('Mode: ${sale.method}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kBlue))),
        const SizedBox(height: 12),
        Text(s.msg, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        const Text('★ ★ ★ ★ ★', style: TextStyle(letterSpacing: 4, color: kAccent, fontSize: 14)),
        const SizedBox(height: 8),
      ]))),
      actions: [
        // Bouton Partager (texte)
        TextButton.icon(
          icon: const Icon(Icons.share, size: 16),
          label: const Text('Partager'),
          onPressed: () => _shareText(ctx)),
        // Bouton Imprimer (PDF)
        ElevatedButton.icon(
          icon: const Icon(Icons.print, size: 16),
          label: const Text('Imprimer / PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white),
          onPressed: () => _printReceipt(ctx)),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
      ],
    );
  }

  Widget _row(String l, String v, {bool bold=false, bool large=false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: TextStyle(
        fontSize: large ? 14 : 12, fontWeight: bold ? FontWeight.w900 : FontWeight.normal)),
      Text(v, style: TextStyle(
        fontSize: large ? 14 : 12, fontWeight: bold ? FontWeight.w900 : FontWeight.normal, color: color)),
    ]));

  Future<void> _printReceipt(BuildContext ctx) async {
    try {
      final doc = await buildReceiptPdf(sale, state.settings);
      await Printing.layoutPdf(
        onLayout: (_) async => doc.save(),
        name: 'Ticket_${sale.shortId}',
      );
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Erreur impression: $e'), backgroundColor: kRed));
      }
    }
  }

  void _shareText(BuildContext ctx) {
    final s   = state.settings;
    final buf = StringBuffer();
    buf.writeln('═══════════════════════');
    buf.writeln(s.name);
    buf.writeln(s.slogan);
    buf.writeln('${s.addr}, ${s.city}');
    buf.writeln('Tél: ${s.tel}');
    buf.writeln('MF: ${s.mf}');
    buf.writeln('───────────────────────');
    buf.writeln('Ticket #${sale.shortId}');
    buf.writeln(fmtDT(sale.date));
    buf.writeln('Caissier: ${sale.cashier}');
    buf.writeln('───────────────────────');
    for (final i in sale.items) {
      final ttl = i.total.toStringAsFixed(3);
      buf.writeln('${i.name.padRight(20)} x${i.qty}  $ttl ${s.cur}');
    }
    buf.writeln('───────────────────────');
    buf.writeln('Sous-total HT : ${sale.subtotal.toStringAsFixed(3)} ${s.cur}');
    buf.writeln('TVA           : ${sale.tax.toStringAsFixed(3)} ${s.cur}');
    buf.writeln('═══════════════════════');
    buf.writeln('TOTAL TTC     : ${sale.total.toStringAsFixed(3)} ${s.cur}');
    if (sale.method == 'Espèces' && sale.given > 0) {
      buf.writeln('Remis         : ${sale.given.toStringAsFixed(3)} ${s.cur}');
      buf.writeln('Monnaie       : ${sale.change.toStringAsFixed(3)} ${s.cur}');
    }
    buf.writeln('───────────────────────');
    buf.writeln('Paiement: ${sale.method}');
    buf.writeln('═══════════════════════');
    buf.writeln(s.msg);
    Share.share(buf.toString(), subject: 'Ticket ${s.name} #${sale.shortId}');
  }
}

          

// ═══════════════════════════════════════════════
// PAGE TABLEAU DE BORD
// ═══════════════════════════════════════════════
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext ctx) {
    final st  = ctx.watch<AppState>();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);
    final todaySales = st.sales.where((s) => s.date.isAfter(todayStart)).toList();
    final monthSales = st.sales.where((s) => s.date.isAfter(monthStart)).toList();
    final totToday   = todaySales.fold(0.0, (s, t) => s + t.total);
    final totMonth   = monthSales.fold(0.0, (s, t) => s + t.total);
    final totAll     = st.sales.fold(0.0, (s, t) => s + t.total);
    final avg        = st.sales.isEmpty ? 0.0 : totAll / st.sales.length;
    final lowStock   = st.products.where((p) => p.stock > 0 && p.stock <= 10).length;

    return ListView(padding: const EdgeInsets.all(14), children: [
      // Stats grid
      GridView.count(crossAxisCount: 2, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.65,
        children: [
          _stat('💰', "Aujourd'hui",       st.fmtP(totToday), kGreen),
          _stat('🧾', 'Tickets/jour',      '${todaySales.length}',  kBlue),
          _stat('📅', 'CA ce mois',        st.fmtP(totMonth), kPrimary),
          _stat('🛒', 'Panier moyen',      st.fmtP(avg),      kPurple),
          _stat('⚠️', 'Stock faible',      '$lowStock produits', kOrange),
          _stat('💳', 'CA total',          st.fmtP(totAll),   kRed),
        ]),
      const SizedBox(height: 14),
      // Payment methods donut
      if (st.sales.isNotEmpty) ...[
        _sectionTitle('💳 Modes de Paiement'),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          ...() {
            final m = <String, double>{};
            for (final s in st.sales) m[s.method] = (m[s.method] ?? 0) + s.total;
            final tot = m.values.fold(0.0, (a, b) => a + b);
            final cols = [kPrimary, kGreen, kAccent, kPurple, kRed, kBlue, kTeal];
            return m.entries.toList().asMap().entries.map((e) {
              final pct = tot > 0 ? e.value.value / tot : 0.0;
              return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(
                  color: cols[e.key % cols.length], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(e.value.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                SizedBox(width: 120, child: ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: pct, minHeight: 8,
                    backgroundColor: Colors.grey.shade200, color: cols[e.key % cols.length]))),
                const SizedBox(width: 8),
                Text('${(pct * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
              ]));
            }).toList();
          }(),
        ]))),
      ],
      const SizedBox(height: 4),
      _sectionTitle('📋 Dernières Transactions'),
      ...st.sales.take(10).map((s) => Card(
        margin: const EdgeInsets.symmetric(vertical: 3),
        child: ListTile(dense: true,
          leading: CircleAvatar(backgroundColor: kBlue.withOpacity(.12), radius: 18,
            child: Text('#${s.shortId.substring(s.shortId.length.clamp(2, s.shortId.length) - 2)}',
              style: const TextStyle(color: kBlue, fontWeight: FontWeight.w900, fontSize: 11))),
          title: Text('${s.cashier} — ${st.fmtP(s.total)}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          subtitle: Text('${fmtDT(s.date)} · ${s.totalQty} art.',
            style: const TextStyle(fontSize: 11)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: kBlue.withOpacity(.1), borderRadius: BorderRadius.circular(12)),
            child: Text(s.method, style: const TextStyle(color: kBlue, fontWeight: FontWeight.w700, fontSize: 10)))))),
    ]);
  }

  Widget _sectionTitle(String t) => Padding(padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kPrimary)));

  Widget _stat(String ic, String lbl, String val, Color col) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: col.withOpacity(.08), borderRadius: BorderRadius.circular(12),
      border: Border(left: BorderSide(color: col, width: 4))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(ic, style: const TextStyle(fontSize: 22)),
      const Spacer(),
      Text(val, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: col)),
      Text(lbl, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]));
}

// ═══════════════════════════════════════════════
// PAGE PRODUITS
// ═══════════════════════════════════════════════
class ProduitsPage extends StatefulWidget {
  const ProduitsPage({super.key});
  @override State<ProduitsPage> createState() => _ProduitsState();
}
class _ProduitsState extends State<ProduitsPage> {
  final _srch = TextEditingController();
  @override void dispose() { _srch.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext ctx) {
    final st = ctx.watch<AppState>();
    final q  = _srch.text.toLowerCase();
    final prods = st.products.where((p) =>
      q.isEmpty || p.name.toLowerCase().contains(q) || p.barcode.contains(q)).toList();
    final isAdmin = ['Admin','Superviseur'].contains(st.currentUser?.role);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(10), child: Row(children: [
        Expanded(child: TextField(controller: _srch,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search), hintText: 'Rechercher...',
            contentPadding: EdgeInsets.symmetric(vertical: 8),
            border: OutlineInputBorder()),
          onChanged: (_) => setState(() {}))),
        if (isAdmin) ...[
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16), label: const Text('Nouveau'),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
            onPressed: () => showDialog(context: ctx, builder: (_) => ProductDialog(state: st))),
        ],
      ])),
      Expanded(child: ListView.builder(
        itemCount: prods.length,
        itemBuilder: (ctx, i) {
          final pr  = prods[i];
          final cat = st.categories.where((c) => c.id == pr.cat).firstOrNull;
          return Card(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: ListTile(
              leading: Text(pr.emoji, style: const TextStyle(fontSize: 26)),
              title: Text(pr.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (pr.barcode.isNotEmpty)
                  Text(pr.barcode, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey)),
                const SizedBox(height: 2),
                Wrap(spacing: 4, children: [
                  _badge(cat?.name ?? '—', kBlue),
                  _badge('TVA ${pr.tva}%', kPurple),
                  _badge('${pr.stock} en stock', pr.stock <= 0 ? kRed : pr.stock <= 10 ? kOrange : kGreen),
                  if (pr.status == 0) _badge('Inactif', Colors.grey),
                ]),
              ]),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(st.fmtP(pr.priceTTC),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: kGreen, fontSize: 13)),
                if (isAdmin) Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit, size: 16), padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => showDialog(context: ctx, builder: (_) => ProductDialog(state: st, product: pr))),
                  IconButton(icon: const Icon(Icons.delete, size: 16, color: kRed),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                    onPressed: () => _delete(ctx, st, pr)),
                ]),
              ]),
            ));
        })),
    ]);
  }

  Widget _badge(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: c.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
    child: Text(t, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: c)));

  void _delete(BuildContext ctx, AppState st, Product pr) => showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      title: Text('Supprimer "${pr.name}" ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        TextButton(
          onPressed: () { st.deleteProduct(pr.id); st.logAct('PRODUCT_DELETE', pr.name); Navigator.pop(ctx); },
          style: TextButton.styleFrom(foregroundColor: kRed),
          child: const Text('Supprimer')),
      ]));
}

// ── Product form dialog ───────────────────────
class ProductDialog extends StatefulWidget {
  final AppState state;
  final Product? product;
  const ProductDialog({super.key, required this.state, this.product});
  @override State<ProductDialog> createState() => _ProdDialogState();
}
class _ProdDialogState extends State<ProductDialog> {
  final _name = TextEditingController(), _price = TextEditingController();
  final _stock = TextEditingController(), _emoji = TextEditingController();
  final _barcode = TextEditingController();
  int _cat = 1, _tva = 0, _status = 1;

  @override void initState() {
    super.initState();
    final pr = widget.product;
    if (pr != null) {
      _name.text = pr.name; _price.text = pr.price.toString();
      _stock.text = pr.stock.toString(); _emoji.text = pr.emoji;
      _barcode.text = pr.barcode; _cat = pr.cat; _tva = pr.tva; _status = pr.status;
    } else {
      _emoji.text = '📦';
      final cats = widget.state.categories;
      if (cats.isNotEmpty) _cat = cats.first.id;
    }
  }
  @override void dispose() {
    _name.dispose(); _price.dispose(); _stock.dispose();
    _emoji.dispose(); _barcode.dispose(); super.dispose();
  }

  @override Widget build(BuildContext ctx) {
    final st   = widget.state;
    final cats = st.categories;
    return AlertDialog(
      title: Text(widget.product == null ? 'Nouveau Produit' : 'Modifier Produit'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _name,
          decoration: const InputDecoration(labelText: 'Désignation *', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: _price, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Prix HT', border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          SizedBox(width: 100, child: DropdownButtonFormField<int>(
            value: _tva,
            decoration: const InputDecoration(labelText: 'TVA', border: OutlineInputBorder()),
            items: [0,7,13,19].map((v) => DropdownMenuItem(value: v, child: Text('$v%'))).toList(),
            onChanged: (v) => setState(() => _tva = v!))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: _stock, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          SizedBox(width: 80, child: TextField(controller: _emoji, textAlign: TextAlign.center,
            decoration: const InputDecoration(labelText: 'Emoji', border: OutlineInputBorder()))),
        ]),
        const SizedBox(height: 10),
        if (cats.isNotEmpty)
          DropdownButtonFormField<int>(
            value: cats.any((c) => c.id == _cat) ? _cat : cats.first.id,
            decoration: const InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder()),
            items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.emoji} ${c.name}'))).toList(),
            onChanged: (v) => setState(() => _cat = v!)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: _barcode,
            decoration: const InputDecoration(labelText: 'Code Barres', prefixIcon: Icon(Icons.qr_code), border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.qr_code_scanner),
            style: IconButton.styleFrom(backgroundColor: kPrimary),
            onPressed: () => _scanBarcode(ctx)),
        ]),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: _status,
          decoration: const InputDecoration(labelText: 'Statut', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 1, child: Text('Actif')),
            DropdownMenuItem(value: 0, child: Text('Inactif')),
          ],
          onChanged: (v) => setState(() => _status = v!)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
          onPressed: () => _save(ctx, st),
          child: const Text('💾 Enregistrer')),
      ],
    );
  }

  Future<void> _scanBarcode(BuildContext ctx) async {
    final code = await Navigator.push<String>(
      ctx, MaterialPageRoute(builder: (_) => const ScannerScreen()));
    if (code != null && mounted) setState(() => _barcode.text = code);
  }

  void _save(BuildContext ctx, AppState st) {
    final nm = _name.text.trim();
    final pr = double.tryParse(_price.text.replaceAll(',', '.'));
    if (nm.isEmpty || pr == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Remplissez les champs obligatoires !')));
      return;
    }
    final prod = Product(
      id: widget.product?.id ?? AppState.newId(), name: nm, cat: _cat,
      price: pr, tva: _tva, stock: int.tryParse(_stock.text) ?? 0,
      emoji: _emoji.text.isEmpty ? '📦' : _emoji.text,
      barcode: _barcode.text.trim(), status: _status);
    st.saveProduct(prod);
    st.logAct(widget.product == null ? 'PRODUCT_ADD' : 'PRODUCT_EDIT', nm);
    Navigator.pop(ctx);
  }
}

// ═══════════════════════════════════════════════
// PAGE CATÉGORIES
// ═══════════════════════════════════════════════
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});
  @override
  Widget build(BuildContext ctx) {
    final st      = ctx.watch<AppState>();
    final isAdmin = ['Admin','Superviseur'].contains(st.currentUser?.role);
    return Column(children: [
      if (isAdmin) Padding(padding: const EdgeInsets.all(10),
        child: Align(alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16), label: const Text('Nouvelle Catégorie'),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
            onPressed: () => showDialog(context: ctx, builder: (_) => CategoryDialog(state: st))))),
      Expanded(child: ListView.builder(
        itemCount: st.categories.length,
        itemBuilder: (ctx, i) {
          final c   = st.categories[i];
          final cnt = st.products.where((p) => p.cat == c.id).length;
          return Card(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: c.colorVal,
                child: Text(c.emoji, style: const TextStyle(fontSize: 18))),
              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('$cnt produit${cnt != 1 ? "s" : ""}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (c.status == 1 ? kGreen : Colors.grey).withOpacity(.12),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(c.status == 1 ? 'Active' : 'Inactive',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: c.status == 1 ? kGreen : Colors.grey))),
                if (isAdmin) ...[
                  IconButton(icon: const Icon(Icons.edit, size: 16), padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => showDialog(context: ctx, builder: (_) => CategoryDialog(state: st, cat: c))),
                  IconButton(icon: const Icon(Icons.delete, size: 16, color: kRed),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                    onPressed: () {
                      if (cnt > 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('⚠ Catégorie utilisée par des produits !')));
                        return;
                      }
                      showDialog(context: ctx, builder: (_) => AlertDialog(
                        title: Text('Supprimer "${c.name}" ?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                          TextButton(
                            onPressed: () { st.deleteCategory(c.id); st.logAct('CATEGORY_DELETE', c.name); Navigator.pop(ctx); },
                            style: TextButton.styleFrom(foregroundColor: kRed),
                            child: const Text('Supprimer')),
                        ]));
                    }),
                ],
              ]),
            ));
        })),
    ]);
  }
}

class CategoryDialog extends StatefulWidget {
  final AppState state;
  final Category? cat;
  const CategoryDialog({super.key, required this.state, this.cat});
  @override State<CategoryDialog> createState() => _CatDialogState();
}
class _CatDialogState extends State<CategoryDialog> {
  final _name = TextEditingController(), _emoji = TextEditingController();
  String _color = '#1b3a5c'; int _status = 1;
  static const _colorPalette = [
    '#1b3a5c','#16a34a','#dc2626','#d97706',
    '#2563eb','#7c3aed','#0891b2','#ea580c','#be185d',
  ];

  @override void initState() {
    super.initState();
    final c = widget.cat;
    if (c != null) { _name.text = c.name; _emoji.text = c.emoji; _color = c.color; _status = c.status; }
    else _emoji.text = '🏷️';
  }
  @override void dispose() { _name.dispose(); _emoji.dispose(); super.dispose(); }

  @override Widget build(BuildContext ctx) {
    return AlertDialog(
      title: Text(widget.cat == null ? 'Nouvelle Catégorie' : 'Modifier Catégorie'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _name,
          decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: _emoji, textAlign: TextAlign.center,
          decoration: const InputDecoration(labelText: 'Emoji', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft,
          child: Text('Couleur', style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: _colorPalette.map((c) =>
          GestureDetector(
            onTap: () => setState(() => _color = c),
            child: Container(width: 32, height: 32,
              decoration: BoxDecoration(color: hexColor(c), shape: BoxShape.circle,
                border: Border.all(
                  color: _color == c ? Colors.white : Colors.transparent, width: 3),
                boxShadow: [if (_color == c) BoxShadow(color: hexColor(c).withOpacity(.5), blurRadius: 6)]))),
        ).toList()),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: _status,
          decoration: const InputDecoration(labelText: 'Statut', border: OutlineInputBorder()),
          items: const [DropdownMenuItem(value: 1, child: Text('Active')), DropdownMenuItem(value: 0, child: Text('Inactive'))],
          onChanged: (v) => setState(() => _status = v!)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            final c = Category(
              id: widget.cat?.id ?? AppState.newId(), name: _name.text.trim(),
              emoji: _emoji.text.isEmpty ? '🏷️' : _emoji.text, color: _color, status: _status);
            widget.state.saveCategory(c);
            widget.state.logAct(widget.cat == null ? 'CATEGORY_ADD' : 'CATEGORY_EDIT', c.name);
            Navigator.pop(ctx);
          },
          child: const Text('💾 Enregistrer')),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// PAGE UTILISATEURS
// ═══════════════════════════════════════════════
class UtilisateursPage extends StatelessWidget {
  const UtilisateursPage({super.key});
  @override
  Widget build(BuildContext ctx) {
    final st      = ctx.watch<AppState>();
    final isAdmin = st.currentUser?.role == 'Admin';
    return Column(children: [
      if (isAdmin) Padding(padding: const EdgeInsets.all(10),
        child: Align(alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.person_add, size: 16), label: const Text('Nouvel Utilisateur'),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
            onPressed: () => showDialog(context: ctx, builder: (_) => UserDialog(state: st))))),
      Expanded(child: ListView.builder(
        itemCount: st.users.length,
        itemBuilder: (ctx, i) {
          final u  = st.users[i];
          final rb = {'Admin': kRed, 'Superviseur': kOrange, 'Vendeur': kBlue}[u.role] ?? Colors.grey;
          return Card(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: u.avatarColor,
                child: Text(u.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
              title: Text('${u.prenom} ${u.nom}', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('@${u.username}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                if (u.lastLogin.isNotEmpty)
                  Text('Connexion: ${u.lastLogin.substring(0, 16).replaceAll('T', ' ')}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ]),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: rb.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(u.role, style: TextStyle(color: rb, fontWeight: FontWeight.w800, fontSize: 11))),
                if (isAdmin && u.id != st.currentUser!.id) ...[
                  IconButton(icon: const Icon(Icons.edit, size: 16), padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => showDialog(context: ctx, builder: (_) => UserDialog(state: st, user: u))),
                  IconButton(icon: const Icon(Icons.delete, size: 16, color: kRed),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                    onPressed: () => showDialog(context: ctx, builder: (_) => AlertDialog(
                      title: Text('Supprimer "${u.prenom} ${u.nom}" ?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                        TextButton(
                          onPressed: () { st.deleteUser(u.id); st.logAct('USER_DELETE', '${u.prenom} ${u.nom}'); Navigator.pop(ctx); },
                          style: TextButton.styleFrom(foregroundColor: kRed),
                          child: const Text('Supprimer')),
                      ]))),
                ],
              ]),
            ));
        })),
    ]);
  }
}

class UserDialog extends StatefulWidget {
  final AppState state;
  final AppUser? user;
  const UserDialog({super.key, required this.state, this.user});
  @override State<UserDialog> createState() => _UserDialogState();
}
class _UserDialogState extends State<UserDialog> {
  final _prenom = TextEditingController(), _nom = TextEditingController();
  final _un = TextEditingController(), _pw = TextEditingController();
  final _tel = TextEditingController(), _email = TextEditingController();
  String _role = 'Vendeur'; int _status = 1;
  bool _showPw = false;

  @override void initState() {
    super.initState();
    final u = widget.user;
    if (u != null) {
      _prenom.text = u.prenom; _nom.text = u.nom; _un.text = u.username;
      _tel.text = u.tel; _email.text = u.email; _role = u.role; _status = u.status;
    }
  }
  @override void dispose() {
    _prenom.dispose(); _nom.dispose(); _un.dispose();
    _pw.dispose(); _tel.dispose(); _email.dispose(); super.dispose();
  }

  @override Widget build(BuildContext ctx) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Nouvel Utilisateur' : 'Modifier Utilisateur'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: TextField(controller: _prenom,
            decoration: const InputDecoration(labelText: 'Prénom *', border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _nom,
            decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder()))),
        ]),
        const SizedBox(height: 10),
        TextField(controller: _un, autocorrect: false,
          decoration: const InputDecoration(labelText: "Nom d'utilisateur *", border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: _pw, obscureText: !_showPw,
          decoration: InputDecoration(
            labelText: widget.user == null ? 'Mot de passe *' : 'Mot de passe (vide=inchangé)',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_showPw ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _showPw = !_showPw)))),
        const SizedBox(height: 10),
        TextField(controller: _email, keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: _tel, keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _role,
          decoration: const InputDecoration(labelText: 'Rôle', border: OutlineInputBorder()),
          items: ['Vendeur','Superviseur','Admin']
            .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => setState(() => _role = v!)),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: _status,
          decoration: const InputDecoration(labelText: 'Statut', border: OutlineInputBorder()),
          items: const [DropdownMenuItem(value: 1, child: Text('Actif')), DropdownMenuItem(value: 0, child: Text('Inactif'))],
          onChanged: (v) => setState(() => _status = v!)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
          onPressed: () => _save(ctx),
          child: const Text('💾 Enregistrer')),
      ],
    );
  }

  void _save(BuildContext ctx) {
    final st = widget.state;
    if (_prenom.text.trim().isEmpty || _nom.text.trim().isEmpty || _un.text.trim().isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Remplissez les champs obligatoires !')));
      return;
    }
    if (widget.user == null && _pw.text.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Mot de passe requis !')));
      return;
    }
    final dup = st.users.any((u) => u.username == _un.text.trim() && u.id != (widget.user?.id ?? -1));
    if (dup) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Nom d'utilisateur déjà utilisé !")));
      return;
    }
    final u = AppUser(
      id: widget.user?.id ?? AppState.newId(),
      username: _un.text.trim(),
      password: _pw.text.isEmpty ? (widget.user?.password ?? '') : _pw.text,
      prenom: _prenom.text.trim(), nom: _nom.text.trim(),
      tel: _tel.text.trim(), email: _email.text.trim(),
      role: _role, status: _status, lastLogin: widget.user?.lastLogin ?? '');
    st.saveUser(u);
    st.logAct(widget.user == null ? 'USER_ADD' : 'USER_EDIT', '${u.prenom} ${u.nom} (${u.role})');
    Navigator.pop(ctx);
  }
}

// ═══════════════════════════════════════════════
// PAGE RAPPORTS
// ═══════════════════════════════════════════════
class RapportsPage extends StatefulWidget {
  const RapportsPage({super.key});
  @override State<RapportsPage> createState() => _RapportState();
}
class _RapportState extends State<RapportsPage> {
  String _period = 'week';

  @override Widget build(BuildContext ctx) {
    final st  = ctx.watch<AppState>();
    final now = DateTime.now();
    List<Sale> filtered;
    switch (_period) {
      case 'today': filtered = st.sales.where((s) => s.date.isAfter(DateTime(now.year,now.month,now.day))).toList(); break;
      case 'month': filtered = st.sales.where((s) => s.date.isAfter(DateTime(now.year,now.month,1))).toList(); break;
      case 'all':   filtered = st.sales; break;
      default:      filtered = st.sales.where((s) => s.date.isAfter(now.subtract(const Duration(days:7)))).toList();
    }
    final tot = filtered.fold(0.0, (s, t) => s + t.total);
    final ht  = filtered.fold(0.0, (s, t) => s + t.subtotal);
    final tax = filtered.fold(0.0, (s, t) => s + t.tax);
    final avg = filtered.isEmpty ? 0.0 : tot / filtered.length;

    return Column(children: [
      // Period selector
      Padding(padding: const EdgeInsets.all(10),
        child: SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'today', label: Text("Auj.", style: TextStyle(fontSize: 11))),
            ButtonSegment(value: 'week',  label: Text('7 jours', style: TextStyle(fontSize: 11))),
            ButtonSegment(value: 'month', label: Text('Mois', style: TextStyle(fontSize: 11))),
            ButtonSegment(value: 'all',   label: Text('Tout', style: TextStyle(fontSize: 11))),
          ],
          selected: {_period},
          onSelectionChanged: (s) => setState(() => _period = s.first))),
      Expanded(child: ListView(padding: const EdgeInsets.all(10), children: [
        // Stats
        GridView.count(crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.7,
          children: [
            _statCard('💰', 'CA TTC',         st.fmtP(tot), kGreen),
            _statCard('📄', 'HT',             st.fmtP(ht),  kBlue),
            _statCard('🏷️', 'TVA collectée', st.fmtP(tax), kPurple),
            _statCard('🛒', 'Panier moyen',   st.fmtP(avg), kOrange),
            _statCard('🧾', 'Transactions',   '${filtered.length}', kPrimary),
          ]),
        const SizedBox(height: 12),
        // Transactions table
        Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.all(12),
            child: Text('📋 Transactions', style: TextStyle(fontWeight: FontWeight.w900, color: kPrimary))),
          const Divider(height: 1),
          if (filtered.isEmpty)
            const Padding(padding: EdgeInsets.all(20),
              child: Center(child: Text('Aucune transaction', style: TextStyle(color: Colors.grey))))
          else ...filtered.take(50).map((s) => ListTile(
            dense: true,
            leading: CircleAvatar(backgroundColor: kBlue.withOpacity(.1), radius: 16,
              child: Text('#', style: const TextStyle(color: kBlue, fontWeight: FontWeight.w900, fontSize: 11))),
            title: Text(st.fmtP(s.total),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kGreen)),
            subtitle: Text('${fmtDT(s.date)} · ${s.cashier} · ${s.totalQty} art.',
              style: const TextStyle(fontSize: 10)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: kBlue.withOpacity(.1), borderRadius: BorderRadius.circular(12)),
              child: Text(s.method, style: const TextStyle(color: kBlue, fontWeight: FontWeight.w700, fontSize: 10))),
          )),
        ])),
        const SizedBox(height: 12),
        // Clear sales button
        ElevatedButton.icon(
          icon: const Icon(Icons.delete_forever, size: 16), label: const Text("Effacer l'historique"),
          style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white),
          onPressed: () => showDialog(context: ctx, builder: (_) => AlertDialog(
            title: const Text("Effacer tout l'historique des ventes ?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              TextButton(
                onPressed: () { st.clearSales(); st.logAct('HISTORY_CLEAR', 'Historique effacé'); Navigator.pop(ctx); },
                style: TextButton.styleFrom(foregroundColor: kRed), child: const Text('Effacer')),
            ]))),
      ])),
    ]);
  }

  Widget _statCard(String ic, String lbl, String val, Color col) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: col.withOpacity(.08), borderRadius: BorderRadius.circular(12),
      border: Border(left: BorderSide(color: col, width: 4))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(ic, style: const TextStyle(fontSize: 20)),
      const Spacer(),
      Text(val, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: col)),
      Text(lbl, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]));
}

// ═══════════════════════════════════════════════
// PAGE JOURNAL D'ACTIVITÉ
// ═══════════════════════════════════════════════
class LogsPage extends StatefulWidget {
  const LogsPage({super.key});
  @override State<LogsPage> createState() => _LogsState();
}
class _LogsState extends State<LogsPage> {
  String _filter = '';

  static const _logIcons = {
    'LOGIN':'🔑', 'LOGIN_FAIL':'⚠️', 'LOGOUT':'🚪',
    'SALE':'💰', 'RECEIPT':'🧾', 'HISTORY_CLEAR':'🗑️',
    'PRODUCT_ADD':'➕', 'PRODUCT_EDIT':'✏️', 'PRODUCT_DELETE':'🗑️',
    'CATEGORY_ADD':'➕', 'CATEGORY_EDIT':'✏️', 'CATEGORY_DELETE':'🗑️',
    'USER_ADD':'👤', 'USER_EDIT':'✏️', 'USER_DELETE':'🗑️',
    'SETTINGS_CHANGE':'⚙️',
  };

  @override Widget build(BuildContext ctx) {
    final st   = ctx.watch<AppState>();
    final logs = _filter.isEmpty
      ? st.logs
      : st.logs.where((l) => l.action.startsWith(_filter)).toList();

    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            value: _filter,
            decoration: const InputDecoration(labelText: 'Filtrer par action', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: '', child: Text('Toutes actions')),
              ...['LOGIN','LOGOUT','SALE','PRODUCT','CATEGORY','USER','SETTINGS']
                .map((a) => DropdownMenuItem(value: a, child: Text(a))),
            ],
            onChanged: (v) => setState(() => _filter = v ?? ''))),
          const SizedBox(width: 8),
          if (st.currentUser?.role == 'Admin')
            ElevatedButton.icon(
              icon: const Icon(Icons.delete, size: 16), label: const Text('Effacer'),
              style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white),
              onPressed: () => showDialog(context: ctx, builder: (_) => AlertDialog(
                title: const Text("Effacer le journal d'activité ?"),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                  TextButton(
                    onPressed: () { st.clearLogs(); Navigator.pop(ctx); },
                    style: TextButton.styleFrom(foregroundColor: kRed), child: const Text('Effacer')),
                ]))),
        ])),
      const SizedBox(height: 8),
      Expanded(child: logs.isEmpty
        ? const Center(child: Text('Aucune activité enregistrée', style: TextStyle(color: Colors.grey)))
        : ListView.builder(
            itemCount: logs.length,
            itemBuilder: (ctx, i) {
              final l  = logs[i];
              final ic = _logIcons[l.action] ?? '📌';
              final rb = {'Admin': kRed, 'Superviseur': kOrange, 'Vendeur': kBlue}[l.role] ?? Colors.grey;
              return ListTile(
                dense: true,
                leading: CircleAvatar(backgroundColor: kPrimary.withOpacity(.1), radius: 18,
                  child: Text(ic, style: const TextStyle(fontSize: 14))),
                title: Row(children: [
                  Text(l.action,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(width: 6),
                  if (l.role.isNotEmpty)
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: rb.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
                      child: Text(l.role, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: rb))),
                ]),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.details, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${l.prenom.isNotEmpty ? l.prenom : l.user} · ${fmtDT(l.date)}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ]),
              );
            })),
    ]);
  }
}

// ═══════════════════════════════════════════════
// PAGE PARAMÈTRES
// ═══════════════════════════════════════════════
class ParametresPage extends StatefulWidget {
  const ParametresPage({super.key});
  @override State<ParametresPage> createState() => _ParamState();
}
class _ParamState extends State<ParametresPage> {
  final _name   = TextEditingController();
  final _slogan = TextEditingController();
  final _addr   = TextEditingController();
  final _city   = TextEditingController();
  final _tel    = TextEditingController();
  final _email  = TextEditingController();
  final _mf     = TextEditingController();
  final _rne    = TextEditingController();
  final _msg    = TextEditingController();
  final _logo   = TextEditingController();
  String _cur = 'DT'; int _tva = 19;
  bool _loaded = false;

  @override void dispose() {
    _name.dispose(); _slogan.dispose(); _addr.dispose(); _city.dispose();
    _tel.dispose(); _email.dispose(); _mf.dispose(); _rne.dispose();
    _msg.dispose(); _logo.dispose(); super.dispose();
  }

  void _load(AppSettings s) {
    if (_loaded) return;
    _name.text = s.name; _slogan.text = s.slogan; _addr.text = s.addr;
    _city.text = s.city; _tel.text = s.tel; _email.text = s.email;
    _mf.text = s.mf; _rne.text = s.rne; _msg.text = s.msg;
    _logo.text = s.logo; _cur = s.cur; _tva = s.tva;
    _loaded = true;
  }

  @override Widget build(BuildContext ctx) {
    final st = ctx.watch<AppState>();
    _load(st.settings);
    return ListView(padding: const EdgeInsets.all(14), children: [
      _section('🏪 Informations du Magasin', [
        _field(_name,   'Nom du Magasin'),
        _field(_slogan, 'Slogan'),
        _field(_addr,   'Adresse'),
        _field(_city,   'Ville'),
        _field(_tel,    'Téléphone', type: TextInputType.phone),
        _field(_email,  'Email',     type: TextInputType.emailAddress),
      ]),
      _section('🏛️ Fiscal & TVA', [
        _field(_mf,  'Matricule Fiscale'),
        _field(_rne, 'N° RNE'),
        Row(children: [
          Expanded(child: DropdownButtonFormField<int>(
            value: _tva,
            decoration: const InputDecoration(labelText: 'TVA par défaut', border: OutlineInputBorder()),
            items: [0,7,13,19].map((v) => DropdownMenuItem(value: v, child: Text('$v%'))).toList(),
            onChanged: (v) => setState(() => _tva = v!))),
          const SizedBox(width: 10),
          Expanded(child: DropdownButtonFormField<String>(
            value: _cur,
            decoration: const InputDecoration(labelText: 'Devise', border: OutlineInputBorder()),
            items: ['DT','€','\$','MAD','DZD']
              .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _cur = v!))),
        ]),
        _field(_msg, 'Message sur ticket'),
      ]),
      _section('🎨 Apparence', [
        _field(_logo, 'Logo Emoji', max: 4),
      ]),
      const SizedBox(height: 8),
      ElevatedButton.icon(
        icon: const Icon(Icons.save), label: const Text('Enregistrer les Paramètres'),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary, foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48)),
        onPressed: () {
          final s = AppSettings(
            name: _name.text.trim().isEmpty ? 'Mon SuperMarché' : _name.text.trim(),
            slogan: _slogan.text.trim(), addr: _addr.text.trim(),
            city: _city.text.trim(), tel: _tel.text.trim(), email: _email.text.trim(),
            mf: _mf.text.trim(), rne: _rne.text.trim(), msg: _msg.text.trim(),
            logo: _logo.text.isEmpty ? '🛒' : _logo.text, cur: _cur, tva: _tva);
          st.saveSettings(s);
          st.logAct('SETTINGS_CHANGE', 'Paramètres mis à jour');
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('✅ Paramètres enregistrés !'), backgroundColor: kGreen));
        }),
    ]);
  }

  Widget _section(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: kPrimary))),
      ...children.map((w) => Padding(padding: const EdgeInsets.only(bottom: 10), child: w)),
      const SizedBox(height: 4),
    ]);

  Widget _field(TextEditingController c, String lbl,
    {TextInputType type = TextInputType.text, int? max}) =>
    TextField(controller: c, keyboardType: type, maxLength: max,
      decoration: InputDecoration(
        labelText: lbl, border: const OutlineInputBorder(), counterText: ''));
}

// ═══════════════════════════════════════════════
// PAGE GESTION DES STOCKS
// ═══════════════════════════════════════════════
class StocksPage extends StatefulWidget {
  const StocksPage({super.key});
  @override State<StocksPage> createState() => _StocksState();
}
class _StocksState extends State<StocksPage> {
  String _filter = 'all';
  final _srch = TextEditingController();

  @override void dispose() { _srch.dispose(); super.dispose(); }

  @override Widget build(BuildContext ctx) {
    final st  = ctx.watch<AppState>();
    final q   = _srch.text.toLowerCase();
    var prods = st.products.where((p) => p.status == 1).toList();
    if (q.isNotEmpty) prods = prods.where((p) => p.name.toLowerCase().contains(q)).toList();
    switch (_filter) {
      case 'low':  prods = prods.where((p) => p.stock > 0 && p.stock <= 10).toList(); break;
      case 'zero': prods = prods.where((p) => p.stock == 0).toList(); break;
    }
    prods.sort((a, b) => a.stock.compareTo(b.stock));

    final lowCount  = st.products.where((p) => p.stock > 0 && p.stock <= 10).length;
    final zeroCount = st.products.where((p) => p.stock == 0).length;

    return Column(children: [
      // Alert banner
      if (lowCount > 0 || zeroCount > 0)
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: kOrange.withOpacity(.15),
          child: Row(children: [
            const Text('⚠️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(child: Text(
              '$zeroCount en rupture · $lowCount stock faible',
              style: const TextStyle(fontWeight: FontWeight.w700, color: kOrange))),
          ])),
      // Search + filter
      Padding(padding: const EdgeInsets.all(10), child: Column(children: [
        TextField(controller: _srch,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search), hintText: 'Rechercher produit...',
            contentPadding: EdgeInsets.symmetric(vertical: 8),
            border: OutlineInputBorder()),
          onChanged: (_) => setState(() {})),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'all',  label: Text('Tous (${st.products.where((p)=>p.status==1).length})', style: const TextStyle(fontSize: 11))),
            ButtonSegment(value: 'low',  label: Text('Faible ($lowCount)', style: const TextStyle(fontSize: 11))),
            ButtonSegment(value: 'zero', label: Text('Rupture ($zeroCount)', style: const TextStyle(fontSize: 11))),
          ],
          selected: {_filter},
          onSelectionChanged: (s) => setState(() => _filter = s.first)),
      ])),
      // List
      Expanded(child: prods.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(_filter == 'zero' ? '✅' : '📦', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(_filter == 'zero' ? 'Aucune rupture de stock !' : 'Aucun produit',
              style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ]))
        : ListView.builder(
            itemCount: prods.length,
            itemBuilder: (ctx, i) {
              final pr  = prods[i];
              final col = pr.stock == 0 ? kRed : pr.stock <= 5 ? kOrange : pr.stock <= 10 ? Color(0xFFca8a04) : kGreen;
              return Card(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                child: ListTile(
                  leading: Stack(alignment: Alignment.topRight, children: [
                    Text(pr.emoji, style: const TextStyle(fontSize: 28)),
                    if (pr.stock == 0)
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle)),
                  ]),
                  title: Text(pr.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  subtitle: Text(st.fmtP(pr.priceTTC), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: col.withOpacity(.12), borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: col.withOpacity(.3))),
                      child: Text(pr.stock == 0 ? '⚠ Rupture' : '${pr.stock} unités',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: col))),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: kPrimary),
                      onPressed: () => _showStockDialog(ctx, st, pr)),
                  ]),
                ));
            })),
    ]);
  }

  void _showStockDialog(BuildContext ctx, AppState st, Product pr) {
    final ctrl = TextEditingController(text: '${pr.stock}');
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: Text('📦 Stock — ${pr.name}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(pr.emoji, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Stock actuel : ', style: const TextStyle(color: Colors.grey)),
          Text('${pr.stock}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        ]),
        const SizedBox(height: 16),
        TextField(controller: ctrl, keyboardType: TextInputType.number, autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          decoration: const InputDecoration(
            labelText: 'Nouveau stock', border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.inventory_2_outlined))),
        const SizedBox(height: 8),
        // Quick buttons
        Wrap(spacing: 8, runSpacing: 8, children: [0, 10, 20, 50, 100].map((v) =>
          ActionChip(label: Text('+$v'), onPressed: () {
            final cur = int.tryParse(ctrl.text) ?? 0;
            ctrl.text = '${cur + v}';
          })).toList()),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.white),
          onPressed: () async {
            final newStock = int.tryParse(ctrl.text) ?? pr.stock;
            final updated = Product(id: pr.id, name: pr.name, cat: pr.cat, price: pr.price,
              tva: pr.tva, stock: newStock, emoji: pr.emoji, barcode: pr.barcode, status: pr.status);
            await st.saveProduct(updated);
            st.logAct('STOCK_UPDATE', '${pr.name} : ${pr.stock} → $newStock');
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('✔ Enregistrer')),
      ],
    ));
  }
}

// ═══════════════════════════════════════════════
// WIDGET : CALCULATRICE FLOTTANTE (FAB)
// ═══════════════════════════════════════════════
class CalculatriceButton extends StatelessWidget {
  const CalculatriceButton({super.key});
  @override
  Widget build(BuildContext ctx) => FloatingActionButton(
    mini: true,
    backgroundColor: kPrimary2,
    foregroundColor: Colors.white,
    tooltip: 'Calculatrice',
    onPressed: () => showDialog(context: ctx, builder: (_) => const CalculatriceDialog()),
    child: const Icon(Icons.calculate_outlined, size: 20),
  );
}

class CalculatriceDialog extends StatefulWidget {
  const CalculatriceDialog({super.key});
  @override State<CalculatriceDialog> createState() => _CalcState();
}
class _CalcState extends State<CalculatriceDialog> {
  String _display = '0';
  String _expr    = '';
  double _prev    = 0;
  String _op      = '';
  bool   _newNum  = true;

  void _press(String val) {
    setState(() {
      if (val == 'C') {
        _display = '0'; _expr = ''; _prev = 0; _op = ''; _newNum = true; return;
      }
      if (val == '⌫') {
        if (_display.length > 1) _display = _display.substring(0, _display.length - 1);
        else _display = '0';
        return;
      }
      if (val == '±') { _display = _display.startsWith('-') ? _display.substring(1) : '-$_display'; return; }
      if (val == '%') { _display = '${(double.tryParse(_display) ?? 0) / 100}'; return; }
      if (['+', '−', '×', '÷'].contains(val)) {
        _prev = double.tryParse(_display) ?? 0; _op = val; _newNum = true;
        _expr = '$_display $val'; return;
      }
      if (val == '=') {
        final cur = double.tryParse(_display) ?? 0;
        double res;
        switch (_op) {
          case '+': res = _prev + cur; break;
          case '−': res = _prev - cur; break;
          case '×': res = _prev * cur; break;
          case '÷': res = cur != 0 ? _prev / cur : 0; break;
          default:  res = cur;
        }
        _expr = '$_expr $_display =';
        _display = res == res.toInt() ? '${res.toInt()}' : res.toStringAsFixed(3);
        _op = ''; _newNum = true; return;
      }
      if (val == '.') {
        if (_newNum) { _display = '0.'; _newNum = false; return; }
        if (!_display.contains('.')) _display += '.';
        return;
      }
      if (_newNum) { _display = val; _newNum = false; }
      else { _display = _display == '0' ? val : _display + val; }
    });
  }

  Widget _btn(String label, {Color? bg, Color? fg, int flex = 1}) {
    final isOp    = ['+', '−', '×', '÷', '='].contains(label);
    final isClear = label == 'C';
    return Expanded(flex: flex, child: Padding(padding: const EdgeInsets.all(3),
      child: ElevatedButton(
        onPressed: () => _press(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg ?? (isOp ? kPrimary : isClear ? kRed : Colors.grey.shade200),
          foregroundColor: fg ?? (isOp || isClear ? Colors.white : Colors.black87),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 1),
        child: Text(label, style: TextStyle(fontSize: isOp ? 20 : 17, fontWeight: FontWeight.w700)))));
  }

  @override Widget build(BuildContext ctx) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      content: SizedBox(width: 300, child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Expression
        Align(alignment: Alignment.centerRight,
          child: Text(_expr, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
        // Display
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: kPrimary.withOpacity(.06), borderRadius: BorderRadius.circular(8)),
          child: Text(_display, textAlign: TextAlign.right,
            style: TextStyle(fontSize: _display.length > 12 ? 18 : 28, fontWeight: FontWeight.w900, color: kPrimary),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
        const SizedBox(height: 10),
        // Keypad
        for (final row in [
          ['C', '±', '%', '÷'],
          ['7', '8', '9', '×'],
          ['4', '5', '6', '−'],
          ['1', '2', '3', '+'],
          ['⌫', '0', '.', '='],
        ]) Row(children: row.map((k) {
          if (k == '=') return _btn(k, bg: kGreen, fg: Colors.white);
          if (k == 'C') return _btn(k, bg: kRed, fg: Colors.white);
          if (k == '⌫') return _btn(k, bg: kOrange.withOpacity(.8), fg: Colors.white);
          if (['+','−','×','÷'].contains(k)) return _btn(k, bg: kPrimary, fg: Colors.white);
          return _btn(k);
        }).toList()),
        const SizedBox(height: 8),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
    );
  }
}

// ═══════════════════════════════════════════════
// PAGE BACKUP / RESTAURATION
// ═══════════════════════════════════════════════
class BackupPage extends StatelessWidget {
  const BackupPage({super.key});
  @override
  Widget build(BuildContext ctx) {
    final st = ctx.watch<AppState>();
    return ListView(padding: const EdgeInsets.all(16), children: [
      // DB Stats
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📊 Statistiques Base de Données',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kPrimary)),
        const Divider(),
        _statRow('Produits',       '${st.products.length}', Icons.inventory_2_outlined, kBlue),
        _statRow('Catégories',    '${st.categories.length}', Icons.label_outline, kPurple),
        _statRow('Utilisateurs',  '${st.users.length}', Icons.group_outlined, kOrange),
        _statRow('Ventes',        '${st.sales.length}', Icons.receipt_outlined, kGreen),
        _statRow('Logs',          '${st.logs.length}', Icons.list_alt_outlined, kTeal),
      ]))),
      const SizedBox(height: 12),
      // Export
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📤 Exporter les Données',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kPrimary)),
        const SizedBox(height: 12),
        const Text(
          'Exportez toutes vos données en JSON pour les sauvegarder ou les transférer.',
          style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.download_outlined),
          label: const Text('Exporter en JSON'),
          style: ElevatedButton.styleFrom(backgroundColor: kBlue, foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 44)),
          onPressed: () => _exportData(ctx, st)),
      ]))),
      const SizedBox(height: 12),
      // Reset
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('⚠️ Zone Dangereuse',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kRed)),
        const SizedBox(height: 8),
        const Text('Ces actions sont irréversibles !',
          style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.delete_forever),
          label: const Text("Effacer l'historique des ventes"),
          style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 44)),
          onPressed: () => _confirmClearSales(ctx, st)),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.history),
          label: const Text("Effacer le journal d'activité"),
          style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 44)),
          onPressed: () => _confirmClearLogs(ctx, st)),
      ]))),
    ]);
  }

  Widget _statRow(String label, String val, IconData ic, Color col) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(ic, size: 18, color: col),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(color: col.withOpacity(.1), borderRadius: BorderRadius.circular(20)),
        child: Text(val, style: TextStyle(fontWeight: FontWeight.w900, color: col))),
    ]));

  Future<void> _exportData(BuildContext ctx, AppState st) async {
    final data = {
      'exported_at': DateTime.now().toIso8601String(),
      'version': '3.0',
      'api': 'https://rzcode.tn/pos/api',
      'shop': st.settings.name,
      'categories_count': st.categories.length,
      'products_count': st.products.length,
      'sales_count': st.sales.length,
      'total_revenue': st.sales.fold(0.0, (s, t) => s + t.total),
    };
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('📤 Rapport JSON'),
      content: SizedBox(height: 300, child: SingleChildScrollView(
        child: SelectableText(jsonStr, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        TextButton(onPressed: () { Share.share(jsonStr, subject: 'Export POS'); }, child: const Text('Partager')),
      ],
    ));
  }

  void _confirmClearSales(BuildContext ctx, AppState st) => showDialog(
    context: ctx, builder: (_) => AlertDialog(
      title: const Text("⚠️ Effacer tout l'historique des ventes ?"),
      content: const Text('Cette action est irréversible. Toutes les ventes seront supprimées.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white),
          onPressed: () { st.clearSales(); st.logAct('HISTORY_CLEAR', 'Historique ventes effacé'); Navigator.pop(ctx); },
          child: const Text('Effacer')),
      ]));

  void _confirmClearLogs(BuildContext ctx, AppState st) => showDialog(
    context: ctx, builder: (_) => AlertDialog(
      title: const Text("⚠️ Effacer le journal ?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white),
          onPressed: () { st.clearLogs(); Navigator.pop(ctx); },
          child: const Text('Effacer')),
      ]));
}
