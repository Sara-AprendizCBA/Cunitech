import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dialog_animations.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/widgets/animated_list_item.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../models/rabbit.dart';
import '../../controllers/rabbit_controller.dart';
import '../../controllers/auth_controller.dart';
import 'rabbit_form_dialog.dart';
import 'rabbit_detail_screen.dart';

class RabbitsScreen extends StatefulWidget {
  const RabbitsScreen({super.key});

  @override
  State<RabbitsScreen> createState() => _RabbitsScreenState();
}

class _RabbitsScreenState extends State<RabbitsScreen> {
  late final RabbitController rabbitController;
  final AuthController authController = Get.find<AuthController>();
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    rabbitController = Get.isRegistered<RabbitController>()
        ? Get.find<RabbitController>()
        : Get.put(RabbitController());
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // CREATE (rabbit == null) y UPDATE (rabbit != null)
  void _showRabbitForm({Rabbit? rabbit}) {
    showScaleDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RabbitFormDialog(rabbit: rabbit),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar conejo...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
      onChanged: (value) => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBuildContext(context).isTablet;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      floatingActionButton: context.isMobile && authController.isAdmin
          ? FloatingActionButton(
              tooltip: 'Agregar conejo',
              onPressed: () => _showRabbitForm(),
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: Column(
        children: [
          // Header: buscador + botones
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.isMobile ? 16 : (isTablet ? 24 : 32),
              context.isMobile ? 16 : (isTablet ? 20 : 24),
              context.isMobile ? 16 : (isTablet ? 24 : 32),
              context.isMobile ? 12 : 16,
            ),
            child: context.isMobile
                ? Column(
                    children: [
                      _searchField(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.filter_list_rounded),
                              label: const Text('Filtrar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _searchField()),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.filter_list_rounded),
                        label: const Text('Filtrar'),
                      ),
                      if (authController.isAdmin) ...[
                        const SizedBox(width: 12),
                        PressableScale(
                          child: FilledButton.icon(
                            onPressed: () => _showRabbitForm(),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Nuevo Conejo'),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),

          // READ: lista de conejos
          Expanded(
            child: Obx(() {
              if (rabbitController.isLoading.value &&
                  rabbitController.rabbits.isEmpty) {
                return const AppLoadingIndicator(
                  label: 'Cargando conejos…',
                );
              }

              final rabbits = _searchController.text.isEmpty
                  ? rabbitController.rabbits
                  : rabbitController.searchRabbits(_searchController.text);

              if (rabbits.isEmpty) {
                return RefreshIndicator(
                  onRefresh: rabbitController.loadAllRabbits,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: _EmptyRabbitsState(
                              isSearching: _searchController.text.isNotEmpty,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: rabbitController.loadAllRabbits,
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    context.isMobile ? 16 : (isTablet ? 24 : 32),
                    0,
                    context.isMobile ? 16 : (isTablet ? 24 : 32),
                    // Hueco inferior en celular para que el orbe flotante
                    // no tape el ultimo conejo de la lista.
                    context.isMobile ? 132 : 0,
                  ),
                  itemCount: rabbits.length,
                  itemBuilder: (context, index) {
                    final rabbit = rabbits[index];
                    return AnimatedListItem(
                      index: index,
                      child: _RabbitCard(
                        rabbit: rabbit,
                        onTap: () => Get.to(
                          () => RabbitDetailScreen(rabbit: rabbit),
                          transition: Transition.zoom,
                          duration: const Duration(milliseconds: 300),
                        ),
                        onEdit: () => _showRabbitForm(rabbit: rabbit),
                        onDelete: () => _showDeleteDialog(rabbit),
                        canManage: authController.isAdmin,
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // DELETE con confirmación
  void _showDeleteDialog(Rabbit rabbit) {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar conejo'),
        content: Text('¿Deseas eliminar a ${rabbit.displayId}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final ok = await rabbitController.deleteRabbit(rabbit.id);
              if (!mounted) return;
              if (ok) {
                AppSnackbar.success(context, 'Conejo eliminado');
              } else {
                AppSnackbar.error(
                  context,
                  'No se puede eliminar: tiene registros relacionados',
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _RabbitCard extends StatelessWidget {
  final Rabbit rabbit;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool canManage;

  const _RabbitCard({
    required this.rabbit,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
    this.canManage = false,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = rabbit.photoUrl;
    final genderIcon = Icon(
      rabbit.gender == 'Macho' ? Icons.male : Icons.female,
      size: 28,
      color: AppTheme.accent,
    );

    return AppCard(
      margin: EdgeInsets.only(bottom: context.isMobile ? 12 : 16),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
            child: photoUrl != null && photoUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      photoUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      cacheWidth: 128,
                      cacheHeight: 128,
                      errorBuilder: (_, __, ___) => genderIcon,
                    ),
                  )
                : genderIcon,
          ),
          SizedBox(
            width: context.isMobile
                ? 12
                : (ResponsiveBuildContext(context).isTablet ? 20 : 24),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      rabbit.displayId,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    _HealthBadge(status: rabbit.healthStatus),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  rabbit.breed,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _InfoChip(
                      icon: Icons.cake_rounded,
                      label: '${rabbit.ageMonths} meses',
                    ),
                    if (rabbit.weightKg > 0)
                      _InfoChip(
                        icon: Icons.monitor_weight_outlined,
                        label: '${rabbit.weightKg} kg',
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Menú de tres puntos (onSelected, NO onTap)
          if (canManage)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HealthBadge extends StatelessWidget {
  final String status;

  const _HealthBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isHealthy = status.toLowerCase() == 'saludable';
    final color = isHealthy ? AppTheme.success : AppTheme.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _EmptyRabbitsState extends StatelessWidget {
  final bool isSearching;

  const _EmptyRabbitsState({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: isSearching
          ? Icons.search_off_rounded
          : Icons.cruelty_free_rounded,
      title: isSearching
          ? 'No se encontraron resultados'
          : 'Aún no hay conejos registrados',
      subtitle: isSearching
          ? 'Prueba con otro término de búsqueda.'
          : 'Los conejos que registres aparecerán aquí.',
    );
  }
}
