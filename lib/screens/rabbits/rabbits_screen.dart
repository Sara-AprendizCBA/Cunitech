import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rabbit.dart';
import '../../controllers/rabbit_controller.dart';
import 'rabbit_form_dialog.dart';

class RabbitsScreen extends StatefulWidget {
  const RabbitsScreen({super.key});

  @override
  State<RabbitsScreen> createState() => _RabbitsScreenState();
}

class _RabbitsScreenState extends State<RabbitsScreen> {
  late final RabbitController rabbitController;
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
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      color: AppTheme.bgLight,
      child: Column(
        children: [
          // Header: buscador + botones
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
            child: isMobile
                ? Column(
                    children: [
                      _searchField(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.filter_list_rounded),
                              label: const Text('Filtrar'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showRabbitForm(),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Nuevo'),
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
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showRabbitForm(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Nuevo Conejo'),
                      ),
                    ],
                  ),
          ),

          // READ: lista de conejos
          Expanded(
            child: Obx(
              () {
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
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: rabbitController.loadAllRabbits,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
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
                      );
                    },
                  ),
                );
              },
            ),
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
        content: Text('¿Deseas eliminar a ${rabbit.name} (#${rabbit.id})?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              rabbitController.deleteRabbit(rabbit.id);
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

  const _RabbitCard({
    required this.rabbit,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                  child: Icon(
                    rabbit.gender == 'Macho' ? Icons.male : Icons.female,
                    size: 28,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(width: 24),
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
                            '${rabbit.name} #${rabbit.id}',
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

// ─────────────────────────────────────────────
// DETALLE DEL CONEJO
// ─────────────────────────────────────────────

class RabbitDetailScreen extends StatelessWidget {
  final Rabbit rabbit;

  const RabbitDetailScreen({super.key, required this.rabbit});

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final rabbitController = Get.find<RabbitController>();

    // Obx: si se edita el conejo, el detalle se actualiza solo
    return Obx(() {
      final r = rabbitController.getRabbitById(rabbit.id) ?? rabbit;

      return Scaffold(
        backgroundColor: AppTheme.bgLight,
        appBar: AppBar(
          title: Text('${r.name} #${r.id}'),
          backgroundColor: AppTheme.surfaceLight,
          elevation: 0,
          foregroundColor: AppTheme.textPrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                      child: Icon(
                        r.gender == 'Macho' ? Icons.male : Icons.female,
                        size: 48,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name,
                              style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 6),
                          Text(
                            '${r.breed} #${r.id}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Información General',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Estado',
                value: r.healthStatus,
                icon: Icons.health_and_safety_rounded,
                color: r.healthStatus.toLowerCase() == 'saludable'
                    ? AppTheme.success
                    : AppTheme.warning,
              ),
              _InfoCard(
                title: 'Género',
                value: r.gender,
                icon: r.gender == 'Macho' ? Icons.male : Icons.female,
              ),
              _InfoCard(
                title: 'Raza',
                value: r.breed,
                icon: Icons.pets_rounded,
              ),
              _InfoCard(
                title: 'Fecha de Nacimiento',
                value: '${_fmt(r.birthDate)}  (${r.ageMonths} meses)',
                icon: Icons.cake_rounded,
              ),
              if (r.weightKg > 0)
                _InfoCard(
                  title: 'Peso',
                  value: '${r.weightKg} kg',
                  icon: Icons.monitor_weight_outlined,
                ),
              _InfoCard(
                title: 'Fecha de Ingreso',
                value: _fmt(r.registrationDate),
                icon: Icons.calendar_today_rounded,
              ),
              if (r.motherId != null)
                _InfoCard(
                  title: 'Madre',
                  value: '#${r.motherId}',
                  icon: Icons.female,
                ),
              if (r.fatherId != null)
                _InfoCard(
                  title: 'Padre',
                  value: '#${r.fatherId}',
                  icon: Icons.male,
                ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Get.dialog(
            RabbitFormDialog(rabbit: r),
            barrierDismissible: false,
          ),
          backgroundColor: AppTheme.accent,
          child: const Icon(Icons.edit_rounded),
        ),
      );
    });
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.borderLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (color ?? AppTheme.accent).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color ?? AppTheme.accent),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}