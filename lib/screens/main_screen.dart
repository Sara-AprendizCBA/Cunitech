// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';

import 'dashboard/dashboard_screen.dart';
import 'rabbits/rabbits_screen.dart';
import 'feeding/feeding_screen.dart';
import 'reproduction/reproduction_screen.dart';
import 'reports/reports_screen.dart';
import 'auth/profile_screen.dart';
import 'auth/settings_screen.dart';

class MainScreen extends StatefulWidget {
  final ThemeController themeController;
  const MainScreen({super.key, required this.themeController});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const RabbitsScreen(),
    const FeedingScreen(),
    const ReproductionScreen(),
    const ReportsScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_outlined, 'label': 'Inicio'},
    {'icon': Icons.pets_outlined, 'label': 'Conejos'},
    {'icon': Icons.restaurant_outlined, 'label': 'Alimentación'},
    {'icon': Icons.favorite_border, 'label': 'Reproducción'},
    {'icon': Icons.analytics_outlined, 'label': 'Reportes'},
  ];

  // ==================== CERRAR SESIÓN ====================
  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sesión cerrada correctamente"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Ir a Perfil
  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  // Ir a Configuración
  void _goToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  // ==================== MENÚ DESPLEGABLE DE PERFIL ====================
  void _showProfileMenu() {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(200, 500, 50, 50),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          child: ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
              child: const Text("AC", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: const Text("Admin"),
            subtitle: const Text("Administrador"),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'profile',
          child: const ListTile(
            leading: Icon(Icons.person_outline),
            title: Text("Ver Perfil"),
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: const ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text("Configuración"),
          ),
        ),
        PopupMenuItem<String>(
          value: 'password',
          child: const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text("Cambiar Contraseña"),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: const ListTile(
            leading: Icon(Icons.logout_rounded, color: Colors.red),
            title: Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'profile':
            _goToProfile();
            break;
          case 'settings':
            _goToSettings();
            break;
          case 'password':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Función próximamente")),
            );
            break;
          case 'logout':
            _logout();
            break;
        }
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              border: Border(right: BorderSide(color: AppTheme.borderLight, width: 1)),
            ),
            child: Column(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.borderLight, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.pets, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "CUNITECH",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Menú de navegación
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _navItems.length,
                    itemBuilder: (context, index) {
                      final item = _navItems[index];
                      final isSelected = _currentIndex == index;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            onTap: () => setState(() => _currentIndex = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.accentLight : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item['icon'] as IconData,
                                    color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    item['label'] as String,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ==================== USER SECTION ====================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: AppTheme.borderLight, width: 1)),
                  ),
                  child: GestureDetector(
                    onTap: _showProfileMenu,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                          child: const Text("AC", style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Admin", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text("Administrador", style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: Container(
              color: AppTheme.bgLight,
              child: Column(
                children: [
                  // Top Bar
                  Container(
                    height: 72,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      border: Border(bottom: BorderSide(color: AppTheme.borderLight, width: 1)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _navItems[_currentIndex]['label'] as String,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
                        const SizedBox(width: 8),
                        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                      ],
                    ),
                  ),

                  Expanded(child: _screens[_currentIndex]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
