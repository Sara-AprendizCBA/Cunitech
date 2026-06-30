import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rabbit.dart';
import '../../controllers/rabbit_controller.dart';

class RabbitsScreen extends StatefulWidget {
  const RabbitsScreen({super.key});

  @override
  State<RabbitsScreen> createState() => _RabbitsScreenState();
}

class _RabbitsScreenState extends State<RabbitsScreen> {
  final rabbitController = Get.find<RabbitController>();
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgLight,
      child: Column(
        children: [
          // Header con filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar conejo...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () {
                    // Abrir diálogo de filtros
                  },
                  icon: const Icon(Icons.filter_list_rounded),
                  label: const Text('Filtrar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // Abrir diálogo para crear nuevo conejo
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuevo Conejo'),
                ),
              ],
            ),
          ),

          // Lista de conejos
          Expanded(
            child: Obx(
              () {
                if (rabbitController.isLoading.value) {
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

                return ListView.builder(
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
                      onDelete: () => _showDeleteDialog(rabbit),
                      onEdit: () => _showEditDialog(rabbit),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

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
              rabbitController.deleteRabbit(rabbit.id);
              Get.back();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Rabbit rabbit) {
    // TODO: Implementar diálogo de edición
    Get.snackbar('Info', 'Edición en desarrollo');
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
                // Avatar
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

                // Información principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${rabbit.name} #${rabbit.id}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(width: 12),
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
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.cake_rounded,
                            label: '${rabbit.ageMonths} meses',
                          ),
                          const SizedBox(width: 12),
                          _InfoChip(
                            icon: Icons.monitor_weight_outlined,
                            label: '${rabbit.weightKg} kg',
                          ),
                          const SizedBox(width: 12),
                          if (rabbit.isBreeder)
                            _InfoChip(
                              icon: Icons.favorite_rounded,
                              label: '${rabbit.litterCount} partos',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Acciones
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: onEdit,
                      child: const Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: onDelete,
                      child: const Row(
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
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// RABBIT DETAIL SCREEN
// ─────────────────────────────────────────────

class RabbitDetailScreen extends StatefulWidget {
  final Rabbit rabbit;

  const RabbitDetailScreen({super.key, required this.rabbit});

  @override
  State<RabbitDetailScreen> createState() => _RabbitDetailScreenState();
}

class _RabbitDetailScreenState extends State<RabbitDetailScreen> {
  final rabbitController = Get.find<RabbitController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text('${widget.rabbit.name} #${widget.rabbit.id}'),
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                    child: Icon(
                      widget.rabbit.gender == 'Macho'
                          ? Icons.male
                          : Icons.female,
                      size: 56,
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.rabbit.name,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.rabbit.breed} #${widget.rabbit.id}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _DetailChip(
                              label: '${widget.rabbit.ageMonths} meses',
                              icon: Icons.cake_rounded,
                            ),
                            const SizedBox(width: 16),
                            _DetailChip(
                              label: '${widget.rabbit.weightKg} kg',
                              icon: Icons.monitor_weight_outlined,
                            ),
                            const SizedBox(width: 16),
                            _DetailChip(
                              label: widget.rabbit.gender,
                              icon: widget.rabbit.gender == 'Macho'
                                  ? Icons.male
                                  : Icons.female,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Información detallada
            Text(
              'Información General',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            _InfoCard(
              title: "Estado Sanitario",
              value: widget.rabbit.healthStatus,
              icon: Icons.health_and_safety_rounded,
              color: widget.rabbit.healthStatus.toLowerCase() == 'saludable'
                  ? AppTheme.success
                  : AppTheme.warning,
            ),
            _InfoCard(
              title: "Género",
              value: widget.rabbit.gender,
              icon: widget.rabbit.gender == 'Macho' ? Icons.male : Icons.female,
            ),
            _InfoCard(
              title: "Raza",
              value: widget.rabbit.breed,
              icon: Icons.pets_rounded,
            ),
            if (widget.rabbit.isBreeder) ...[
              _InfoCard(
                title: "Partos",
                value: '${widget.rabbit.litterCount}',
                icon: Icons.favorite_rounded,
              ),
              if (widget.rabbit.expectedBirthDate != null)
                _InfoCard(
                  title: "Próximo Parto",
                  value:
                      '${widget.rabbit.expectedBirthDate!.day}/${widget.rabbit.expectedBirthDate!.month}/${widget.rabbit.expectedBirthDate!.year}',
                  icon: Icons.calendar_today_rounded,
                ),
            ],
            _InfoCard(
              title: "Fecha de Registro",
              value:
                  "${widget.rabbit.registrationDate.day}/${widget.rabbit.registrationDate.month}/${widget.rabbit.registrationDate.year}",
              icon: Icons.calendar_today_rounded,
            ),
            if (widget.rabbit.lastFeedingDate != null)
              _InfoCard(
                title: "Última Alimentación",
                value:
                    "${widget.rabbit.lastFeedingDate!.day}/${widget.rabbit.lastFeedingDate!.month}/${widget.rabbit.lastFeedingDate!.year}",
                icon: Icons.restaurant_rounded,
              ),
            if (widget.rabbit.notes != null && widget.rabbit.notes!.isNotEmpty)
              _InfoCard(
                title: "Notas",
                value: widget.rabbit.notes!,
                icon: Icons.note_rounded,
              ),

            const SizedBox(height: 40),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        rabbitController.recordFeeding(widget.rabbit.id),
                    icon: const Icon(Icons.restaurant_rounded),
                    label: const Text('Registrar Alimentación'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        rabbitController.recordTreatment(widget.rabbit.id),
                    icon: const Icon(Icons.medical_services_rounded),
                    label: const Text('Registrar Tratamiento'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Abrir diálogo de edición
        },
        backgroundColor: AppTheme.accent,
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _DetailChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
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
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}