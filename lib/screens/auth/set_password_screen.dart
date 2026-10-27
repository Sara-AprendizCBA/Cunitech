// lib/screens/auth/set_password_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/widgets/app_loading.dart';
import '../../controllers/auth_controller.dart';

/// Estados posibles de la pantalla.
enum _Status { verifying, form, error }

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  _Status _status = _Status.verifying;
  String _errorMessage = '';
  String? _formError;
  bool _saving = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _verifyToken();
  }

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ==================== PARSEO DE PARÁMETROS ====================
  // La URL es http://host/#/set-password?token=XXX&type=invite (hash routing).
  // Con "#", el query queda dentro del fragment; por eso, además de
  // uri.queryParameters, parseamos el fragment.
  ({String? token, String type}) _parseParams() {
    final uri = Uri.base;
    final params = <String, String>{};
    params.addAll(uri.queryParameters);

    final fragment = uri.fragment;
    final qIndex = fragment.indexOf('?');
    if (qIndex != -1) {
      params.addAll(Uri.splitQueryString(fragment.substring(qIndex + 1)));
    }
    return (token: params['token'], type: params['type'] ?? 'invite');
  }

  // ==================== VERIFICACIÓN DEL TOKEN ====================
  Future<void> _verifyToken() async {
    final parsed = _parseParams();
    final token = parsed.token;

    if (token == null || token.isEmpty) {
      setState(() {
        _status = _Status.error;
        _errorMessage = 'No se encontró un token válido en el enlace.';
      });
      return;
    }

    try {
      await _supabase.auth.verifyOTP(
        tokenHash: token,
        type: parsed.type == 'recovery' ? OtpType.recovery : OtpType.invite,
      );
      if (!mounted) return;
      setState(() => _status = _Status.form);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = _Status.error;
        _errorMessage = 'Enlace inválido o expirado.';
      });
    }
  }

  // ==================== ACCIONES ====================
  void _goLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: _newController.text),
      );
      await Get.find<AuthController>().loadCurrentUser();
      if (!mounted) return;

      AppSnackbar.success(context, '¡Contraseña creada!');
      // Todos los roles entran a /main (qué ve cada uno lo decide MainScreen).
      Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
    } on AuthException catch (e) {
      debugPrint('Error actualizando contraseña: ${e.message}');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = _friendlyAuthError(e.message);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = 'No se pudo crear la contraseña. Intenta de nuevo.';
      });
    }
  }

  String _friendlyAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('weak') || lower.contains('at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (lower.contains('session') || lower.contains('expired')) {
      return 'Tu sesión expiró. Vuelve a iniciar sesión.';
    }
    return 'No se pudo crear la contraseña. Intenta de nuevo.';
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: _goLogin,
        ),
        title: const Text('CUNITECH'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _card(context, _buildContent(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_status) {
      case _Status.verifying:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppTheme.spacingXl),
          child: AppLoadingIndicator(label: 'Verificando enlace…'),
        );
      case _Status.error:
        return _errorView(context);
      case _Status.form:
        return _formView(context);
    }
  }

  // ==================== VISTA DE ERROR ====================
  Widget _errorView(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text('Enlace no válido', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goLogin,
              child: const Text('Ir al login'),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FORMULARIO ====================
  Widget _formView(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Crea tu contraseña',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Tu cuenta en CUNITECH está lista.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            _passwordField(
              controller: _newController,
              label: 'Nueva contraseña',
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _passwordField(
              controller: _confirmController,
              label: 'Confirmar contraseña',
              obscure: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (v) {
                if (v != _newController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            if (_formError != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      _formError!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Crear contraseña'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPERS UI ====================
  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      enabled: !_saving,
      validator: validator,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
