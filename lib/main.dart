import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/app_state.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  final apiService = APIService();
  await apiService.initialize();
  runApp(MyApp(apiService: apiService));
}

class MyApp extends StatelessWidget {
  final APIService apiService;
  const MyApp({Key? key, required this.apiService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<APIService>.value(value: apiService),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider(apiService)),
        ChangeNotifierProvider<AppState>(create: (_) => AppState(apiService)),
      ],
      child: Consumer<AppState>(
        builder: (ctx, appState, _) => MaterialApp(
          title: 'SuperMarché POS',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1b3a5c)),
            fontFamily: 'Roboto',
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1b3a5c), brightness: Brightness.dark),
          ),
          themeMode: appState.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
          routes: {
            '/splash': (_) => const SplashScreen(),
            '/login':  (_) => const LoginScreen(),
            '/home':   (_) => const HomeScreen(),
          },
        ),
      ),
    );
  }
}
