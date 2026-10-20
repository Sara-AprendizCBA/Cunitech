// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/utils/app_snackbar.dart';
import '../core/utils/responsive.dart';
import '../controllers/auth_controller.dart';

import 'dashboard/dashboard_screen.dart';
import 'rabbits/rabbits_screen.dart';
import 'feeding/feeding_screen.dart';
import 'reproduction/reproduction_screen.dart';
import 'salud/salud_screen.dart';
import 'reports/reports_screen.dart';
import 'admin/user_management_screen.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _sidebarProfileKey = GlobalKey();
  final _drawerProfileKey = GlobalKey();
  final _mobileProfileKey = GlobalKey();

  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.home_outlined,
      'label': 'Inicio',
      'screen': const DashboardScreen(),
      'roles': const ['admin', 'veterinario', 'ayudante'],
    },
    {
      'icon': Icons.pets_outlined,
      'label': 'Conejos',
      'screen': const RabbitsScreen(),
      'roles': const ['admin', 'veterinario', 'ayudante'],
    },
    {
      'icon': Icons.restaurant_outlined,
      'label': 'Alimentación',
      'screen': const FeedingScreen(),
      'roles': const ['admin', 'veterinario', 'ayudante'],
    },
    {
      'icon': Icons.favorite_border,
      'label': 'Reproducción',
      'screen': const ReproductionScreen(),
      'roles': const ['admin', 'veterinario', 'ayudante'],
    },
    {
      'icon': Icons.health_and_safety_outlined,
      'label': 'Salud',
      'screen': const SaludScreen(),
      'roles': const ['admin', 'veterinario', 'ayudante'],
    },
    {
      'icon': Icons.analytics_outlined,
      'label': 'Reportes',
      'screen': const ReportsScreen(),
      'roles': const ['admin', 'veterinario'],
    },
    {
      'icon': Icons.people_alt_rounded,
      'label': 'Usuarios',
      'screen': const UserManagementScreen(),
      'roles': const ['admin'],
    },
  ];

  // ==================== HELPERS DE ROL ====================
  List<Map<String, dynamic>> _visibleItems(AuthController auth) {
    return _navItems.where((item) {
      final roles = item['roles'] as List<String>? ?? const [];
      return roles.contains(auth.currentRol.value);
    }).toList();
  }

  String _rolLabel(String rol) => switch (rol) {
        'admin' => 'Admin',
        'veterinario' => 'Veterinario',
        'ayudante' => 'Ayudante',
        _ => 'Usuario',
      };

  String _initials(String? nombre) {
    final n = (nombre ?? '').trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  // ==================== HELPERS DE TEMA ====================
  Color _surfaceColor(BuildContext context) =>
      Theme.of(context).cardTheme.color ??
      Theme.of(context).colorScheme.surface;

  Color _borderColor(BuildContext context) =>
      Theme.of(context).dividerTheme.color ??
      Theme.of(context).colorScheme.outline;

  Color? _secondaryTextColor(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.color ??
      Theme.of(context).textTheme.bodyMedium?.color;

  Color? _primaryTextColor(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge?.color ??
      Theme.of(context).textTheme.titleMedium?.color;

  // ==================== CERRAR SESIÓN ====================
  Future<void> _logout() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    try {
      await Supabase.instance.client.auth.signOut();
      // El listener en main.dart detectará signedOut y navegará al login.
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Error al cerrar sesión: $e');
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
  void _showProfileMenu(GlobalKey anchorKey) {
    final auth = Get.find<AuthController>();
    final nombre = auth.currentUser.value?['nombre'] as String? ?? 'Usuario';
    final rol = _rolLabel(auth.currentRol.value);
    final initials = _initials(nombre);

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;

    RelativeRect position = const RelativeRect.fromLTRB(200, 500, 50, 50);
    if (overlay != null && box != null) {
      final rect = Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      );
      position = RelativeRect.fromRect(rect, Offset.zero & overlay.size);
    }

    showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem<String>(
          enabled: false,
          child: ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
              child: Text(initials,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: Text(nombre),
            subtitle: Text(rol),
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
      if (!mounted) return;
      if (value == null) return;

      switch (value) {
        case 'profile':
          _goToProfile();
          break;
        case 'settings':
          _goToSettings();
          break;
        case 'password':
          AppSnackbar.info(context, "Función próximamente");
          break;
        case 'logout':
          _logout();
          break;
      }
      // showMenu ya cerró el menú: NO hacer Navigator.pop aquí.
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final theme = Theme.of(context);
    final isMobile = ResponsiveBuildContext(context).isMobile;
    final isTablet = ResponsiveBuildContext(context).isTablet;
    final isDesktop = ResponsiveBuildContext(context).isDesktop;

    return Obx(() {
      final items = _visibleItems(authController);

      if (items.isEmpty) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Center(
            child: authController.isLoading.value
                ? const CircularProgressIndicator()
                : const Text('No tienes acceso a ningún módulo'),
          ),
        );
      }

      final index = _currentIndex < items.length ? _currentIndex : 0;
      final nombre =
          authController.currentUser.value?['nombre'] as String? ?? 'Usuario';
      final rol = _rolLabel(authController.currentRol.value);
      final initials = _initials(nombre);

      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: (isMobile || isTablet)
            ? Drawer(
                child: _buildNavigationDrawer(
                    context, items, index, nombre, rol, initials),
              )
            : null,
        body: SafeArea(
          top: !isDesktop,
          bottom: false,
          child: !isDesktop
              ? Column(
                  children: [
                    _buildMobileTopBar(context,
                        isTablet: isTablet, items: items, currentIndex: index),
                    Expanded(child: items[index]['screen'] as Widget),
                  ],
                )
              : Row(
                  children: [
                    // Sidebar
                    Container(
                      width: 240,
                      decoration: BoxDecoration(
                        color: _surfaceColor(context),
                        border: Border(
                            right: BorderSide(
                                color: _borderColor(context), width: 1)),
                      ),
                      child: Column(
                        children: [
                          // Logo
                          Container(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                            decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: _borderColor(context), width: 1)),
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
                                  child: const Icon(Icons.pets,
                                      color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "CUNITECH",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: items.length,
                              itemBuilder: (context, i) {
                                final item = items[i];
                                final isSelected = index == i;

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusMd),
                                      onTap: () =>
                                          setState(() => _currentIndex = i),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                                  .withValues(alpha: 0.15)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                              AppTheme.radiusMd),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              item['icon'] as IconData,
                                              color: isSelected
                                                  ? AppTheme.accent
                                                  : _secondaryTextColor(context),
                                              size: 22,
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              item['label'] as String,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? AppTheme.accent
                                                    : _primaryTextColor(context),
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
                              border: Border(
                                  top: BorderSide(
                                      color: _borderColor(context), width: 1)),
                            ),
                            child: GestureDetector(
                              key: _sidebarProfileKey,
                              onTap: () => _showProfileMenu(_sidebarProfileKey),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor:
                                        AppTheme.accent.withValues(alpha: 0.1),
                                    child: Text(initials,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(nombre,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14)),
                                        Text(rol,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    _secondaryTextColor(context))),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_drop_down,
                                      color: _secondaryTextColor(context)),
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
                        color: theme.scaffoldBackgroundColor,
                        child: Column(
                          children: [
                            // Top Bar
                            Container(
                              height: 72,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              decoration: BoxDecoration(
                                color: _surfaceColor(context),
                                border: Border(
                                    bottom: BorderSide(
                                        color: _borderColor(context),
                                        width: 1)),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    items[index]['label'] as String,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                  const Spacer(),
                                  IconButton(
                                      icon: const Icon(
                                          Icons.notifications_outlined),
                                      onPressed: () {}),
                                  const SizedBox(width: 8),
                                  IconButton(
                                      icon: const Icon(Icons.search),
                                      onPressed: () {}),
                                ],
                              ),
                            ),

                            Expanded(child: items[index]['screen'] as Widget),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      );
    });
  }

  Widget _buildNavigationDrawer(
    BuildContext context,
    List<Map<String, dynamic>> items,
    int currentIndex,
    String nombre,
    String rol,
    String initials,
  ) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.adaptivePadding),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _borderColor(context)),
              ),
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
                  'CUNITECH',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final selected = i == currentIndex;
                return ListTile(
                  leading: Icon(
                    item['icon'] as IconData,
                    color:
                        selected ? AppTheme.accent : _secondaryTextColor(context),
                  ),
                  title: Text(item['label'] as String),
                  selected: selected,
                  selectedColor: AppTheme.accent,
                  selectedTileColor:
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                  onTap: () {
                    setState(() => _currentIndex = i);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: _borderColor(context))),
            ),
            child: ListTile(
              key: _drawerProfileKey,
              leading: CircleAvatar(
                backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                child: Text(
                  initials,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              title: Text(
                nombre,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(rol),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => _showProfileMenu(_drawerProfileKey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTopBar(
    BuildContext context, {
    required bool isTablet,
    required List<Map<String, dynamic>> items,
    required int currentIndex,
  }) {
    return Container(
      height: isTablet ? 72 : 64,
      padding: EdgeInsets.symmetric(horizontal: context.adaptivePaddingH),
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        border: Border(bottom: BorderSide(color: _borderColor(context))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Abrir navegación',
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Expanded(
            child: Text(
              items[currentIndex]['label'] as String,
              style: Theme.of(context).textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Notificaciones',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            key: _mobileProfileKey,
            tooltip: 'Perfil',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _showProfileMenu(_mobileProfileKey),
          ),
        ],
      ),
    );
  }
}
