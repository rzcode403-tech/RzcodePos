import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/app_state.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

// ══════════════════════════════════════════════
// COULEURS
// ══════════════════════════════════════════════
const kPrimary  = Color(0xFF1b3a5c);
const kPrimary2 = Color(0xFF234d7a);
const kAccent   = Color(0xFFe8a020);
const kGreen    = Color(0xFF16a34a);
const kRed      = Color(0xFFdc2626);
const kBlue     = Color(0xFF2563eb);
const kPurple   = Color(0xFF7c3aed);
const kOrange   = Color(0xFFea580c);
const kTeal     = Color(0xFF0891b2);

const kPayMethods = ['Espèces', 'Carte', 'Chèque', 'Mobile Pay'];

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

// ══════════════════════════════════════════════
// HOME SCREEN (Drawer navigation)
// ══════════════════════════════════════════════
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static const _titles = {
    'caisse':     'Point de Vente',
    'dashboard':  'Tableau de Bord',
    'produits':   'Produits',
    'categories': 'Catégories',
    'rapports':   'Rapports',
    'stocks':     'Gestion des Stocks',
    'parametres': 'Paramètres',
  };

  @override
  Widget build(BuildContext ctx) {
    final st   = ctx.watch<AppState>();
    final auth = ctx.watch<AuthProvider>();
    final user = auth.user;

    Widget body;
    switch (st.page) {
      case 'dashboard':  body = const DashboardPage();  break;
      case 'produits':   body = const ProduitsPage();   break;
      case 'categories': body = const CategoriesPage(); break;
      case 'rapports':   body = const RapportsPage();   break;
      case 'stocks':     body = const StocksPage();     break;
      case 'parametres': body = const ParametresPage(); break;
      default:           body = const CaissePage();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: Text(_titles[st.page] ?? 'POS',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        actions: [
          IconButton(
            icon: Icon(st.darkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: st.toggleDark),
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                backgroundColor: kAccent, radius: 17,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)))),
        ],
      ),
      drawer: const _AppDrawer(),
      body: SafeArea(child: body),
      floatingActionButton: st.page == 'caisse' ? const _CalcFab() : null,
    );
  }
}

// ══════════════════════════════════════════════
// DRAWER
// ══════════════════════════════════════════════
class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  static const _nav = [
    {'id': 'caisse',     'label': 'Point de Vente', 'icon': Icons.point_of_sale_outlined},
    {'id': 'dashboard',  'label': 'Tableau de Bord', 'icon': Icons.dashboard_outlined},
    {'id': 'produits',   'label': 'Produits',        'icon': Icons.inventory_2_outlined},
    {'id': 'categories', 'label': 'Catégories',      'icon': Icons.label_outline},
    {'id': 'rapports',   'label': 'Rapports',        'icon': Icons.bar_chart_outlined},
    {'id': 'stocks',     'label': 'Stock',           'icon': Icons.warehouse_outlined},
    {'id': 'parametres', 'label': 'Paramètres',      'icon': Icons.settings_outlined},
  ];

  @override
  Widget build(BuildContext ctx) {
    final st   = ctx.watch<AppState>();
    final auth = ctx.watch<AuthProvider>();
    final user = auth.user;

    return Drawer(child: SafeArea(child: Column(children: [
      Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(16,16,16,12),
        color: kPrimary,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🛒', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 4),
          Text(st.settings.shopName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
          Text('POS v3.0 • API',
            style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 10)),
        ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: kPrimary2,
        child: Row(children: [
          CircleAvatar(backgroundColor: kAccent, radius: 19,
            child: Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user?.name ?? '—',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            Text(user?.role ?? '—',
              style: TextStyle(color: Colors.white.withOpacity(.65), fontSize: 11)),
          ])),
        ])),
      Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 6), children: [
        for (final item in _nav)
          _tile(ctx, st, item),
      ])),
      Divider(color: Colors.white.withOpacity(.2), height: 1),
      ListTile(
        leading: Icon(Icons.logout, color: Colors.red.shade300, size: 20),
        title: Text('Déconnexion', style: TextStyle(color: Colors.red.shade300, fontWeight: FontWeight.w700, fontSize: 13)),
        onTap: () async {
          Navigator.pop(ctx);
          await auth.logout();
          if (ctx.mounted) Navigator.of(ctx).pushReplacementNamed('/login');
        }),
      const SizedBox(height: 6),
    ])));
  }

  Widget _tile(BuildContext ctx, AppState st, Map item) {
    final id       = item['id'] as String;
    final isActive = st.page == id;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(.13) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? const Border(left: BorderSide(color: kAccent, width: 3)) : null),
      child: ListTile(
        dense: true,
        leading: Icon(item['icon'] as IconData,
          color: isActive ? kAccent : Colors.white.withOpacity(.7), size: 20),
        title: Text(item['label'] as String,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(.75),
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600, fontSize: 13)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        onTap: () { st.setPage(id); Navigator.pop(ctx); },
      ));
  }
}

// ══════════════════════════════════════════════
// PAGE CAISSE
// ══════════════════════════════════════════════
class CaissePage extends StatefulWidget {
  const CaissePage({Key? key}) : super(key: key);
  @override State<CaissePage> createState() => _CaisseState();
}

class _CaisseState extends State<CaissePage> {
  final _srch = TextEditingController();
  String _cat = 'Tous';

