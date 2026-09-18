import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../controllers/dashboard_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController dashboardController = Get.put(DashboardController());

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      color: AppTheme.bgLight,
      child: Obx(() {
        // Este Obx principal controla el loading y todo el contenido
        if (dashboardController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: isMobile ? 24 : 40),
              _sectionLabel(context, 'RESUMEN GENERAL'),
              const SizedBox(height: 16),
              _buildMetricsGrid(context),
              const SizedBox(height: 40),
              _buildNextBirthBanner(context),
              const SizedBox(height: 40),
              _buildTableHeader(context),
              const SizedBox(height: 16),
              _buildActiveRabbits(context),
              const SizedBox(height: 48),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 6),
              Text(
                '${DateTime.now().day} de ${_getMonthName(DateTime.now().month)} · Granja Mosquera',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const _Avatar('GR'),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        mainAxisSpacing: isMobile ? 12 : 20,
        crossAxisSpacing: isMobile ? 12 : 20,
        childAspectRatio: isMobile ? 1.15 : 1.85,
      ),
      itemCount: 4,
      itemBuilder: (_, i) {
        return Obx(() => _MetricCard(
              label: _getMetricLabel(i),
              value: _getMetricValue(i),
              trend: _getMetricTrend(i),
              positive: _getMetricPositive(i),
            ));
      },
    );
  }

  // Métodos auxiliares para evitar leer .value fuera de Obx
  String _getMetricLabel(int i) {
    switch (i) {
      case 0: return 'Total Conejos';
      case 1: return 'Partos';
      case 2: return 'Supervivencia';
      case 3: return 'Alertas';
      default: return '';
    }
  }

  String _getMetricValue(int i) {
    switch (i) {
      case 0: return dashboardController.totalRabbits.value.toString();
      case 1: return dashboardController.totalBirths.value.toString();
      case 2: return dashboardController.survivalRate.value;
      case 3: return dashboardController.alerts.value.toString();
      default: return '0';
    }
  }

  String _getMetricTrend(int i) {
    switch (i) {
      case 0: return '+12 este mes';
      case 1: return '+8%';
      case 2: return '−2%';
      case 3: return 'Sin cambio';
      default: return '';
    }
  }

  bool? _getMetricPositive(int i) {
    switch (i) {
      case 0: return true;
      case 1: return true;
      case 2: return false;
      case 3: return null;
      default: return null;
    }
  }

  Widget _buildNextBirthBanner(BuildContext context) {
    final nextBirth = dashboardController.getNextExpectedBirth();
    if (nextBirth == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.accent.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: const Text('No hay partos próximos programados',
            style: TextStyle(color: Colors.white)),
      );
    }
    return const SizedBox(); // placeholder
  }

  Widget _buildTableHeader(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Row(
      children: [
        Expanded(
          child: Text(
            'CONEJAS ACTIVAS',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(letterSpacing: 0.8),
          ),
        ),
        if (!isMobile) TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Nueva Coneja'),
          style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
        ),
      ],
    );
  }

  Widget _buildActiveRabbits(BuildContext context) {
    return Obx(() {
      final list = dashboardController.activeRabbits;
      if (list.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: const Center(child: Text('No hay conejas reproductoras activas')),
        );
      }

      return Column(
        children: list.asMap().entries.map((e) {
          return _buildRabbitCard(context, e.value, e.key);
        }).toList(),
      );
    });
  }

  Widget _buildRabbitCard(BuildContext context, dynamic rabbit, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width < 700 ? 16 : 24,
              vertical: 18,
            ),
            child: Row(
              children: [
                _RabbitAvatar(initial: rabbit['name'][0], color: AppTheme.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${rabbit['name']} #${rabbit['id']}',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      _StatusPill(status: rabbit['isBreeder'] == true ? 'Reproductora' : 'Normal'),
                    ],
                  ),
                ),
                if (MediaQuery.of(context).size.width >= 700)
                  Text('${rabbit['weightKg']} kg', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textTertiary),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (80 + 40 * index).ms);
  }

  String _getMonthName(int month) {
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return months[month - 1];
  }
}

// ───────────────── WIDGETS AUXILIARES ─────────────────
class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar(this.initials);

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text(initials, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      );
}

class _MetricCard extends StatelessWidget {
  final String label, value, trend;
  final bool? positive;

  const _MetricCard({required this.label, required this.value, required this.trend, required this.positive});

  @override
  Widget build(BuildContext context) {
    final trendColor = positive == null
        ? AppTheme.textTertiary
        : positive!
            ? AppTheme.success
            : AppTheme.danger;

    final trendIcon = positive == null
        ? Icons.remove_rounded
        : positive!
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 32)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(trendIcon, size: 16, color: trendColor),
              const SizedBox(width: 6),
              Text(trend, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: trendColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RabbitAvatar extends StatelessWidget {
  final String initial;
  final Color color;
  const _RabbitAvatar({required this.initial, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.center,
        child: Text(initial, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color)),
      );
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFD4A76A), borderRadius: BorderRadius.circular(999)),
        child: Text(status, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
      );
}