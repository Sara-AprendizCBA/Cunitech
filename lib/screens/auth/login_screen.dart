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
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Row(
        children: [
          if (isWideScreen)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/Conejos.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.35),
                        AppTheme.accent.withOpacity(0.85),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(72),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/Logo 1.png',
                          height: 148,
                          fit: BoxFit.contain,
                        ).animate().fadeIn(duration: 900.ms).scale(
                              begin: const Offset(0.8, 0.8),
                              duration: 1000.ms,
                              curve: Curves.easeOutBack,
                            ),
                        const SizedBox(height: 48),
                        const Text(
                          "CUNITECH",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Gestión profesional de criaderos",
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white.withOpacity(0.95),
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                        ),
                        const SizedBox(height: 80),
                        _buildBrandStat("142", "Conejos registrados"),
                        const SizedBox(height: 36),
                        _buildBrandStat("98.4%", "Tasa de supervivencia"),
                        const SizedBox(height: 36),
                        _buildBrandStat("31", "Partos este mes"),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            flex: isWideScreen ? 5 : 10,
            child: Container(
              color: AppTheme.surfaceLight,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 40),
                  child: SizedBox(
                    width: 460,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isWideScreen)
                          Center(
                            child: Image.asset(
                              'assets/images/Logo 1.png',
                              height: 92,
                            ),
                          ),
                        const SizedBox(height: 40),
                        _buildRoleSelector(),
                        const SizedBox(height: 44),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.borderLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              _buildTabButton("Iniciar Sesión", isLogin),
                              _buildTabButton("Registrarse", !isLogin),
                            ],
                          ),
                        ),
                        const SizedBox(height: 52),
                        Text(
                          isLogin ? "Bienvenido de nuevo" : "Crear cuenta",
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.6,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isLogin
                              ? "Accede a tu sistema de gestión de conejos"
                              : "Registra tu granja y comienza a controlar todo",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 48),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (!isLogin)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: TextFormField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      labelText: "Nombre de la Granja",
                                      hintText: "Granja Los Conejos",
                                      prefixIcon: const Icon(Icons.business_rounded),
                                    ),
                                  ),
                                ),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: "Correo electrónico",
                                  hintText: "admin@cunitech.co",
                                  prefixIcon: const Icon(Icons.email_rounded),
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: "Contraseña",
                                  hintText: "••••••••",
                                  prefixIcon: const Icon(Icons.lock_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                              ),
                              if (!isLogin)
                                Padding(
                                  padding: const EdgeInsets.only(top: 24),
                                  child: TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    decoration: InputDecoration(
                                      labelText: "Confirmar Contraseña",
                                      hintText: "••••••••",
                                      prefixIcon: const Icon(Icons.lock_rounded),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 40),
                              SizedBox(
                                width: double.infinity,
                                height: 64,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _authenticate,
                                  style: ElevatedButton.styleFrom(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : Text(
                                          isLogin ? "INICIAR SESIÓN" : "CREAR CUENTA",
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                ),
                              ),
                            ],
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

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Selecciona tu rol",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildRoleCard(UserRole.admin, "Administrador", Icons.shield_rounded, "Control total"),
            const SizedBox(width: 12),
            _buildRoleCard(UserRole.veterinario, "Veterinario", Icons.medical_services_rounded, "Salud"),
            const SizedBox(width: 12),
            _buildRoleCard(UserRole.ayudante, "Ayudante", Icons.handshake_rounded, "Operaciones"),
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accent.withOpacity(0.1) : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.accent : AppTheme.borderLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: isSelected ? AppTheme.accent : AppTheme.textSecondary),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? AppTheme.accent : null,
                ),
              ),
              Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isLogin = !isLogin),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? AppTheme.surfaceLight : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandStat(String value, String label) {
    return Row(
      children: [
        Text(value, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(width: 16),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: Colors.white70))),
      ],
    );
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (isLogin) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) Navigator.pushReplacementNamed(context, '/main');
      } else {
        if (_passwordController.text != _confirmPasswordController.text) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Las contraseñas no coinciden")),
            );
          }
          return;
        }

        await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          data: {
            'name': _nameController.text.trim(),
            'role': selectedRole.name,
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registro exitoso. Revisa tu correo para confirmar."),
              backgroundColor: Colors.green,
            ),
          );
          setState(() => isLogin = true);
        }
      }
    } on AuthException catch (e) {
      String message = e.message;
      if (e.message.contains("Email not confirmed")) {
        message = "Por favor confirma tu correo electrónico";
      } else if (e.message.contains("Invalid login credentials")) {
        message = "Correo o contraseña incorrectos";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