  @override void dispose() { _srch.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext ctx) {
    final st = ctx.watch<AppState>();
    final isLandscape = MediaQuery.of(ctx).orientation == Orientation.landscape;
    return isLandscape
      ? Row(children: [
          Expanded(flex: 3, child: _products(ctx, st)),
          const VerticalDivider(width: 1),
          SizedBox(width: 300, child: _cart(ctx, st)),
        ])
      : Column(children: [
          Expanded(flex: 3, child: _products(ctx, st)),
          const Divider(height: 1),
          SizedBox(height: MediaQuery.of(ctx).size.height * .44, child: _cart(ctx, st)),
        ]);
  }

  Widget _products(BuildContext ctx, AppState st) {
    final cats  = st.categories;
    var prods   = st.products.where((p) => p.isActive).toList();
    final q     = _srch.text.toLowerCase();
    if (q.isNotEmpty) prods = prods.where((p) => p.name.toLowerCase().contains(q) || p.barcode.contains(q)).toList();
    if (_cat != 'Tous') {
      final c = cats.where((c) => c.name == _cat).firstOrNull;
      if (c != null) prods = prods.where((p) => p.categoryId == c.id).toList();
    }

    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(10,10,10,6),
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
              final p = st.products.where((p) => p.barcode == code && p.isActive).firstOrNull;
              if (p != null) { st.addToCart(p); _srch.clear(); setState(() {}); _snack(ctx, '✅ ${p.name} ajouté'); }
              else _snack(ctx, '⚠ Code non trouvé : $code');
            })),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.qr_code_scanner),
            style: IconButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
            onPressed: () => _openScanner(ctx, st)),
        ])),
      SizedBox(height: 44, child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [_chip('Tous'), ...cats.map((c) => _chip(c.name))])),
      Expanded(child: prods.isEmpty
        ? const Center(child: Text('Aucun produit trouvé', style: TextStyle(color: Colors.grey)))
        : GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 130, childAspectRatio: .75, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: prods.length,
            itemBuilder: (ctx, i) {
              final pr  = prods[i];
              final oos = pr.stock <= 0;
              return GestureDetector(
                onTap: oos ? null : () { st.addToCart(pr); _snack(ctx, '📦 ${pr.name}'); },
                child: Opacity(opacity: oos ? .4 : 1, child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 6)],
                    border: Border.all(color: Colors.grey.withOpacity(.15))),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('📦', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(pr.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                    const SizedBox(height: 4),
                    Text('${pr.price.toStringAsFixed(3)} ${context.read<AppState>().settings.currency}',
                      style: const TextStyle(color: kGreen, fontWeight: FontWeight.w900, fontSize: 11)),
                    Text(oos ? '⚠ Rupture' : '${pr.stock} en stock',
                      style: TextStyle(fontSize: 9, color: oos ? kRed : Colors.grey)),
                  ]),
                )));
            })),
    ]);
  }

  Widget _chip(String name) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: FilterChip(
      label: Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
        color: _cat == name ? Colors.white : null)),
      selected: _cat == name,
      onSelected: (_) => setState(() => _cat = name),
      selectedColor: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 2)));

  Widget _cart(BuildContext ctx, AppState st) {
    final taxRate = st.settings.taxRate.toDouble();
    final tax     = st.cartSubtotal * (taxRate / 100);
    final total   = st.cartSubtotal + tax;

    return Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: kPrimary,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('🛒 Panier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(20)),
            child: Text('${st.cartCount} art.',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
        ])),
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
                leading: const Text('📦', style: TextStyle(fontSize: 20)),
                title: Text(ci.product.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${ci.product.price.toStringAsFixed(3)} × ${ci.quantity}',
                  style: const TextStyle(fontSize: 10)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(ci.total.toStringAsFixed(3),
                    style: const TextStyle(color: kGreen, fontWeight: FontWeight.w900, fontSize: 11)),
                  const SizedBox(width: 4),
                  _qBtn('−', () => st.updateQty(ci.product.id!, -1)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('${ci.quantity}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13))),
                  _qBtn('+', () => st.updateQty(ci.product.id!,  1)),
                  const SizedBox(width: 2),
                  GestureDetector(onTap: () => st.removeFromCart(ci.product.id!),
                    child: const Icon(Icons.close, size: 16, color: kRed)),
                ]),
              );
            })),
      Container(
        padding: const EdgeInsets.fromLTRB(14,8,14,8),
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 8, offset: const Offset(0,-2))]),
        child: Column(children: [
          _sumRow('Sous-total HT', '${st.cartSubtotal.toStringAsFixed(3)} ${st.settings.currency}'),
          _sumRow('TVA (${st.settings.taxRate}%)', '${tax.toStringAsFixed(3)} ${st.settings.currency}'),
          const Divider(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TOTAL TTC', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kPrimary)),
            Text('${total.toStringAsFixed(3)} ${st.settings.currency}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kPrimary)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline, size: 15),
              label: const Text('Vider', style: TextStyle(fontSize: 12)),
              onPressed: st.cart.isEmpty ? null : () => _confirmClear(ctx, st),
              style: OutlinedButton.styleFrom(foregroundColor: kRed, side: const BorderSide(color: kRed)))),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: ElevatedButton.icon(
              icon: const Icon(Icons.payment, size: 15),
              label: const Text('ENCAISSER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              onPressed: st.cart.isEmpty ? null : () => _openPayment(ctx, st),
              style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.white, minimumSize: const Size(0, 44)))),
          ]),
        ])),
    ]);
  }

  Widget _qBtn(String l, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: Container(width: 20, height: 20, alignment: Alignment.center,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
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
        TextButton(onPressed: () { st.clearCart(); Navigator.pop(ctx); },
          style: TextButton.styleFrom(foregroundColor: kRed), child: const Text('Vider')),
      ]));

  void _openPayment(BuildContext ctx, AppState st) => showDialog(
    context: ctx, barrierDismissible: false,
    builder: (_) => PaymentDialog(state: st));

  Future<void> _openScanner(BuildContext ctx, AppState st) async {
    final code = await Navigator.push<String>(ctx, MaterialPageRoute(builder: (_) => const ScannerScreen()));
    if (code == null || !ctx.mounted) return;
    final api = ctx.read<APIService>();
    final p = await api.getByBarcode(code);
    if (p != null && ctx.mounted) {
      st.addToCart(p);
      _snack(ctx, '✅ ${p.name} ajouté');
    } else {
      _srch.text = code; setState(() {});
      if (ctx.mounted) _snack(ctx, '⚠ Code non trouvé : $code');
    }
  }
}

