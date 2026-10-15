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
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Row(
        children: [
          // ========== HERO IMAGE - LEFT SIDE ==========
          if (!isMobile)
            Expanded(
              flex: isTablet ? 4 : 5,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/Conejos.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 32 : 64),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo + Brand Name
                        _buildHeroLogo(),
                        const SizedBox(height: 72),
                        Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: isTablet ? 32 : 48,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                            children: [
                              const TextSpan(text: 'Gestión Profesional\nde '),
                              TextSpan(
                                text: 'Criaderos',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 600.ms),
                        const SizedBox(height: 32),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Text(
                            'Controla tu granja con precisión veterinaria, '
                            'eficiencia operativa y tranquilidad profesional.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.75),
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ).animate().fadeIn(duration: 800.ms, delay: 100.ms),
                        const SizedBox(height: 80),
                        _buildHeroStats(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ========== LOGIN CARD - RIGHT SIDE ==========
          Expanded(
            flex: isMobile ? 10 : (isTablet ? 6 : 5),
            child: Container(
              color: AppTheme.bgLight,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : (isTablet ? 32 : 64),
                    vertical: isMobile ? 24 : 48,
                  ),
                  child: SizedBox(
                    width: 480,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo Mobile
                        if (isMobile) ...[
                          _buildMobileLogo(),
                          const SizedBox(height: 24),
                        ],

                        // Tab Buttons
                        _buildAuthTabs(context),
                        const SizedBox(height: 40),

                        // Header Text
                        Text(
                          isLogin
                              ? "Bienvenido de nuevo"
                              : "Crear nueva cuenta",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLogin
                              ? "Accede a tu sistema integral de gestión"
                              : "Registra tu granja y empieza ahora",
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Error Message
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F1),
                              border: Border.all(
                                color: const Color(0xFFF3B5B5),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFB54747),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFF9B3434),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_errorMessage != null) const SizedBox(height: 16),

                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (!isLogin) ...[
                                _buildTextField(
                                  controller: _nameController,
                                  label: "Nombre de la Granja",
                                  hint: "Granja Los Conejos",
                                  icon: Icons.business_rounded,
                                ),
                                const SizedBox(height: 20),
                              ],
                              _buildTextField(
                                controller: _emailController,
                                label: "Correo electrónico",
                                hint: "Correo electrónico",
                                icon: Icons.email_rounded,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 20),
                              _buildPasswordField(
                                controller: _passwordController,
                                label: "Contraseña",
                                obscure: _obscurePassword,
                                onToggle: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              if (!isLogin) ...[
                                const SizedBox(height: 20),
                                _buildPasswordField(
                                  controller: _confirmPasswordController,
                                  label: "Confirmar Contraseña",
                                  obscure: _obscureConfirmPassword,
                                  onToggle: () => setState(
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 28),
                              _buildAuthButton(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => setState(() => isLogin = !isLogin),
                          child: RichText(
                            text: TextSpan(
                              text: isLogin
                                  ? "¿No tienes cuenta? "
                                  : "¿Ya tienes cuenta? ",
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF5A5A5A),
                                fontWeight: FontWeight.w400,
                              ),
                              children: [
                                TextSpan(
                                  text: isLogin
                                      ? "Regístrate"
                                      : "Inicia sesión",
                                  style: TextStyle(
                                    color: const Color(0xFFe0e27c),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }

  // ========== HERO LOGO ==========
  Widget _buildHeroLogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CUNITECH',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Merriweather',
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Rabbit Farm Management',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }

  // ========== MOBILE LOGO ==========
  Widget _buildMobileLogo() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFe0e27c).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFe0e27c).withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.pets_rounded,
            color: Color(0xFFe0e27c),
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'CUNITECH',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFe0e27c),
            fontFamily: 'Merriweather',
            letterSpacing: 1,
          ),
        ),
      ],
    );
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabButton(context, "Iniciar Sesión", isLogin),
          _buildTabButton(context, "Registrarse", !isLogin),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, String text, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isLogin = !isLogin),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(
            vertical: context.isMobile ? 10 : (context.isTablet ? 12 : 14),
          ),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
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
              color: selected ? AppTheme.accent : AppTheme.textSecondary,
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
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
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(
                icon,
                color: AppTheme.accent.withValues(alpha: 0.8),
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E0DA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E0DA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.accent,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              hintStyle: const TextStyle(
                color: Color(0xFFD1D5DB),
                fontSize: 14,
              ),
            ),
            style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
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
            decoration: InputDecoration(
              hintText: "••••••••",
              prefixIcon: Icon(
                Icons.lock_rounded,
                color: AppTheme.accent.withValues(alpha: 0.8),
                size: 20,
              ),
              suffixIcon: GestureDetector(
                onTap: onToggle,
                child: Icon(
                  obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: const Color(0xFF9CA3AF),
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E0DA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E0DA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.accent,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              hintStyle: const TextStyle(
                color: Color(0xFFD1D5DB),
                fontSize: 14,
              ),
            ),
            style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
          ),
        ),
      ],
    );
  }

  // ========== AUTH BUTTON ==========
  Widget _buildAuthButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _authenticate,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 56)),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppTheme.accent.withValues(alpha: 0.6);
          }
          if (states.contains(WidgetState.pressed)) {
            return const Color(0xFF80634B);
          }
          return AppTheme.accent;
        }),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        elevation: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered) ? 6 : 0,
        ),
        shadowColor: WidgetStatePropertyAll(
          AppTheme.accent.withValues(alpha: 0.3),
        ),
        overlayColor: WidgetStatePropertyAll(
          Colors.white.withValues(alpha: 0.1),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
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
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
    );
  }

  // ==================== AUTENTICACIÓN CON SUPABASE (VIA EDGE FUNCTION) ====================
  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (!isLogin &&
        _passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Las contraseñas no coinciden";
        _isLoading = false;
      });
      return;
    }

    if (!isLogin && _nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "El nombre de la granja es requerido";
        _isLoading = false;
      });
      return;
    }

    try {
      if (isLogin) {
        // ---------- LOGIN VIA EDGE FUNCTION ----------
        final FunctionResponse response = await _supabase.functions.invoke(
          'login',
          body: {
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          },
        );

        if (response.status == 200) {
          final data = response.data;
          if (data is Map && data['session'] is Map) {
            final session = data['session'] as Map;
            final refreshToken = session['refresh_token'];
            if (refreshToken is String && refreshToken.isNotEmpty) {
              await _supabase.auth.setSession(refreshToken);
            }
          }
        } else {
          final errorMsg = response.data is Map
              ? (response.data['error'] ?? 'Credenciales inválidas').toString()
              : 'Error al iniciar sesión (${response.status})';
          throw Exception(errorMsg);
        }
      } else {
        // ---------- REGISTER ----------
        final response = await _supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final user = response.user;
        if (user == null) {
          throw Exception("No se pudo crear la cuenta");
        }

        // Insertamos los datos extra en la tabla usuario
        await _supabase.from('usuario').insert({
          'id_usuario': user.id,
          'nombre': _nameController.text.trim(),
        });

        // Supabase puede iniciar sesión automáticamente al registrarse.
        if (response.session != null) {
          await _supabase.auth.signOut();
        }

        if (mounted) {
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
        }
        return;
      }

      if (mounted) {
        AppSnackbar.success(
          context,
          isLogin ? 'Bienvenido' : 'Cuenta creada correctamente',
        );
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _errorMessage = msg;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
