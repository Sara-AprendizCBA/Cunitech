import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/app_snackbar.dart';

/// Preferencias locales persistentes de la aplicación.
///
/// Los valores se guardan en `SharedPreferences` (persistencia local, no en
/// Supabase) y se exponen mediante getters estáticos para poder consultarlos
/// desde cualquier parte de la app sin instanciar nada.
class AppPreferences {
  AppPreferences._();

  static const String _kNotifEnabled = 'settings.notif.enabled';
  static const String _kNotifPartos = 'settings.notif.partos';
  static const String _kNotifVacunas = 'settings.notif.vacunas';

  static bool _notifEnabled = true;
  static bool _notifPartos = true;
  static bool _notifVacunas = true;

  static bool get notifEnabled => _notifEnabled;
  static bool get notifPartos => _notifPartos;
  static bool get notifVacunas => _notifVacunas;

  /// Carga las preferencias desde disco hacia la memoria.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _notifEnabled = prefs.getBool(_kNotifEnabled) ?? true;
    _notifPartos = prefs.getBool(_kNotifPartos) ?? true;
    _notifVacunas = prefs.getBool(_kNotifVacunas) ?? true;
  }

  static Future<void> setNotifEnabled(bool value) async {
    _notifEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifEnabled, value);
  }

  static Future<void> setNotifPartos(bool value) async {
    _notifPartos = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifPartos, value);
  }

  static Future<void> setNotifVacunas(bool value) async {
    _notifVacunas = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifVacunas, value);
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final ThemeController _theme = Get.find<ThemeController>();

  bool _notifEnabled = AppPreferences.notifEnabled;
  bool _notifPartos = AppPreferences.notifPartos;
  bool _notifVacunas = AppPreferences.notifVacunas;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await AppPreferences.load();
    if (!mounted) return;
    setState(() {
      _notifEnabled = AppPreferences.notifEnabled;
      _notifPartos = AppPreferences.notifPartos;
      _notifVacunas = AppPreferences.notifVacunas;
    });
  }

  // ==================== ACCIONES ====================

  Future<void> _openChangePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ChangePasswordDialog(supabase: _supabase),
    );
    if (!mounted) return;
    if (changed == true) {
      AppSnackbar.success(context, 'Contraseña actualizada correctamente');
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Configuración'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
                _sectionTitle(context, 'Apariencia'),
                _appearanceCard(context),
                _sectionTitle(context, 'Notificaciones'),
                _notificationsCard(context),
                _sectionTitle(context, 'Seguridad'),
                _securityCard(context),
                _sectionTitle(context, 'Región'),
                _languageCard(context),
                _footer(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== SECCIONES ====================

  Widget _appearanceCard(BuildContext context) {
    return _card(context, [
      AnimatedBuilder(
        animation: _theme,
        builder: (context, _) => _switchTile(
          context,
          icon: _theme.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          title: 'Tema oscuro',
          subtitle: _theme.isDarkMode ? 'Activado' : 'Desactivado',
          value: _theme.isDarkMode,
          onChanged: (value) =>
              _theme.setTheme(value ? ThemeMode.dark : ThemeMode.light),
        ),
      ),
    ]);
  }

  Widget _notificationsCard(BuildContext context) {
    return _card(context, [
      _switchTile(
        context,
        icon: Icons.notifications_outlined,
        title: 'Notificaciones',
        subtitle: 'Recordatorios de la aplicación',
        value: _notifEnabled,
        onChanged: (value) {
          setState(() => _notifEnabled = value);
          AppPreferences.setNotifEnabled(value);
        },
      ),
      _switchTile(
        context,
        icon: Icons.child_care_outlined,
        title: 'Partos',
        subtitle: 'Avisos de partos próximos',
        value: _notifPartos,
        onChanged: (value) {
          setState(() => _notifPartos = value);
          AppPreferences.setNotifPartos(value);
        },
      ),
      _switchTile(
        context,
        icon: Icons.vaccines_outlined,
        title: 'Vacunas',
        subtitle: 'Avisos de vacunación',
        value: _notifVacunas,
        onChanged: (value) {
          setState(() => _notifVacunas = value);
          AppPreferences.setNotifVacunas(value);
        },
      ),
    ]);
  }

  Widget _securityCard(BuildContext context) {
    return _card(context, [
      _clickableTile(
        context,
        icon: Icons.lock_outlined,
        title: 'Cambiar contraseña',
        subtitle: 'Actualiza tu contraseña de acceso',
        onTap: _openChangePassword,
      ),
    ]);
  }

  Widget _languageCard(BuildContext context) {
    final theme = Theme.of(context);
    return _card(context, [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _leadingIcon(context, Icons.language_outlined),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Idioma', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text('Español (Colombia)', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _leadingIcon(
              context,
              Icons.translate_rounded,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inglés',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: theme.textTheme.bodySmall?.color),
                  ),
                  const SizedBox(height: 2),
                  Text('Próximamente', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            _comingSoonChip(context),
          ],
        ),
      ),
    ]);
  }

  Widget _footer(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: AppTheme.spacingXl,
        bottom: AppTheme.spacingLg,
      ),
      child: Column(
        children: [
          Icon(Icons.eco_rounded, size: 22, color: theme.colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            'CUNITECH v1.0.0',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.textTheme.bodySmall?.color),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  Widget _sectionTitle(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingXs,
        AppTheme.spacingLg,
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

  Widget _card(BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outline;
    final dividerColor = theme.dividerTheme.color ?? borderColor;

    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        items.add(Divider(height: 1, thickness: 1, color: dividerColor));
      }
      items.add(children[i]);
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: items),
    );
  }

  Widget _leadingIcon(BuildContext context, IconData icon, {Color? color}) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: c),
    );
  }

  Widget _switchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _leadingIcon(context, icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _clickableTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _leadingIcon(context, icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _comingSoonChip(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Próximamente',
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.textTheme.bodySmall?.color),
      ),
    );
  }
}

/// Diálogo modal para cambiar la contraseña del usuario autenticado.
///
/// Valida la contraseña actual mediante `signInWithPassword` y aplica el
/// cambio con `updateUser`. Devuelve `true` en `Navigator.pop` si tuvo éxito.
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.supabase});

  final SupabaseClient supabase;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentController.text;
    final next = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Completa todos los campos');
      return;
    }
    if (next.length < 6) {
      setState(() => _error = 'La nueva contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (next != confirm) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }
    if (next == current) {
      setState(() => _error = 'La nueva contraseña debe ser diferente a la actual');
      return;
    }

    final email = widget.supabase.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      setState(() => _error = 'No se pudo obtener el correo del usuario');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.supabase.auth.signInWithPassword(
        email: email,
        password: current,
      );
      await widget.supabase.auth.updateUser(
        UserAttributes(password: next),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _translateError(e.message);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Ocurrió un error inesperado. Intenta de nuevo.';
      });
    }
  }

  String _translateError(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login') || m.contains('invalid credentials')) {
      return 'La contraseña actual es incorrecta';
    }
    if (m.contains('same password')) {
      return 'La nueva contraseña debe ser diferente';
    }
    if (m.contains('password should be') || m.contains('password is too short')) {
      return 'La contraseña no cumple los requisitos mínimos';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Cambiar contraseña'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(controller: _currentController, label: 'Contraseña actual'),
            const SizedBox(height: 14),
            _field(controller: _newController, label: 'Nueva contraseña'),
            const SizedBox(height: 14),
            _field(
              controller: _confirmController,
              label: 'Confirmar nueva contraseña',
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Actualizar'),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      obscureText: _obscure,
      enabled: !_loading,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