// ══════════════════════════════════════════════
// SCANNER
// ══════════════════════════════════════════════
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);
  @override State<ScannerScreen> createState() => _ScannerState();
}
class _ScannerState extends State<ScannerScreen> {
  final _manualCtrl = TextEditingController();
  bool _found = false;

  @override void dispose() { _manualCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(title: const Text('📷 Scanner Code Barres'), backgroundColor: kPrimary, foregroundColor: Colors.white),
    body: SafeArea(child: Column(children: [
      Expanded(flex: 3, child: Container(
        color: Colors.grey.shade900,
        child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.qr_code_scanner, size: 80, color: Colors.white38),
          SizedBox(height: 16),
          Text('Scanner non disponible\nUtilisez la saisie manuelle', textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14)),
        ])))),
      Container(color: Colors.grey.shade900, padding: const EdgeInsets.all(14), child: Column(children: [
        const Text('Saisir le code barres manuellement', style: TextStyle(color: Colors.white60, fontSize: 12)),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            onSubmitted: (v) { if (v.trim().isNotEmpty) Navigator.pop(ctx, v.trim()); })),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () { final v = _manualCtrl.text.trim(); if (v.isNotEmpty) Navigator.pop(ctx, v); },
            style: ElevatedButton.styleFrom(backgroundColor: kAccent, foregroundColor: Colors.white),
            child: const Text('✓')),
        ]),
      ])),
    ])),
  );
}

// ══════════════════════════════════════════════
// DIALOGUE PAIEMENT
// ══════════════════════════════════════════════
class PaymentDialog extends StatefulWidget {
  final AppState state;
  const PaymentDialog({Key? key, required this.state}) : super(key: key);
  @override State<PaymentDialog> createState() => _PayState();
}
class _PayState extends State<PaymentDialog> {
  String _method = '';
  final _givenCtrl = TextEditingController();
  double _change = 0;
  bool _loading = false;

  @override void dispose() { _givenCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext ctx) {
    final st    = widget.state;
    final tax   = st.cartSubtotal * (st.settings.taxRate / 100);
    final total = st.cartSubtotal + tax;
    return AlertDialog(
      title: Text('💳 Encaissement\n${total.toStringAsFixed(3)} ${st.settings.currency}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                  Text(m, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _method == m ? kGreen : null)),
                ])));
          }).toList()),
        if (_method == 'Espèces') ...[
          const SizedBox(height: 14),
          TextField(
            controller: _givenCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Montant remis', prefixIcon: Icon(Icons.payments_outlined), border: OutlineInputBorder()),
            onChanged: (v) {
              final g = double.tryParse(v.replaceAll(',', '.')) ?? 0;
              setState(() => _change = g - total);
            }),
          if (_givenCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _change >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Monnaie à rendre :', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text('${_change.abs().toStringAsFixed(3)} ${st.settings.currency}',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: _change >= 0 ? kGreen : kRed)),
              ])),
          ],
        ],
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: (_method.isEmpty || _loading) ? null : () => _confirm(ctx, st, total),
          style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.white),
          child: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('✔ Confirmer', style: TextStyle(fontWeight: FontWeight.w900))),
      ],
    );
  }

  Future<void> _confirm(BuildContext ctx, AppState st, double total) async {
    double given = 0;
    if (_method == 'Espèces') {
      given = double.tryParse(_givenCtrl.text.replaceAll(',', '.')) ?? 0;
      if (given > 0 && given < total) {
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('⚠ Montant insuffisant !'), backgroundColor: kRed));
        return;
      }
      if (given == 0) given = total;
    } else { given = total; }

    setState(() => _loading = true);
    final sale = await st.processSale(_method, given, st.settings.taxRate.toDouble());
    setState(() => _loading = false);

    if (!ctx.mounted) return;
    Navigator.pop(ctx);
    _showReceipt(ctx, st, total, given, _method);
  }

  void _showReceipt(BuildContext ctx, AppState st, double total, double given, String method) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('✅ Vente enregistrée !', textAlign: TextAlign.center),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🎉', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 8),
        Text('${total.toStringAsFixed(3)} ${st.settings.currency}',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: kGreen)),
        Text('Paiement: $method', style: const TextStyle(color: Colors.grey)),
        if (method == 'Espèces' && given > 0) ...[
          const SizedBox(height: 8),
          Text('Monnaie: ${(given - total).clamp(0, 1e9).toStringAsFixed(3)} ${st.settings.currency}',
            style: const TextStyle(fontWeight: FontWeight.w700, color: kBlue, fontSize: 16)),
        ],
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
    ));
  }
}

