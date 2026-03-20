import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  final APIService _api;

  AppState(this._api);

  // ── Data ─────────────────────────────────────
  AppSettings    settings   = AppSettings();
  List<Category> categories = [];
  List<Product>  products   = [];
  List<Sale>     sales      = [];
  List<CartItem> cart       = [];
  bool loading  = true;
  bool darkMode = false;
  String page   = 'caisse';

  // ── Init ─────────────────────────────────────
  Future<void> init() async {
    loading = true;
    notifyListeners();
    await Future.wait([
      loadCategories(),
      loadProducts(),
      loadSales(),
      loadSettings(),
    ]);
    loading = false;
    notifyListeners();
  }

  // ── Settings ─────────────────────────────────
  Future<void> loadSettings() async {
    try {
      final r = await _api.getSettings();
      if (r['success'] == true && r['data'] != null) {
        settings = AppSettings.fromJson(r['data'] as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> saveSettings(AppSettings s) async {
    try {
      await _api.updateSettings(s);
      settings = s;
      notifyListeners();
    } catch (_) {}
  }

  String fmtP(double n) => '${n.toStringAsFixed(3)} ${settings.currency}';

  // ── Categories ────────────────────────────────
  Future<void> loadCategories() async {
    try {
      final r = await _api.getCategories();
      if (r['success'] == true) {
        categories = List<Category>.from(r['data'] ?? []);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> saveCategory(Map<String, dynamic> data) async {
    try {
      final r = data['id'] != null
          ? await _api.updateCategory(data['id'] as int, data)
          : await _api.createCategory(data);
      if (r['success'] == true) {
        await loadCategories();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final r = await _api.deleteCategory(id);
      if (r['success'] == true) {
        categories.removeWhere((c) => c.id == id);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ── Products ──────────────────────────────────
  Future<void> loadProducts() async {
    try {
      final r = await _api.getProducts();
      if (r['success'] == true) {
        products = List<Product>.from(r['data'] ?? []);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> saveProduct(Map<String, dynamic> data) async {
    try {
      final r = data['id'] != null
          ? await _api.updateProduct(data['id'] as int, data)
          : await _api.createProduct(data);
      if (r['success'] == true) {
        await loadProducts();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final r = await _api.deleteProduct(id);
      if (r['success'] == true) {
        products.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ── Sales ─────────────────────────────────────
  Future<void> loadSales() async {
    try {
      final r = await _api.getSales();
      if (r['success'] == true) {
        sales = List<Sale>.from(r['data'] ?? []);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<Sale?> processSale(String method, double given, double taxRate) async {
    if (cart.isEmpty) return null;
    final subtotal = cartSubtotal;
    final tax      = subtotal * (taxRate / 100);
    final total    = subtotal + tax;
    final change   = method == 'Espèces' ? (given - total).clamp(0.0, 1e9) : 0.0;

    final items = cart.map((ci) => {
      'product_id': ci.product.id,
      'name':       ci.product.name,
      'price':      ci.product.price,
      'quantity':   ci.quantity,
      'subtotal':   ci.product.price * ci.quantity,
    }).toList();

    final data = {
      'items':          jsonEncode(items),
      'subtotal':       subtotal,
      'tax':            tax,
      'total':          total,
      'payment_method': method,
      'given':          given,
      'change_amount':  change,
    };

    try {
      final r = await _api.createSale(data);
      if (r['success'] == true) {
        clearCart();
        await loadSales();
        return sales.isNotEmpty ? sales.first : null;
      }
    } catch (_) {}
    return null;
  }

  // ── Cart ──────────────────────────────────────
  void addToCart(Product p) {
    final i = cart.indexWhere((c) => c.product.id == p.id);
    if (i >= 0) cart[i].quantity++;
    else cart.add(CartItem(product: p, quantity: 1));
    notifyListeners();
  }

  void updateQty(int productId, int delta) {
    final i = cart.indexWhere((c) => c.product.id == productId);
    if (i < 0) return;
    cart[i].quantity += delta;
    if (cart[i].quantity <= 0) cart.removeAt(i);
    notifyListeners();
  }

  void removeFromCart(int productId) {
    cart.removeWhere((c) => c.product.id == productId);
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  double get cartSubtotal => cart.fold(0.0, (s, i) => s + i.product.price * i.quantity);
  int get cartCount       => cart.fold(0,   (s, i) => s + i.quantity);

  // ── Misc ──────────────────────────────────────
  void toggleDark() { darkMode = !darkMode; notifyListeners(); }
  void setPage(String p) { page = p; notifyListeners(); }
}
