import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==================== SUPABASE INITIALIZATION ====================
  await Supabase.initialize(
    url: 'https://aswhtehpmmeetplnskmz.supabase.co',
    anonKey: 'sb_publishable_hP_Ad03CQHCSgpyaw1p4mw_GapuC8RJ',
  );
  // ============================================================

  // Inicializar servicios globales
  await NotificationService().init();

  runApp(const CunitechApp());
}

// Cliente global de Supabase
final supabase = Supabase.instance.client;

class CunitechApp extends StatefulWidget {
  const CunitechApp({super.key});

  @override
  State<CunitechApp> createState() => _CunitechAppState();
}

class _CunitechAppState extends State<CunitechApp> {
  final ThemeController _themeController = ThemeController();

  @override
  void initState() {
    super.initState();

    // ==================== AUTH STATE LISTENER ====================
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      print('🔐 Auth Event: $event'); // Para debugging

      if (!mounted) return;

      // Pequeño delay para que el estado se actualice
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;

        try {
          switch (event) {
            case AuthChangeEvent.tokenRefreshed:
              break;

            case AuthChangeEvent.signedOut:
              if (ModalRoute.of(context)?.settings.name != '/') {
                Navigator.of(context).pushReplacementNamed('/');
                print('✅ Navegando a login');
              }
              break;

            default:
              break;
          }
        } catch (e) {
          print('❌ Navigation error: $e');
        }
      });
    });
    // ============================================================
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, child) {
        return MaterialApp(
          title: 'CUNITECH',
          debugShowCheckedModeBanner: false,

          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeController.themeMode,

          initialRoute: '/',
          routes: {
            '/': (context) => const AuthScreen(),
            '/main': (context) => MainScreen(
                  themeController: _themeController,
                ),
          },

          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.noScaling,
              ),
              child: Container(
                color: AppTheme.lightTheme.scaffoldBackgroundColor,
                child: child!,
              ),
            );
          },
        );
      },
    );
  }
}