// ══════════════════════════════════════════════
// DASHBOARD
// ══════════════════════════════════════════════
class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext ctx) {
    final st       = ctx.watch<AppState>();
    final now      = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);
    final todaySales = st.sales.where((s) => s.createdAt?.isAfter(todayStart) == true).toList();
    final monthSales = st.sales.where((s) => s.createdAt?.isAfter(monthStart) == true).toList();
    final totToday   = todaySales.fold(0.0, (s, t) => s + t.total);
    final totMonth   = monthSales.fold(0.0, (s, t) => s + t.total);
    final totAll     = st.sales.fold(0.0, (s, t) => s + t.total);
    final avg        = st.sales.isEmpty ? 0.0 : totAll / st.sales.length;
    final lowStock   = st.products.where((p) => p.stock > 0 && p.stock <= p.minStock).length;
    final cur        = st.settings.currency;

    return RefreshIndicator(
      onRefresh: () async { await st.init(); },
      child: ListView(padding: const EdgeInsets.all(14), children: [
        GridView.count(crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.65,
          children: [
            _stat('💰', "Aujourd'hui",  '${totToday.toStringAsFixed(3)} $cur', kGreen),
            _stat('🧾', 'Tickets/jour', '${todaySales.length}',                 kBlue),
            _stat('📅', 'CA ce mois',   '${totMonth.toStringAsFixed(3)} $cur', kPrimary),
            _stat('🛒', 'Panier moyen', '${avg.toStringAsFixed(3)} $cur',       kPurple),
            _stat('⚠️', 'Stock faible', '$lowStock produits',                   kOrange),
            _stat('💳', 'CA total',     '${totAll.toStringAsFixed(3)} $cur',    kRed),
          ]),
        const SizedBox(height: 14),
        if (st.sales.isNotEmpty) ...[
          _sectionTitle('💳 Modes de Paiement'),
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
            ...() {
              final m = <String, double>{};
              for (final s in st.sales) m[s.paymentMethod] = (m[s.paymentMethod] ?? 0) + s.total;
              final tot  = m.values.fold(0.0, (a, b) => a + b);
              final cols = [kPrimary, kGreen, kAccent, kPurple, kRed];
              return m.entries.toList().asMap().entries.map((e) {
                final pct = tot > 0 ? e.value.value / tot : 0.0;
                return Padding(padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: cols[e.key % cols.length], shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e.value.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                    SizedBox(width: 120, child: ClipRRect(borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: Colors.grey.shade200, color: cols[e.key % cols.length]))),
                    const SizedBox(width: 8),
                    Text('${(pct * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                  ]));
              }).toList();
            }(),
          ]))),
        ],
        _sectionTitle('📋 Dernières Transactions'),
        ...st.sales.take(10).map((s) => Card(
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: ListTile(dense: true,
            leading: CircleAvatar(backgroundColor: kBlue.withOpacity(.12), radius: 18,
              child: Text('#${(s.id ?? 0) % 99}', style: const TextStyle(color: kBlue, fontWeight: FontWeight.w900, fontSize: 11))),
            title: Text('${s.total.toStringAsFixed(3)} $cur', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            subtitle: Text('${fmtDT(s.createdAt ?? DateTime.now())} · ${s.items.length} art.', style: const TextStyle(fontSize: 11)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: kBlue.withOpacity(.1), borderRadius: BorderRadius.circular(12)),
              child: Text(s.paymentMethod, style: const TextStyle(color: kBlue, fontWeight: FontWeight.w700, fontSize: 10)))))),
      ]));
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
      Text(val, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: col)),
      Text(lbl, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]));
}

// ══════════════════════════════════════════════
// PAGE PRODUITS
// ══════════════════════════════════════════════
class ProduitsPage extends StatefulWidget {
  const ProduitsPage({Key? key}) : super(key: key);
  @override State<ProduitsPage> createState() => _ProduitsState();
}
class _ProduitsState extends State<ProduitsPage> {
  final _srch = TextEditingController();
  @override void dispose() { _srch.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext ctx) {
    final st    = ctx.watch<AppState>();
    final q     = _srch.text.toLowerCase();
    final prods = st.products.where((p) =>
      q.isEmpty || p.name.toLowerCase().contains(q) || p.barcode.contains(q)).toList();

    return Column(children: [
      Padding(padding: const EdgeInsets.all(10), child: Row(children: [
        Expanded(child: TextField(controller: _srch,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search), hintText: 'Rechercher...',
            contentPadding: EdgeInsets.symmetric(vertical: 8), border: OutlineInputBorder()),
          onChanged: (_) => setState(() {}))),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16), label: const Text('Nouveau'),
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
          onPressed: () => showDialog(context: ctx, builder: (_) => ProductDialog(state: st))),
      ])),
      Expanded(child: RefreshIndicator(
        onRefresh: () => st.loadProducts(),
        child: prods.isEmpty
          ? const Center(child: Text('Aucun produit', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              itemCount: prods.length,
              itemBuilder: (ctx, i) {
                final pr  = prods[i];
                final cat = st.categories.where((c) => c.id == pr.categoryId).firstOrNull;
                return Card(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  child: ListTile(
                    leading: const Text('📦', style: TextStyle(fontSize: 26)),
                    title: Text(pr.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (pr.barcode.isNotEmpty)
                        Text(pr.barcode, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey)),
                      const SizedBox(height: 2),
                      Wrap(spacing: 4, children: [
                        _badge(cat?.name ?? '—', kBlue),
                        _badge('${pr.stock} en stock', pr.stock <= 0 ? kRed : pr.stock <= pr.minStock ? kOrange : kGreen),
                        if (!pr.isActive) _badge('Inactif', Colors.grey),
                      ]),
                    ]),
                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('${pr.price.toStringAsFixed(3)} ${st.settings.currency}',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: kGreen, fontSize: 13)),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.edit, size: 16), padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                          onPressed: () => showDialog(context: ctx, builder: (_) => ProductDialog(state: st, product: pr))),
                        IconButton(icon: const Icon(Icons.delete, size: 16, color: kRed), padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                          onPressed: () => _delete(ctx, st, pr)),
                      ]),
                    ]),
                  ));
              }))),
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
          onPressed: () async { await st.deleteProduct(pr.id!); if (ctx.mounted) Navigator.pop(ctx); },
          style: TextButton.styleFrom(foregroundColor: kRed), child: const Text('Supprimer')),
      ]));
}

