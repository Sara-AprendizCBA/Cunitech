import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/responsive.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/user_profile.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final userController = Get.put(UserController());
  final authController = Get.find<AuthController>();

  final _searchCtrl = TextEditingController();

  static const Color _green = Color(0xFF2E7D32);
  static const List<String> _roles = [
    'usuario',
    'ayudante',
    'veterinario',
    'admin',
  ];

  String? get _myId =>
      authController.currentUser.value?['id_usuario'] as String?;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _rolLabel(String rol) => switch (rol) {
        'admin' => 'Admin',
        'veterinario' => 'Veterinario',
        'ayudante' => 'Ayudante',
        _ => 'Usuario',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Gestión de Usuarios'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStats(),
            _buildFilters(context),
            Expanded(child: _buildList(context)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Crear usuario'),
      ),
    );
  }

  // ────── Estadísticas ──────

  Widget _buildStats() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatChip(
              label: 'Total',
              value: userController.totalUsers,
              color: AppTheme.textSecondary,
            ),
            _StatChip(
              label: 'Admins',
              value: userController.totalAdmins,
              color: AppTheme.accent,
            ),
            _StatChip(
              label: 'Veterinarios',
              value: userController.totalVeterinarios,
              color: AppTheme.info,
            ),
            _StatChip(
              label: 'Ayudantes',
              value: userController.totalAyudantes,
              color: _green,
            ),
          ],
        ),
      ),
    );
  }

  // ────── Filtros ──────

  Widget _buildFilters(BuildContext context) {
    final isMobile = context.isMobile;
    final search = _searchField();
    final role = _rolFilter();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: isMobile
          ? Column(
              children: [
                search,
                const SizedBox(height: 8),
                role,
              ],
            )
          : Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 12),
                SizedBox(width: 200, child: role),
              ],
            ),
    );
  }

  Widget _searchField() {
    return Obx(
      () => TextField(
        controller: _searchCtrl,
        onChanged: userController.setSearch,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o email...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: userController.searchQuery.value.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Limpiar',
                  onPressed: () {
                    _searchCtrl.clear();
                    userController.setSearch('');
                  },
                ),
        ),
      ),
    );
  }

  Widget _rolFilter() {
    return Obx(
      () => DropdownButtonFormField<String>(
        initialValue: userController.rolFilter.value,
        isExpanded: true,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: const [
          DropdownMenuItem(value: 'todos', child: Text('Todos')),
          DropdownMenuItem(value: 'admin', child: Text('Admin')),
          DropdownMenuItem(value: 'veterinario', child: Text('Veterinario')),
          DropdownMenuItem(value: 'ayudante', child: Text('Ayudante')),
          DropdownMenuItem(value: 'usuario', child: Text('Usuario')),
        ],
        onChanged: (value) {
          if (value != null) userController.setRolFilter(value);
        },
      ),
    );
  }

  // ────── Lista ──────

  Widget _buildList(BuildContext context) {
    return Obx(() {
      if (userController.isLoading.value && userController.users.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      final list = userController.filteredUsers;
      if (list.isEmpty) {
        return const Center(child: Text('No hay usuarios registrados'));
      }
      return ListView.builder(
        padding: EdgeInsets.all(context.adaptivePadding).copyWith(top: 8),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final user = list[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildUserCard(context, user, key: ValueKey(user.idUsuario)),
          );
        },
      );
    });
  }

  Widget _buildUserCard(BuildContext context, UserProfile user,
      {Key? key}) {
    final isMobile = context.isMobile;
    final isSelf = _myId == user.idUsuario;

    final avatar = CircleAvatar(
      radius: 22,
      backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
      child: Text(
        _initial(user),
        style: const TextStyle(
          color: AppTheme.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.nombre.isEmpty ? 'Sin nombre' : user.nombre,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 2),
        Text(
          user.email ?? '—',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );

    final controls = Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(width: 150, child: _rolDropdown(user, isSelf)),
        _activoSwitch(user, isSelf),
        if (!isSelf)
          IconButton(
            tooltip: 'Eliminar',
            color: AppTheme.danger,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(user),
          ),
      ],
    );

    return Container(
      key: key,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    avatar,
                    const SizedBox(width: 12),
                    Expanded(child: info),
                  ],
                ),
                const SizedBox(height: 12),
                controls,
              ],
            )
          : Row(
              children: [
                avatar,
                const SizedBox(width: 12),
                Expanded(child: info),
                const SizedBox(width: 12),
                controls,
              ],
            ),
    );
  }

  Widget _rolDropdown(UserProfile user, bool isSelf) {
    return DropdownButtonFormField<String>(
      initialValue: user.rol,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: _roles
          .map(
            (r) => DropdownMenuItem(value: r, child: Text(_rolLabel(r))),
          )
          .toList(),
      onChanged: isSelf
          ? null
          : (value) {
              if (value != null && value != user.rol) {
                _changeRol(user, value);
              }
            },
    );
  }

  Widget _activoSwitch(UserProfile user, bool isSelf) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: user.activo,
          onChanged: isSelf ? null : (value) => _toggleActivo(user, value),
        ),
        Text(
          user.activo ? 'Activo' : 'Inactivo',
          style: TextStyle(
            fontSize: 12,
            color: user.activo ? _green : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  String _initial(UserProfile user) {
    final source = user.nombre.isNotEmpty ? user.nombre : (user.email ?? '');
    return source.isEmpty ? '?' : source[0].toUpperCase();
  }

  // ────── Acciones ──────

  Future<void> _changeRol(UserProfile user, String nuevoRol) async {
    final ok = await userController.cambiarRol(user.idUsuario, nuevoRol);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.success(context, 'Rol actualizado');
    } else {
      AppSnackbar.error(context, 'Error al actualizar el rol');
    }
  }

  Future<void> _toggleActivo(UserProfile user, bool activo) async {
    final ok = await userController.toggleActivo(user.idUsuario, activo);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.success(
        context,
        activo ? 'Usuario activado' : 'Usuario desactivado',
      );
    } else {
      AppSnackbar.error(context, 'Error al actualizar el estado');
    }
  }

  Future<void> _showCreateUserDialog() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CreateUserDialog(),
    );
    if (created == true && mounted) {
      AppSnackbar.success(context, 'Invitación enviada y usuario creado');
    }
  }

  Future<void> _confirmDelete(UserProfile user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Eliminar a ${user.nombre.isEmpty ? (user.email ?? 'este usuario') : user.nombre}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final ok = await userController.eliminarUsuario(user.idUsuario);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.success(context, 'Usuario eliminado');
    } else {
      AppSnackbar.error(context, 'Error al eliminar el usuario');
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog();

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _personalCtrl = TextEditingController();
  final _laboralCtrl = TextEditingController();
  final _userController = Get.find<UserController>();

  static final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static const List<String> _rolesPermitidos = [
    'admin',
    'veterinario',
    'ayudante',
  ];

  String _rol = 'ayudante';
  bool _saving = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _personalCtrl.dispose();
    _laboralCtrl.dispose();
    super.dispose();
  }

  String _rolLabel(String rol) => switch (rol) {
        'admin' => 'Admin',
        'veterinario' => 'Veterinario',
        _ => 'Ayudante',
      };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await _userController.crearUsuario(
      personalEmail: _personalCtrl.text.trim(),
      laboralEmail: _laboralCtrl.text.trim(),
      nombre: _nombreCtrl.text.trim(),
      rol: _rol,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _saving = false);
      AppSnackbar.error(
        context,
        'No se pudo crear el usuario. Revisa los datos y tu conexión.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear usuario'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa el nombre'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _personalCtrl,
                  enabled: !_saving,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo personal',
                    hintText: 'donde recibirá la invitación',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Ingresa el correo personal';
                    if (!_emailRe.hasMatch(value)) return 'Correo no válido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _laboralCtrl,
                  enabled: !_saving,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo laboral (login)',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Ingresa el correo laboral';
                    if (!_emailRe.hasMatch(value)) return 'Correo no válido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _rol,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    prefixIcon: Icon(Icons.workspace_premium_outlined),
                  ),
                  items: _rolesPermitidos
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(_rolLabel(r)),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _rol = value);
                        },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.person_add_alt_1),
          label: Text(_saving ? 'Creando...' : 'Crear y enviar'),
        ),
      ],
    );
  }
}
