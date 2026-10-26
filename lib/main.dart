import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'controllers/auth_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/set_password_screen.dart';
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

  // Controlador global de autenticación (rol del usuario actual)
  Get.put(AuthController(), permanent: true);

  // Inicializar servicios globales
  await NotificationService().init();

  runApp(const CunitechApp());
}

// Cliente global de Supabase
final supabase = Supabase.instance.client;
final navigatorKey = GlobalKey<NavigatorState>();

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

    // Controlador de tema accesible desde cualquier pantalla vía GetX
    if (!Get.isRegistered<ThemeController>()) {
      Get.put<ThemeController>(_themeController, permanent: true);
    }

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
              if (Get.currentRoute != '/') {
                navigatorKey.currentState?.pushReplacementNamed('/');
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
        return GetMaterialApp(
          title: 'CUNITECH',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          defaultTransition: Transition.rightToLeftWithFade,
          transitionDuration: const Duration(milliseconds: 250),

          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeController.themeMode,

          initialRoute: '/',
          routes: {
            '/': (context) => const AuthScreen(),
            '/set-password': (context) => const SetPasswordScreen(),
            '/main': (context) => MainScreen(
                  themeController: _themeController,
                ),
          },

          builder: (context, child) {
            AppTheme.sync(context);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.noScaling,
              ),
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: child!,
              ),
            );
          },
        );
      },
    );
  }
}