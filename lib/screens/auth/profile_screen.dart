// lib/screens/auth/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../controllers/auth_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthController _auth = Get.find<AuthController>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _originalName = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser.value;
    _originalName = user?['nombre'] as String? ?? '';
    _nameController.text = _originalName;
    _emailController.text = user?['email'] as String? ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ==================== HELPERS ====================

  String _rolLabel(String rol) => switch (rol) {
        'admin' => 'Administrador',
        'veterinario' => 'Veterinario',
        'ayudante' => 'Ayudante',
        _ => 'Usuario sin asignar',
      };

  String _initials(String? nombre) {
    final n = (nombre ?? '').trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  // ==================== ACCIONES ====================

  void _cancel() {
    FocusScope.of(context).unfocus();
    setState(() => _nameController.text = _originalName);
  }

  Future<void> _save() async {
    final nuevo = _nameController.text.trim();
    if (nuevo.isEmpty) {
      AppSnackbar.warning(context, 'El nombre no puede estar vacío');
      return;
    }

    final id = _auth.currentUser.value?['id_usuario'] as String?;
    if (id == null) {
      AppSnackbar.error(context, 'No se pudo identificar al usuario');
      return;
    }

    setState(() => _saving = true);
    try {
      await _supabase
          .from('usuario')
          .update({'nombre': nuevo}).eq('id_usuario', id);
      await _auth.loadCurrentUser();
      if (!mounted) return;

      final current = _auth.currentUser.value;
      if (current != null) {
        _auth.currentUser.value = {...current, 'nombre': nuevo};
      }
      _originalName = nuevo;
      _nameController.text = nuevo;

      setState(() => _saving = false);
      AppSnackbar.success(context, 'Perfil actualizado');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.error(context, 'No se pudo actualizar el perfil');
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Mi Perfil'),
      ),
      body: Obx(() {
        final user = _auth.currentUser.value;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final nombre = user['nombre'] as String? ?? 'Usuario';
        final rol = _rolLabel(_auth.currentRol.value);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppTheme.spacingLg),
                  _header(context, nombre, rol),
                  const SizedBox(height: AppTheme.spacingLg),
                  _sectionTitle(context, 'Información'),
                  _formCard(context),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buttons(context),
                  const SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ==================== SECCIONES ====================

  Widget _header(BuildContext context, String nombre, String rol) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppTheme.accent,
          child: Text(
            _initials(nombre),
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          nombre,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(rol, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _formCard(BuildContext context) {
    final theme = Theme.of(context);
    return _card(
      context,
      Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel(context, 'Nombre Completo'),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _nameController,
              enabled: !_saving,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_saving) _save();
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'Tu nombre completo',
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _fieldLabel(context, 'Correo Electrónico'),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _emailController,
              readOnly: true,
              style: theme.textTheme.bodyMedium,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined),
                helperText: 'El correo no se puede modificar',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buttons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : _cancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accent,
              side: const BorderSide(color: AppTheme.accent),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Guardar Cambios'),
          ),
        ),
      ],
    );
  }

  // ==================== HELPERS UI ====================

  Widget _sectionTitle(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingXs,
        0,
        AppTheme.spacingXs,
        AppTheme.spacingSm,
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String text) {
    return Text(text, style: Theme.of(context).textTheme.titleSmall);
  }

  Widget _card(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.16),
      surfaceTintColor: Colors.transparent,
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