class ProductDialog extends StatefulWidget {
  final AppState state;
  final Product? product;
  const ProductDialog({Key? key, required this.state, this.product}) : super(key: key);
  @override State<ProductDialog> createState() => _ProdDlgState();
}
class _ProdDlgState extends State<ProductDialog> {
  final _name = TextEditingController(), _price = TextEditingController();
  final _cost = TextEditingController(), _stock = TextEditingController();
  final _barcode = TextEditingController(), _desc = TextEditingController();
  int _catId = 0; bool _active = true; bool _loading = false;

  @override void initState() {
    super.initState();
    final pr = widget.product;
    if (pr != null) {
      _name.text = pr.name; _price.text = pr.price.toString();
      _cost.text  = pr.costPrice.toString(); _stock.text = pr.stock.toString();
      _barcode.text = pr.barcode; _desc.text = pr.description ?? '';
      _catId = pr.categoryId; _active = pr.isActive;
    } else {
      final cats = widget.state.categories;
      if (cats.isNotEmpty) _catId = cats.first.id ?? 0;
    }
  }
  @override void dispose() { _name.dispose(); _price.dispose(); _cost.dispose(); _stock.dispose(); _barcode.dispose(); _desc.dispose(); super.dispose(); }

  @override Widget build(BuildContext ctx) {
    final cats = widget.state.categories;
    return AlertDialog(
      title: Text(widget.product == null ? 'Nouveau Produit' : 'Modifier Produit'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Désignation *', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: _price, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Prix vente *', border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _cost, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Prix achat', border: OutlineInputBorder()))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: _stock, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _barcode,
            decoration: const InputDecoration(labelText: 'Code Barres', border: OutlineInputBorder()))),
        ]),
        const SizedBox(height: 10),
        if (cats.isNotEmpty)
          DropdownButtonFormField<int>(
            value: cats.any((c) => c.id == _catId) ? _catId : cats.first.id,
            decoration: const InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder()),
            items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) => setState(() => _catId = v ?? 0)),
        const SizedBox(height: 10),
        SwitchListTile(title: const Text('Actif'), value: _active, onChanged: (v) => setState(() => _active = v)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
          onPressed: _loading ? null : () => _save(ctx),
          child: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('💾 Enregistrer')),
      ],
    );
  }

  Future<void> _save(BuildContext ctx) async {
    if (_name.text.trim().isEmpty || _price.text.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Remplissez les champs obligatoires !')));
      return;
    }
    setState(() => _loading = true);
    final data = {
      if (widget.product?.id != null) 'id': widget.product!.id,
      'name': _name.text.trim(),
      'price': double.tryParse(_price.text.replaceAll(',', '.')) ?? 0,
      'cost_price': double.tryParse(_cost.text.replaceAll(',', '.')) ?? 0,
      'stock': int.tryParse(_stock.text) ?? 0,
      'barcode': _barcode.text.trim(),
      'category_id': _catId,
      'description': _desc.text.trim(),
      'is_active': _active ? 1 : 0,
    };
    final ok = await widget.state.saveProduct(data);
    setState(() => _loading = false);
    if (ctx.mounted) {
      Navigator.pop(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(ok ? '✅ Produit enregistré' : '❌ Erreur lors de l\'enregistrement'),
        backgroundColor: ok ? kGreen : kRed));
    }
  }
}

// ══════════════════════════════════════════════
// PAGE CATÉGORIES
// ══════════════════════════════════════════════
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext ctx) {
    final st = ctx.watch<AppState>();
    return Column(children: [
      Padding(padding: const EdgeInsets.all(10),
        child: Align(alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16), label: const Text('Nouvelle Catégorie'),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
            onPressed: () => showDialog(context: ctx, builder: (_) => CategoryDialog(state: st))))),
      Expanded(child: RefreshIndicator(
        onRefresh: () => st.loadCategories(),
        child: st.categories.isEmpty
          ? const Center(child: Text('Aucune catégorie', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              itemCount: st.categories.length,
              itemBuilder: (ctx, i) {
                final c   = st.categories[i];
                final cnt = st.products.where((p) => p.categoryId == c.id).length;
                return Card(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: hexColor(c.color),
                      child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('$cnt produit${cnt != 1 ? "s" : ""}'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (c.isActive ? kGreen : Colors.grey).withOpacity(.12),
                          borderRadius: BorderRadius.circular(20)),
                        child: Text(c.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c.isActive ? kGreen : Colors.grey))),
                      IconButton(icon: const Icon(Icons.edit, size: 16), padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                        onPressed: () => showDialog(context: ctx, builder: (_) => CategoryDialog(state: st, cat: c))),
                      IconButton(icon: const Icon(Icons.delete, size: 16, color: kRed), padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                        onPressed: () {
                          if (cnt > 0) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('⚠ Catégorie utilisée par des produits !'))); return; }
                          showDialog(context: ctx, builder: (_) => AlertDialog(
                            title: Text('Supprimer "${c.name}" ?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                              TextButton(
                                onPressed: () async { await st.deleteCategory(c.id!); if (ctx.mounted) Navigator.pop(ctx); },
                                style: TextButton.styleFrom(foregroundColor: kRed), child: const Text('Supprimer')),
                            ]));
                        }),
                    ]),
                  ));
              }))),
    ]);
  }
}

