import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    try {
      final auth = context.read<AuthProvider>();
      await Future.wait([
        _waitInit(auth),
        Future.delayed(const Duration(milliseconds: 2500)),
      ]);
      if (!mounted) return;
      if (auth.isLoggedIn) {
        await context.read<AppState>().init();
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _waitInit(AuthProvider auth) async {
    if (auth.isInitialized) return;
    int attempts = 0;
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      return !auth.isInitialized && ++attempts < 160;
    });
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1b3a5c), Color(0xFF234d7a), Color(0xFF0f2338)])),
      child: SafeArea(child: Center(child: FadeTransition(opacity: _fade,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 120, height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.1), shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(.3), width: 2)),
            child: const Center(child: Text('🛒', style: TextStyle(fontSize: 52)))),
          const SizedBox(height: 40),
          const Text('SuperMarché POS',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Système de Caisse Professionnel',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(.7))),
          const SizedBox(height: 60),
          SizedBox(width: 48, height: 48,
            child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(.9)))),
        ])))),
    ));
}
