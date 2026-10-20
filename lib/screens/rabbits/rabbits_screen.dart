import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/app_snackbar.dart';
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
    Get.dialog(RabbitFormDialog(rabbit: rabbit), barrierDismissible: false);
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
              context.isMobile
                  ? 16
                  : (isTablet ? 24 : 32),
              context.isMobile
                  ? 16
                  : (isTablet ? 20 : 24),
              context.isMobile
                  ? 16
                  : (isTablet ? 24 : 32),
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
                        FilledButton.icon(
                          onPressed: () => _showRabbitForm(),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Nuevo Conejo'),
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
                return const Center(child: CircularProgressIndicator());
              }

              final rabbits = _searchController.text.isEmpty
                  ? rabbitController.rabbits
                  : rabbitController.searchRabbits(_searchController.text);

              if (rabbits.isEmpty) {
                return Center(
                  child: Text(
                    _searchController.text.isEmpty
                        ? 'No hay conejos registrados'
                        : 'No se encontraron resultados',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: rabbitController.loadAllRabbits,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.isMobile
                        ? 16
                        : (isTablet ? 24 : 32),
                  ).copyWith(
                    bottom: context.isMobile ? 80 : 0,
                  ),
                  itemCount: rabbits.length,
                  itemBuilder: (context, index) {
                    final rabbit = rabbits[index];
                    return _RabbitCard(
                      rabbit: rabbit,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RabbitDetailScreen(rabbit: rabbit),
                        ),
                      ),
                      onEdit: () => _showRabbitForm(rabbit: rabbit),
                      onDelete: () => _showDeleteDialog(rabbit),
                      canManage: authController.isAdmin,
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
    return Container(
      margin: EdgeInsets.only(bottom: context.isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(
              context.isMobile
                  ? 12
                  : (ResponsiveBuildContext(context).isTablet ? 16 : 20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                  backgroundImage:
                      rabbit.photoUrl != null && rabbit.photoUrl!.isNotEmpty
                      ? NetworkImage(rabbit.photoUrl!)
                      : null,
                  child: rabbit.photoUrl == null || rabbit.photoUrl!.isEmpty
                      ? Icon(
                          rabbit.gender == 'Macho' ? Icons.male : Icons.female,
                          size: 28,
                          color: AppTheme.accent,
                        )
                      : null,
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppTheme.textSecondary),
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
                            Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
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