class CategoryDialog extends StatefulWidget {
  final AppState state;
  final Category? cat;
  const CategoryDialog({Key? key, required this.state, this.cat}) : super(key: key);
  @override State<CategoryDialog> createState() => _CatDlgState();
}
class _CatDlgState extends State<CategoryDialog> {
  final _name = TextEditingController();
  String _color = '#1b3a5c'; bool _active = true; bool _loading = false;
  static const _palette = ['#1b3a5c','#16a34a','#dc2626','#d97706','#2563eb','#7c3aed','#0891b2','#ea580c'];

  @override void initState() {
    super.initState();
    final c = widget.cat;
    if (c != null) { _name.text = c.name; _color = c.color; _active = c.isActive; }
  }
  @override void dispose() { _name.dispose(); super.dispose(); }

  @override Widget build(BuildContext ctx) => AlertDialog(
    title: Text(widget.cat == null ? 'Nouvelle Catégorie' : 'Modifier Catégorie'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      Align(alignment: Alignment.centerLeft, child: Text('Couleur', style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 8, children: _palette.map((c) => GestureDetector(
        onTap: () => setState(() => _color = c),
        child: Container(width: 32, height: 32,
          decoration: BoxDecoration(color: hexColor(c), shape: BoxShape.circle,
            border: Border.all(color: _color == c ? Colors.white : Colors.transparent, width: 3),
            boxShadow: [if (_color == c) BoxShadow(color: hexColor(c).withOpacity(.5), blurRadius: 6)])))).toList()),
      const SizedBox(height: 10),
      SwitchListTile(title: const Text('Active'), value: _active, onChanged: (v) => setState(() => _active = v)),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
        onPressed: _loading ? null : () => _save(ctx),
        child: const Text('💾 Enregistrer')),
    ],
  );

  Future<void> _save(BuildContext ctx) async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final data = {
      if (widget.cat?.id != null) 'id': widget.cat!.id,
      'name': _name.text.trim(), 'color': _color, 'is_active': _active ? 1 : 0,
    };
    await widget.state.saveCategory(data);
    setState(() => _loading = false);
    if (ctx.mounted) Navigator.pop(ctx);
  }
}

// ══════════════════════════════════════════════
// PAGE RAPPORTS
// ══════════════════════════════════════════════
class RapportsPage extends StatefulWidget {
  const RapportsPage({Key? key}) : super(key: key);
  @override State<RapportsPage> createState() => _RapportState();
}
class _RapportState extends State<RapportsPage> {
  String _period = 'week';
  @override Widget build(BuildContext ctx) {
    final st  = ctx.watch<AppState>();
    final now = DateTime.now();
    List<Sale> filtered;
    switch (_period) {
      case 'today': filtered = st.sales.where((s) => s.createdAt?.isAfter(DateTime(now.year,now.month,now.day)) == true).toList(); break;
      case 'month': filtered = st.sales.where((s) => s.createdAt?.isAfter(DateTime(now.year,now.month,1)) == true).toList(); break;
      case 'all':   filtered = st.sales; break;
      default:      filtered = st.sales.where((s) => s.createdAt?.isAfter(now.subtract(const Duration(days:7))) == true).toList();
    }
    final tot = filtered.fold(0.0, (s, t) => s + t.total);
    final ht  = filtered.fold(0.0, (s, t) => s + t.subtotal);
    final tax = filtered.fold(0.0, (s, t) => s + t.tax);
    final avg = filtered.isEmpty ? 0.0 : tot / filtered.length;
    final cur = st.settings.currency;

    return Column(children: [
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
      Expanded(child: RefreshIndicator(
        onRefresh: () => st.loadSales(),
        child: ListView(padding: const EdgeInsets.all(10), children: [
          GridView.count(crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.7,
            children: [
              _sc('💰', 'CA TTC',          '${tot.toStringAsFixed(3)} $cur', kGreen),
              _sc('📄', 'HT',              '${ht.toStringAsFixed(3)} $cur',  kBlue),
              _sc('🏷️', 'TVA collectée',  '${tax.toStringAsFixed(3)} $cur',  kPurple),
              _sc('🛒', 'Panier moyen',    '${avg.toStringAsFixed(3)} $cur',  kOrange),
              _sc('🧾', 'Transactions',    '${filtered.length}',              kPrimary),
            ]),
          const SizedBox(height: 12),
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
                child: const Text('#', style: TextStyle(color: kBlue, fontWeight: FontWeight.w900, fontSize: 11))),
              title: Text('${s.total.toStringAsFixed(3)} $cur', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kGreen)),
              subtitle: Text('${fmtDT(s.createdAt ?? DateTime.now())} · ${s.items.length} art.', style: const TextStyle(fontSize: 10)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: kBlue.withOpacity(.1), borderRadius: BorderRadius.circular(12)),
                child: Text(s.paymentMethod, style: const TextStyle(color: kBlue, fontWeight: FontWeight.w700, fontSize: 10))))),
          ])),
        ]))),
    ]);
  }

  Widget _sc(String ic, String lbl, String val, Color col) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: col.withOpacity(.08), borderRadius: BorderRadius.circular(12),
      border: Border(left: BorderSide(color: col, width: 4))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(ic, style: const TextStyle(fontSize: 20)),
      const Spacer(),
      Text(val, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: col)),
      Text(lbl, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]));
}

