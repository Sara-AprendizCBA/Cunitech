import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

enum UserRole {
  admin,
  ayudante,
  veterinario,
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(text: "admin@cunitech.co");
  final _passwordController = TextEditingController(text: "123456");
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  UserRole selectedRole = UserRole.admin;
  String? _errorMessage;

  final SupabaseClient _supabase = Supabase.instance.client;

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
    final isWideScreen = MediaQuery.of(context).size.width > 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFFEFBF7),
      body: Row(
        children: [
          // ========== HERO IMAGE - LEFT SIDE ==========
          if (isWideScreen)
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/Conejos.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.3),
                      BlendMode.multiply,
                    ),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFD4A574).withValues(alpha: 0.2),
                        const Color(0xFF1E40AF).withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFD4A574).withValues(alpha: 0.2),
                          const Color(0xFF9E7C5E).withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo + Brand Name
                          _buildHeroLogo(),
                          const SizedBox(height: 64),
                          Text(
                            "Gestión Profesional\nde Criaderos",
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -1.2,
                              height: 1.2,
                              fontFamily: 'Merriweather',
                            ),
                          ).animate().fadeIn(duration: 600.ms),
                          const SizedBox(height: 32),
                          Text(
                            "Controla tu granja con precisión veterinaria, eficiencia operativa y tranquilidad profesional.",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.6,
                              fontWeight: FontWeight.w400,
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
            ),

          // ========== LOGIN CARD - RIGHT SIDE ==========
          Expanded(
            flex: isWideScreen ? 5 : 10,
            child: Container(
              color: const Color(0xFFFEFBF7),
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideScreen ? 56 : 32,
                    vertical: 40,
                  ),
                  child: SizedBox(
                    width: 480,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo Mobile
                        if (!isWideScreen) ...[
                          _buildMobileLogo(),
                          const SizedBox(height: 48),
                        ],

                        // Role Selector
                        _buildRoleSelector(),
                        const SizedBox(height: 48),

                        // Tab Buttons
                        _buildAuthTabs(),
                        const SizedBox(height: 48),

                        // Header Text
                        Text(
                          isLogin ? "Bienvenido de nuevo" : "Crear nueva cuenta",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF9E7C5E),
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
                            color: const Color(0xFF5A5A5A),
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 44),

                        // Error Message
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFDD5624),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (_errorMessage != null) const SizedBox(height: 24),

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
                                hint: "admin@cunitech.co",
                                icon: Icons.email_rounded,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 20),
                              _buildPasswordField(
                                controller: _passwordController,
                                label: "Contraseña",
                                obscure: _obscurePassword,
                                onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              if (!isLogin) ...[
                                const SizedBox(height: 20),
                                _buildPasswordField(
                                  controller: _confirmPasswordController,
                                  label: "Confirmar Contraseña",
                                  obscure: _obscureConfirmPassword,
                                  onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                              ],
                              const SizedBox(height: 44),
                              _buildAuthButton(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => setState(() => isLogin = !isLogin),
                          child: RichText(
                            text: TextSpan(
                              text: isLogin ? "¿No tienes cuenta? " : "¿Ya tienes cuenta? ",
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF5A5A5A),
                                fontWeight: FontWeight.w400,
                              ),
                              children: [
                                TextSpan(
                                  text: isLogin ? "Regístrate" : "Inicia sesión",
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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CUNITECH',
                  style: TextStyle(
                    fontSize: 28,
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem("142+", "Conejos"),
        _buildStatItem("98.4%", "Supervivencia"),
        _buildStatItem("31", "Partos/mes"),
      ],
    ).animate().fadeIn(duration: 1000.ms, delay: 200.ms);
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ========== ROLE SELECTOR ==========
  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "¿Cuál es tu rol?",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5A5A5A),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildRoleCard(
              UserRole.admin,
              "Administrador",
              Icons.shield_rounded,
              "Control\ntotal",
            ),
            const SizedBox(width: 12),
            _buildRoleCard(
              UserRole.veterinario,
              "Veterinario",
              Icons.local_hospital_rounded,
              "Salud",
            ),
            const SizedBox(width: 12),
            _buildRoleCard(
              UserRole.ayudante,
              "Ayudante",
              Icons.handshake_rounded,
              "Operaciones",
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard(UserRole role, String title, IconData icon, String subtitle) {
    final isSelected = selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF9E7C5E).withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF9E7C5E)
                  : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF9E7C5E).withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected
                    ? const Color(0xFF829A12)
                    : const Color(0xFFCBD5E1),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 12,
                  color: isSelected
                      ? const Color(0xFF9E7C5E)
                      : const Color(0xFF2C2C2C),
                ),
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: const Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== AUTH TABS ==========
  Widget _buildAuthTabs() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildTabButton("Iniciar Sesión", isLogin),
          _buildTabButton("Registrarse", !isLogin),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isLogin = !isLogin),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
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
                  ? const Color(0xFFe0e27c)
                  : const Color(0xFFCBD5E1),
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
              prefixIcon: Icon(icon, color: const Color(0xFFCBD5E1), size: 20),
              filled: true,
              fillColor: const Color(0xFFF5F3F0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFe0e27c),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              hintStyle: const TextStyle(
                color: Color(0xFFD1D5DB),
                fontSize: 14,
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1F2937),
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
              prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFFCBD5E1), size: 20),
              suffixIcon: GestureDetector(
                onTap: onToggle,
                child: Icon(
                  obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: const Color(0xFF9CA3AF),
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF5F3F0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFe0e27c),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              hintStyle: const TextStyle(
                color: Color(0xFFD1D5DB),
                fontSize: 14,
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  // ========== AUTH BUTTON ==========
  Widget _buildAuthButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _authenticate,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isLoading
                ? [
                    const Color(0xFF9E7C5E).withValues(alpha: 0.6),
                    const Color(0xFF1D7563).withValues(alpha: 0.6),
                  ]
                : [
                    const Color(0xFF9E7C5E),
                    const Color(0xFF9E7C5E),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9E7C5E).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
                  isLogin ? "INICIAR SESIÓN" : "CREAR CUENTA",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  // ========== HELPER: Convierte el enum de rol a String para Supabase ==========
  String _rolToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.veterinario:
        return 'veterinario';
      case UserRole.ayudante:
        return 'ayudante';
    }
  }

  // ==================== AUTENTICACIÓN CON SUPABASE (VIA EDGE FUNCTION) ====================
  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (!isLogin && _passwordController.text != _confirmPasswordController.text) {
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
          'rol': _rolToString(selectedRole),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cuenta creada correctamente. Inicia sesión."),
              backgroundColor: AppTheme.accent,
              duration: Duration(milliseconds: 1800),
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLogin ? "Bienvenido" : "Cuenta creada correctamente"),
            backgroundColor: AppTheme.accent,
            duration: const Duration(milliseconds: 1200),
          ),
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