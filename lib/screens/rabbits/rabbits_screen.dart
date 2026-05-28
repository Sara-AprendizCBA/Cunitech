import 'package:flutter/material.dart';
import '../../models/rabbit.dart';
import '../../core/theme/app_theme.dart';

class RabbitsScreen extends StatelessWidget {
  const RabbitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rabbits = [
      Rabbit(id: 'R001', breed: 'Nueva Zelanda', ageMonths: 12, weightKg: 4.5, gender: 'Macho', healthStatus: 'Saludable', registrationDate: DateTime(2025, 5, 1)),
      Rabbit(id: 'R002', breed: 'California', ageMonths: 8, weightKg: 4.2, gender: 'Hembra', healthStatus: 'Saludable', registrationDate: DateTime(2025, 9, 1)),
      Rabbit(id: 'R003', breed: 'Nueva Zelanda', ageMonths: 6, weightKg: 3.8, gender: 'Macho', healthStatus: 'En Tratamiento', registrationDate: DateTime(2025, 11, 1)),
    ];

    return Container(
      color: AppTheme.bgLight,
      child: Column(
        children: [
          // Header interno (ya que el top bar está en MainScreen)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
            child: Row(
              children: [
                Text(
                  'Conejos',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list_rounded),
                  label: const Text('Filtrar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuevo Conejo'),
                ),
              ],
            ),
          ),

          // Lista de conejos
          Expanded(
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RabbitCard extends StatelessWidget {
  final Rabbit rabbit;
  final VoidCallback onTap;

  const _RabbitCard({required this.rabbit, required this.onTap});

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
                  backgroundColor: AppTheme.accent.withOpacity(0.1),
                  child: Icon(
                    Icons.pets,
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
                            rabbit.id,
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
                          _InfoChip(
                            icon: rabbit.gender == 'Macho' ? Icons.male : Icons.female,
                            label: rabbit.gender,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Acción
                Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: AppTheme.textTertiary,
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
        color: color.withOpacity(0.1),
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

class RabbitDetailScreen extends StatelessWidget {
  final Rabbit rabbit;

  const RabbitDetailScreen({super.key, required this.rabbit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(rabbit.id),
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
                    backgroundColor: AppTheme.accent.withOpacity(0.1),
                    child: Icon(
                      Icons.pets,
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
                          rabbit.id,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          rabbit.breed,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _DetailChip(
                              label: '${rabbit.ageMonths} meses',
                              icon: Icons.cake_rounded,
                            ),
                            const SizedBox(width: 16),
                            _DetailChip(
                              label: '${rabbit.weightKg} kg',
                              icon: Icons.monitor_weight_outlined,
                            ),
                            const SizedBox(width: 16),
                            _DetailChip(
                              label: rabbit.gender,
                              icon: rabbit.gender == 'Macho' ? Icons.male : Icons.female,
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
              value: rabbit.healthStatus,
              icon: Icons.health_and_safety_rounded,
              color: rabbit.healthStatus.toLowerCase() == 'saludable'
                  ? AppTheme.success
                  : AppTheme.warning,
            ),
            _InfoCard(
              title: "Género",
              value: rabbit.gender,
              icon: rabbit.gender == 'Macho' ? Icons.male : Icons.female,
            ),
            _InfoCard(
              title: "Fecha de Registro",
              value: "${rabbit.registrationDate.day}/${rabbit.registrationDate.month}/${rabbit.registrationDate.year}",
              icon: Icons.calendar_today_rounded,
            ),
            _InfoCard(
              title: "Última Alimentación",
              value: "Hace 2 días",
              icon: Icons.restaurant_rounded,
            ),
            _InfoCard(
              title: "Último Tratamiento",
              value: "10 Mayo 2026",
              icon: Icons.medical_services_rounded,
            ),

            const SizedBox(height: 40),

            // Historial
            Text(
              'Historial Reciente',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'El historial completo se mostrará aquí...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
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
            color: (color ?? AppTheme.accent).withOpacity(0.1),
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