// ══════════════════════════════════════════════
// PAGE STOCKS
// ══════════════════════════════════════════════
class StocksPage extends StatefulWidget {
  const StocksPage({Key? key}) : super(key: key);
  @override State<StocksPage> createState() => _StocksState();
}
class _StocksState extends State<StocksPage> {
  String _filter = 'all';
  final _srch = TextEditingController();
  @override void dispose() { _srch.dispose(); super.dispose(); }

  @override Widget build(BuildContext ctx) {
    final st  = ctx.watch<AppState>();
    final q   = _srch.text.toLowerCase();
    var prods = st.products.where((p) => p.isActive).toList();
    if (q.isNotEmpty) prods = prods.where((p) => p.name.toLowerCase().contains(q)).toList();
    switch (_filter) {
      case 'low':  prods = prods.where((p) => p.stock > 0 && p.stock <= p.minStock).toList(); break;
      case 'zero': prods = prods.where((p) => p.stock == 0).toList(); break;
    }
    prods.sort((a, b) => a.stock.compareTo(b.stock));

    final lowCount  = st.products.where((p) => p.stock > 0 && p.stock <= p.minStock).length;
    final zeroCount = st.products.where((p) => p.stock == 0).length;

    return Column(children: [
      if (lowCount > 0 || zeroCount > 0)
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: kOrange.withOpacity(.15),
          child: Row(children: [
            const Text('⚠️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text('$zeroCount en rupture · $lowCount stock faible',
              style: const TextStyle(fontWeight: FontWeight.w700, color: kOrange)),
          ])),
      Padding(padding: const EdgeInsets.all(10), child: Column(children: [
        TextField(controller: _srch,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Rechercher...', contentPadding: EdgeInsets.symmetric(vertical: 8), border: OutlineInputBorder()),
          onChanged: (_) => setState(() {})),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'all',  label: Text('Tous (${st.products.where((p)=>p.isActive).length})', style: const TextStyle(fontSize: 11))),
            ButtonSegment(value: 'low',  label: Text('Faible ($lowCount)', style: const TextStyle(fontSize: 11))),
            ButtonSegment(value: 'zero', label: Text('Rupture ($zeroCount)', style: const TextStyle(fontSize: 11))),
          ],
          selected: {_filter},
          onSelectionChanged: (s) => setState(() => _filter = s.first)),
      ])),
      Expanded(child: RefreshIndicator(
        onRefresh: () => st.loadProducts(),
        child: prods.isEmpty
          ? const Center(child: Text('Aucun produit', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              itemCount: prods.length,
              itemBuilder: (ctx, i) {
                final pr  = prods[i];
                final col = pr.stock == 0 ? kRed : pr.stock <= pr.minStock ? kOrange : kGreen;
                return Card(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  child: ListTile(
                    leading: const Text('📦', style: TextStyle(fontSize: 28)),
                    title: Text(pr.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Text('${pr.price.toStringAsFixed(3)} ${st.settings.currency}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: col.withOpacity(.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: col.withOpacity(.3))),
                        child: Text(pr.stock == 0 ? '⚠ Rupture' : '${pr.stock} unités',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: col))),
                      const SizedBox(width: 8),
                      IconButton(icon: const Icon(Icons.edit_note, color: kPrimary),
                        onPressed: () => _showStockDialog(ctx, st, pr)),
                    ]),
                  ));
              }))),
    ]);
  }

  void _showStockDialog(BuildContext ctx, AppState st, Product pr) {
    final ctrl = TextEditingController(text: '${pr.stock}');
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: Text('📦 Stock — ${pr.name}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('📦', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Stock actuel : ', style: TextStyle(color: Colors.grey)),
          Text('${pr.stock}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        ]),
        const SizedBox(height: 16),
        TextField(controller: ctrl, keyboardType: TextInputType.number, autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          decoration: const InputDecoration(labelText: 'Nouveau stock', border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory_2_outlined))),
        const SizedBox(height: 8),
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
            await st.saveProduct({
              'id': pr.id, 'name': pr.name, 'price': pr.price, 'cost_price': pr.costPrice,
              'stock': newStock, 'barcode': pr.barcode, 'category_id': pr.categoryId,
              'is_active': pr.isActive ? 1 : 0,
            });
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('✔ Enregistrer')),
      ],
    ));
  }
}

// ══════════════════════════════════════════════
// PAGE PARAMÈTRES
// ══════════════════════════════════════════════
class ParametresPage extends StatefulWidget {
  const ParametresPage({Key? key}) : super(key: key);
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
  String _cur = 'DT'; int _tva = 19;
  bool _loaded = false;

  @override void dispose() { _name.dispose(); _slogan.dispose(); _addr.dispose(); _city.dispose(); _tel.dispose(); _email.dispose(); _mf.dispose(); _rne.dispose(); _msg.dispose(); super.dispose(); }

