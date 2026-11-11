import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/responsive.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const bool _registroPublicoHabilitado = false;
  bool isLogin = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(text: '');
  final _passwordController = TextEditingController(text: '');
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _errorMessage;
  static final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  int _totalConejos = 0;
  double _tasaSupervivencia = 0;
  int _partosMes = 0;
  bool _statsLoaded = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _cargarStats();
  }

  Future<void> _cargarStats() async {
    try {
      final stats = await _supabase.rpc('get_public_stats');

      if (mounted) {
        setState(() {
          _totalConejos = (stats['total_conejo'] as num?)?.toInt() ?? 0;
          _partosMes = (stats['total_partos_mes'] as num?)?.toInt() ?? 0;
          _tasaSupervivencia =
              (stats['tasa_supervivencia'] as num?)?.toDouble() ?? 0;
          _statsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error cargando stats: $e');
      if (mounted) setState(() => _statsLoaded = true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          if (isDesktop) {
            return Row(
              children: [
                Expanded(child: _buildHero(isDesktop: true)),
                Expanded(
                  child: _buildFormPanel(context, compact: false),
                ),
              ],
            );
          }

          return Column(
            children: [
              SizedBox(
                height: constraints.maxHeight * 0.30,
                child: _buildHero(isDesktop: false),
              ),
              Expanded(
                child: _buildFormPanel(context, compact: true),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHero({required bool isDesktop}) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/Conejos.jpg', fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.45, 1],
              colors: isDesktop
                  ? const [
                      Color(0x0F1A1510),
                      Color(0x401A1510),
                      Color(0x991A1510),
                    ]
                  : const [
                      Color(0x1A1A1510),
                      Color(0x591A1510),
                      Color(0xB31A1510),
                    ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: isDesktop
                  ? const [0, 0.45, 0.82]
                  : const [0, 0.45, 0.78],
              colors: isDesktop
                  ? const [
                      Color(0x661A1510),
                      Color(0x261A1510),
                      Colors.transparent,
                    ]
                  : const [
                      Color(0x8C1A1510),
                      Color(0x401A1510),
                      Colors.transparent,
                    ],
            ),
          ),
        ),
        Positioned(
          top: -70,
          right: -50,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentLight.withValues(alpha: 0.10),
            ),
          ),
        ),
        if (isDesktop)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const [0.72, 1],
                colors: [
                  Colors.transparent,
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 56 : 20),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 520 : 320,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroLogo(compact: !isDesktop),
                    SizedBox(height: isDesktop ? 52 : 18),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: isDesktop ? 46 : 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.08,
                          letterSpacing: -0.8,
                          shadows: const [
                            Shadow(
                              color: Color(0xCC000000),
                              blurRadius: 20,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        children: const [
                          TextSpan(text: 'GESTIÓN PROFESIONAL\nDE '),
                          TextSpan(
                            text: 'CRIADEROS',
                            style: TextStyle(color: AppTheme.accentLight),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 700.ms)
                        .scale(
                          begin: const Offset(0.98, 0.98),
                          end: const Offset(1, 1),
                        ),
                    if (isDesktop) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Controla tu granja con precisión veterinaria, '
                        'eficiencia operativa y tranquilidad profesional.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.6,
                          shadows: const [
                            Shadow(
                              color: Color(0x99000000),
                              blurRadius: 10,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 900.ms, delay: 120.ms),
                      const SizedBox(height: 56),
                      _buildHeroStats(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormPanel(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final horizontalPadding = compact ? 20.0 : 56.0;
    final verticalPadding = compact ? 28.0 : 48.0;

    final errorBackground = isDark
        ? AppTheme.dangerDark.withValues(alpha: 0.18)
        : const Color(0xFFFFF1F1);
    final errorBorder = isDark
        ? AppTheme.dangerDark
        : const Color(0xFFF3B5B5);
    final errorIcon = isDark
        ? const Color(0xFFFCA5A5)
        : const Color(0xFFB54747);
    final errorText = isDark
        ? const Color(0xFFFECACA)
        : const Color(0xFF9B3434);

    final formContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 14,
              color: AppTheme.accent,
            ),
            SizedBox(width: 6),
            Text(
              'ACCESO SEGURO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.4,
                color: AppTheme.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          isLogin ? 'Bienvenido de nuevo' : 'Crear nueva cuenta',
          style: TextStyle(
            fontSize: compact ? 30 : 32,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            letterSpacing: -1.0,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isLogin
              ? 'Ingresa tus credenciales para continuar.'
              : 'Registra tu granja y empieza ahora.',
          style: TextStyle(
            fontSize: 15,
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        if (_registroPublicoHabilitado) ...[
          _buildAuthTabs(context),
          const SizedBox(height: 24),
        ],
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: errorBackground,
              border: Border.all(color: errorBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: errorIcon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: errorText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              if (!isLogin) ...[
                _buildTextField(
                  controller: _nameController,
                  compact: compact,
                  label: "Nombre de la Granja",
                  hint: "Granja Los Conejos",
                  icon: Icons.business_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el nombre de la granja';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],
              _buildTextField(
                controller: _emailController,
                compact: compact,
                label: "Correo electrónico",
                hint: "Correo electrónico",
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) {
                    return 'Ingresa tu correo electrónico';
                  }
                  if (!_emailRe.hasMatch(email)) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _passwordController,
                compact: compact,
                label: "Contraseña",
                obscure: _obscurePassword,
                onToggle: () => setState(
                  () => _obscurePassword = !_obscurePassword,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              if (!isLogin) ...[
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  compact: compact,
                  label: "Confirmar Contraseña",
                  obscure: _obscureConfirmPassword,
                  onToggle: () => setState(
                    () => _obscureConfirmPassword =
                        !_obscureConfirmPassword,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 28),
              _buildAuthButton(),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildContactFooter(context),
      ],
    );

    final animatedForm = formContent
        .animate()
        .fadeIn(duration: 700.ms)
        .scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1, 1),
          curve: Curves.easeOutCubic,
        );

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: compact ? null : theme.scaffoldBackgroundColor,
        gradient: compact
            ? RadialGradient(
                center: const Alignment(1.1, -1.1),
                radius: 1.6,
                colors: [
                  AppTheme.accent.withValues(alpha: isDark ? 0.16 : 0.10),
                  theme.scaffoldBackgroundColor,
                ],
              )
            : null,
        borderRadius: compact
            ? const BorderRadius.vertical(top: Radius.circular(28))
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minHeight = constraints.maxHeight - verticalPadding * 2;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minHeight < 0 ? 0 : minHeight,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: compact ? 430 : 480,
                  ),
                  child: animatedForm,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactFooter(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '¿No tienes cuenta?',
          style: TextStyle(
            fontSize: 13.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () => AppSnackbar.info(
            context,
            'Solicita acceso al administrador de tu criadero.',
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.accent,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Contacta al administrador',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  // ========== HERO LOGO ==========
  Widget _buildHeroLogo({bool compact = false}) {
    final iconBox = Container(
      width: compact ? 48 : 64,
      height: compact ? 48 : 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.24),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.pets_rounded,
        color: AppTheme.accentLight,
        size: compact ? 28 : 38,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1.04, 1.04),
          duration: 2800.ms,
          curve: Curves.easeInOut,
        );

    return Row(
      children: [
        iconBox,
        SizedBox(width: compact ? 12 : 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CUNITECH',
              style: TextStyle(
                fontSize: compact ? 19 : 23,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Merriweather',
                letterSpacing: 1.4,
              ),
            ),
            Text(
              compact ? 'Cunicultura inteligente' : 'Rabbit Farm Management',
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                color: Colors.white.withValues(alpha: 0.78),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }

  // ========== HERO STATS ==========
  Widget _buildHeroStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            _statsLoaded ? '$_totalConejos' : '—',
            'Conejos',
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: Colors.white.withValues(alpha: 0.15),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildStatItem(
            _statsLoaded ? '${_tasaSupervivencia.toStringAsFixed(1)}%' : '—',
            'Supervivencia',
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: Colors.white.withValues(alpha: 0.15),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildStatItem(
            _statsLoaded ? '$_partosMes' : '—',
            'Partos/mes',
          ),
        ),
      ],
    ).animate().fadeIn(duration: 1000.ms, delay: 200.ms);
  }

  Widget _buildStatItem(String value, String label) {
    return AnimatedOpacity(
      opacity: _statsLoaded ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ========== AUTH TABS ==========
  Widget _buildAuthTabs(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (_registroPublicoHabilitado) ...[
            _buildTabButton(
              context,
              "Iniciar Sesión",
              isLogin,
              onTap: () => setState(() => isLogin = true),
            ),
            _buildTabButton(
              context,
              "Registrarse",
              !isLogin,
              onTap: () => setState(() => isLogin = false),
            ),
          ] else
            _buildTabButton(context, "Iniciar Sesión", true),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context,
    String text,
    bool selected, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(
            vertical: context.isMobile ? 10 : (context.isTablet ? 12 : 14),
          ),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected
                  ? AppTheme.accent
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  // ========== CUSTOM TEXT FIELD ==========
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool compact,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            cursorColor: AppTheme.accent,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(
                icon,
                color: AppTheme.accent.withValues(alpha: 0.85),
                size: 20,
              ),
              filled: true,
              fillColor: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.74),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.45),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.45),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.accent,
                  width: 1.6,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: compact ? 18 : 20,
              ),
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.65,
                ),
                fontSize: 14,
              ),
            ),
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  // ========== PASSWORD FIELD ==========
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required bool compact,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            validator: validator,
            cursorColor: AppTheme.accent,
            decoration: InputDecoration(
              hintText: "••••••••",
              prefixIcon: Icon(
                Icons.lock_rounded,
                color: AppTheme.accent.withValues(alpha: 0.85),
                size: 20,
              ),
              suffixIcon: IconButton(
                onPressed: onToggle,
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.74),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.45),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.45),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.accent,
                  width: 1.6,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: compact ? 18 : 20,
              ),
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.65,
                ),
                fontSize: 14,
              ),
            ),
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  // ========== AUTH BUTTON ==========
  Widget _buildAuthButton() {
    final enabled = !_isLoading;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      height: 54,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: enabled
              ? const [
                  AppTheme.accentLight,
                  AppTheme.accent,
                  Color(0xFF6B4E36),
                ]
              : [
                  AppTheme.accent.withValues(alpha: 0.5),
                  AppTheme.accent.withValues(alpha: 0.4),
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.32),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? _authenticate : null,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    isLogin ? 'INICIAR SESIÓN' : 'CREAR CUENTA',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ==================== AUTENTICACIÓN CON SUPABASE (VIA EDGE FUNCTION) ====================
  Future<void> _authenticate() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (isLogin) {
        final response = await _supabase.functions.invoke(
          'login',
          body: {
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          },
        );

        final data = response.data;
        if (data is! Map || data['session'] is! Map) {
          _setError('No se pudo iniciar sesión. Intenta de nuevo.');
          return;
        }

        final session = data['session'] as Map;
        final refreshToken = session['refresh_token'];
        if (refreshToken is! String || refreshToken.isEmpty) {
          _setError('No se pudo iniciar sesión. Intenta de nuevo.');
          return;
        }

        await _supabase.auth.setSession(refreshToken);
      } else {
        final response = await _supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final user = response.user;
        if (user == null) {
          _setError('No se pudo crear la cuenta. Intenta de nuevo.');
          return;
        }

        await _supabase.from('usuario').insert({
          'id_usuario': user.id,
          'nombre': _nameController.text.trim(),
        });

        if (response.session != null) {
          await _supabase.auth.signOut();
        }

        if (!mounted) return;
        setState(() {
          isLogin = true;
          _nameController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
        AppSnackbar.success(
          context,
          'Cuenta creada correctamente. Inicia sesión.',
        );
        return;
      }

      if (!mounted) return;
      AppSnackbar.success(context, 'Bienvenido');
      Navigator.of(context).pushReplacementNamed('/main');
    } on FunctionException catch (e) {
      _setError(_friendlyFunctionError(e));
    } on AuthException catch (e) {
      _setError(_friendlyAuthError(e));
    } on PostgrestException catch (e) {
      debugPrint('Error guardando usuario: $e');
      _setError('No se pudo completar el registro. Intenta de nuevo.');
    } catch (e) {
      debugPrint('Error de autenticación: $e');
      _setError('No se pudo conectar. Revisa tu conexión e intenta de nuevo.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
  }

  String _friendlyFunctionError(FunctionException e) {
    final details = e.details;
    if (details is Map && details['error'] is String) {
      final message = (details['error'] as String).trim();
      if (message.isNotEmpty) return message;
    }
    if (details is String && details.trim().isNotEmpty) {
      return details.trim();
    }
    return switch (e.status) {
      400 => 'Revisa los datos ingresados.',
      401 => 'Correo o contraseña incorrectos.',
      403 => 'No tienes permisos para iniciar sesión.',
      429 => 'Demasiados intentos. Espera un momento.',
      >= 500 => 'Error del servidor. Intenta de nuevo.',
      _ => 'No se pudo iniciar sesión. Intenta de nuevo.',
    };
  }

  String _friendlyAuthError(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (message.contains('email not confirmed')) {
      return 'Confirma tu correo antes de iniciar sesión.';
    }
    if (message.contains('user already registered') ||
        message.contains('already been registered')) {
      return 'Este correo ya está registrado.';
    }
    if (message.contains('password should be at least') ||
        message.contains('password is too short')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (message.contains('rate limit') ||
        message.contains('too many') ||
        message.contains('security purposes')) {
      return 'Demasiados intentos. Espera un momento.';
    }
    if (message.contains('invalid refresh token')) {
      return 'La sesión expiró. Inicia sesión de nuevo.';
    }
    if (message.contains('invalid email')) {
      return 'Ingresa un correo electrónico válido.';
    }
    debugPrint('Error de autenticación: ${e.message}');
    return 'No se pudo completar la operación. Intenta de nuevo.';
  }
}
