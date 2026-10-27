// lib/screens/main_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/utils/app_snackbar.dart';
import '../core/utils/responsive.dart';
import '../core/widgets/app_loading.dart';
import '../controllers/auth_controller.dart';
import '../models/insight_recomendacion.dart';
import '../services/insight_service.dart';

import 'dashboard/dashboard_screen.dart';
import 'rabbits/rabbits_screen.dart';
import 'feeding/feeding_screen.dart';
import 'reproduction/reproduction_screen.dart';
import 'salud/salud_screen.dart';
import 'reports/reports_screen.dart';
import 'admin/user_management_screen.dart';
import 'auth/profile_screen.dart';
import 'auth/settings_screen.dart';
import 'notifications/notifications_screen.dart';

class MainScreen extends StatefulWidget {
  final ThemeController themeController;
  const MainScreen({super.key, required this.themeController});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _sidebarProfileKey = GlobalKey();
  final _drawerProfileKey = GlobalKey();
  final _mobileProfileKey = GlobalKey();
  final AuthController authController = Get.find<AuthController>();
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.home_outlined,
      'label': 'Inicio',
      'screen': const DashboardScreen(),
      'roles': const ['admin', 'veterinario', 'ayudante', 'usuario'],
    },
    {
      'icon': Icons.pets_outlined,
      'label': 'Conejos',
      'screen': const RabbitsScreen(),
      'roles': const ['admin', 'veterinario', 'ayudante', 'usuario'],
    },
    {
      'icon': Icons.restaurant_outlined,
      'label': 'Alimentación',
      'screen': const FeedingScreen(),
      'roles': const ['admin', 'veterinario', 'ayudante', 'usuario'],
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
      'roles': const ['admin', 'veterinario', 'ayudante', 'usuario'],
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
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Error al cerrar sesión: $e');
      }
      return;
    }

    await Get.deleteAll();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  // Ir a Notificaciones
  void _goToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
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
            leading: Icon(Icons.logout_rounded, color: AppTheme.danger),
            title: Text(
              "Cerrar Sesión",
              style: TextStyle(color: AppTheme.danger),
            ),
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

  Widget _buildInsightOrb(BuildContext context, {double size = 40}) {
    return Tooltip(
      message: 'CUNITECH Insight',
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.accent, Color(0xFF6B5339)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.45),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _showHolographicPanel(context),
              child: Icon(
                Icons.auto_awesome,
                color: const Color(0xFFFDF6EC),
                size: size * 0.47,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHolographicPanel(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CUNITECH Insight',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, _, __) {
        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 560,
                  maxHeight: MediaQuery.of(dialogContext).size.height - 40,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(
                            color: AppTheme.accentLight.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  color: AppTheme.accentLight,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'CUNITECH Insight',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Cerrar',
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: AppTheme.accentLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Flexible(
                              child: SingleChildScrollView(
                                child: FutureBuilder<InsightPanel>(
                                  future:
                                      InsightService().obtenerRecomendaciones(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: AppTheme.accentLight,
                                        ),
                                      );
                                    }
                                    if (snapshot.hasError ||
                                        !snapshot.hasData ||
                                        snapshot.data!.recomendaciones.isEmpty) {
                                      return const Text(
                                        'No hay recomendaciones disponibles.',
                                        style: TextStyle(color: Colors.white70),
                                      );
                                    }
                                    final panel = snapshot.data!;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (panel.diagnosticoGeneral.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: Text(
                                              panel.diagnosticoGeneral,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ...panel.recomendaciones.map(
                                          (r) => _buildInsightCard(r),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInsightCard(InsightRecomendacion r) {
    final prioridad = r.prioridad.toLowerCase();
    final color = prioridad == 'alta'
        ? Colors.redAccent
        : prioridad == 'media'
            ? Colors.orangeAccent
            : Colors.greenAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  r.prioridad.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            r.detalle,
            style: const TextStyle(color: Colors.white70),
          ),
          if (r.impacto.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              r.impacto,
              style: TextStyle(
                color: color,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimatedScreen(
    BuildContext context,
    List<Map<String, dynamic>> items,
    int index,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.02, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(index),
        child: items[index]['screen'] as Widget,
      ),
    );
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
                ? const AppLoadingIndicator()
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              !isDesktop
                  ? Column(
                      children: [
                        _buildMobileTopBar(
                          context,
                          isTablet: isTablet,
                          items: items,
                          currentIndex: index,
                        ),
                        Expanded(
                          child: _buildAnimatedScreen(context, items, index),
                        ),
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
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        curve: Curves.easeOutCubic,
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
                                    tooltip: 'Notificaciones',
                                    icon: const Icon(
                                      Icons.notifications_outlined,
                                    ),
                                    onPressed: _goToNotifications,
                                  ),
                                ],
                              ),
                            ),

                    Expanded(
                      child: _buildAnimatedScreen(context, items, index),
                    ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              if (authController.isAdmin || authController.isVeterinario)
                Positioned(
                  right: 20,
                  bottom: 80,
                  child: _buildInsightOrb(context, size: 56),
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
            onPressed: _goToNotifications,
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