  void _load(AppSettings s) {
    if (_loaded) return;
    _name.text = s.shopName; _slogan.text = s.shopSlogan; _addr.text = s.shopAddress;
    _city.text = s.shopCity; _tel.text  = s.shopPhone;  _email.text = s.shopEmail;
    _mf.text   = s.shopMF;   _rne.text  = s.shopRNE;   _msg.text   = s.welcomeMessage;
    _cur = s.currency; _tva = s.taxRate; _loaded = true;
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
        _field(_mf, 'Matricule Fiscale'),
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
            items: ['DT','€','\$','MAD','DZD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _cur = v!))),
        ]),
        _field(_msg, 'Message sur ticket'),
      ]),
      const SizedBox(height: 8),
      ElevatedButton.icon(
        icon: const Icon(Icons.save), label: const Text('Enregistrer les Paramètres'),
        style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48)),
        onPressed: () async {
          final s = AppSettings(
            shopName: _name.text.trim().isEmpty ? 'Mon SuperMarché' : _name.text.trim(),
            shopSlogan: _slogan.text.trim(), shopAddress: _addr.text.trim(),
            shopCity: _city.text.trim(), shopPhone: _tel.text.trim(), shopEmail: _email.text.trim(),
            shopMF: _mf.text.trim(), shopRNE: _rne.text.trim(), welcomeMessage: _msg.text.trim(),
            currency: _cur, taxRate: _tva);
          await st.saveSettings(s);
          if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('✅ Paramètres enregistrés !'), backgroundColor: kGreen));
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

  Widget _field(TextEditingController c, String lbl, {TextInputType type = TextInputType.text}) =>
    TextField(controller: c, keyboardType: type,
      decoration: InputDecoration(labelText: lbl, border: const OutlineInputBorder()));
}

// ══════════════════════════════════════════════
// CALCULATRICE FAB
// ══════════════════════════════════════════════
class _CalcFab extends StatelessWidget {
  const _CalcFab();
  @override Widget build(BuildContext ctx) => FloatingActionButton(
    mini: true, backgroundColor: kPrimary2, foregroundColor: Colors.white,
    tooltip: 'Calculatrice',
    onPressed: () => showDialog(context: ctx, builder: (_) => const _CalcDialog()),
    child: const Icon(Icons.calculate_outlined, size: 20));
}

class _CalcDialog extends StatefulWidget {
  const _CalcDialog();
  @override State<_CalcDialog> createState() => _CalcState();
}
class _CalcState extends State<_CalcDialog> {
  String _display = '0', _expr = '';
  double _prev = 0; String _op = ''; bool _newNum = true;

  void _press(String val) {
    setState(() {
      if (val == 'C') { _display = '0'; _expr = ''; _prev = 0; _op = ''; _newNum = true; return; }
      if (val == '⌫') { _display = _display.length > 1 ? _display.substring(0, _display.length - 1) : '0'; return; }
      if (val == '±') { _display = _display.startsWith('-') ? _display.substring(1) : '-$_display'; return; }
      if (val == '%') { _display = '${(double.tryParse(_display) ?? 0) / 100}'; return; }
      if (['+','−','×','÷'].contains(val)) { _prev = double.tryParse(_display) ?? 0; _op = val; _newNum = true; _expr = '$_display $val'; return; }
      if (val == '=') {
        final cur = double.tryParse(_display) ?? 0;
        double res;
        switch (_op) {
          case '+': res = _prev + cur; break; case '−': res = _prev - cur; break;
          case '×': res = _prev * cur; break; case '÷': res = cur != 0 ? _prev / cur : 0; break;
          default:  res = cur;
        }
        _expr = '$_expr $_display =';
        _display = res == res.toInt() ? '${res.toInt()}' : res.toStringAsFixed(3);
        _op = ''; _newNum = true; return;
      }
      if (val == '.') { if (_newNum) { _display = '0.'; _newNum = false; return; } if (!_display.contains('.')) _display += '.'; return; }
      if (_newNum) { _display = val; _newNum = false; }
      else { _display = _display == '0' ? val : _display + val; }
    });
  }

  Widget _btn(String l, {Color? bg, Color? fg}) {
    final isOp = ['+','−','×','÷','='].contains(l);
    final isCl = l == 'C';
    return Expanded(child: Padding(padding: const EdgeInsets.all(3),
      child: ElevatedButton(
        onPressed: () => _press(l),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg ?? (isOp ? kPrimary : isCl ? kRed : Colors.grey.shade200),
          foregroundColor: fg ?? (isOp || isCl ? Colors.white : Colors.black87),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 1),
        child: Text(l, style: TextStyle(fontSize: isOp ? 20 : 17, fontWeight: FontWeight.w700)))));
  }

  @override Widget build(BuildContext ctx) => AlertDialog(
    contentPadding: const EdgeInsets.fromLTRB(12,12,12,0),
    content: SizedBox(width: 300, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Align(alignment: Alignment.centerRight, child: Text(_expr, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: kPrimary.withOpacity(.06), borderRadius: BorderRadius.circular(8)),
        child: Text(_display, textAlign: TextAlign.right,
          style: TextStyle(fontSize: _display.length > 12 ? 18 : 28, fontWeight: FontWeight.w900, color: kPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
      const SizedBox(height: 10),
      for (final row in [['C','±','%','÷'],['7','8','9','×'],['4','5','6','−'],['1','2','3','+'],[' ⌫','0','.','=']])
        Row(children: row.map((k) {
          if (k == '=') return _btn(k, bg: kGreen, fg: Colors.white);
          if (k == 'C') return _btn(k, bg: kRed, fg: Colors.white);
          if (k.contains('⌫')) return _btn('⌫', bg: kOrange.withOpacity(.8), fg: Colors.white);
          if (['+','−','×','÷'].contains(k)) return _btn(k, bg: kPrimary, fg: Colors.white);
          return _btn(k);
        }).toList()),
      const SizedBox(height: 8),
    ])),
    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
  );
}
