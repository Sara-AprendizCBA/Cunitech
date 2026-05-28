import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────
//  MODELOS LOCALES (demo)
// ─────────────────────────────────────────────
enum RabbitStatus { gestante, enCelo, saludable, enfermo, destetando }

class _RabbitRow {
  final String id;
  final String name;
  final RabbitStatus status;
  final double weight;
  final String? nextBirth;

  const _RabbitRow({
    required this.id,
    required this.name,
    required this.status,
    required this.weight,
    this.nextBirth,
  });
}

extension on RabbitStatus {
  String get label {
    switch (this) {
      case RabbitStatus.gestante:
        return 'Gestante';
      case RabbitStatus.enCelo:
        return 'En celo';
      case RabbitStatus.saludable:
        return 'Saludable';
      case RabbitStatus.enfermo:
        return 'Enfermo';
      case RabbitStatus.destetando:
        return 'Destetando';
    }
  }

  Color get bgColor {
    switch (this) {
      case RabbitStatus.gestante:
        return AppTheme.accentLight;
      case RabbitStatus.enCelo:
        return const Color(0xFFFFF4E5);
      case RabbitStatus.saludable:
        return const Color(0xFFE6F9EF);
      case RabbitStatus.enfermo:
        return const Color(0xFFFEE8E8);
      case RabbitStatus.destetando:
        return const Color(0xFFF3E8FF);
    }
  }

  Color get textColor {
    switch (this) {
      case RabbitStatus.gestante:
        return AppTheme.accent;
      case RabbitStatus.enCelo:
        return const Color(0xFFB45309);
      case RabbitStatus.saludable:
        return const Color(0xFF15803D);
      case RabbitStatus.enfermo:
        return const Color(0xFFDC2626);
      case RabbitStatus.destetando:
        return const Color(0xFF7C3AED);
    }
  }
}

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _rabbits = [
    _RabbitRow(id: 'A12', name: 'Blanca', status: RabbitStatus.gestante, weight: 3.2, nextBirth: '18 may'),
    _RabbitRow(id: 'B03', name: 'Pelusa', status: RabbitStatus.enCelo, weight: 2.9),
    _RabbitRow(id: 'D01', name: 'Luna', status: RabbitStatus.saludable, weight: 3.5),
    _RabbitRow(id: 'C07', name: 'Rex', status: RabbitStatus.enfermo, weight: 3.1),
    _RabbitRow(id: 'E02', name: 'Canela', status: RabbitStatus.destetando, weight: 2.7),
  ];

  static const _metrics = [
    _Metric('Total conejos', '142', '+12 este mes', true),
    _Metric('Partos', '28', '+8%', true),
    _Metric('Supervivencia', '94%', '−2%', false),
    _Metric('Alertas', '7', 'Sin cambio', null),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgLight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 40),
            _sectionLabel(context, 'RESUMEN GENERAL'),
            const SizedBox(height: 16),
            _buildMetricsGrid(context),
            const SizedBox(height: 40),
            _buildNextBirthBanner(context),
            const SizedBox(height: 40),
            _buildTableHeader(context),
            const SizedBox(height: 16),
            ..._rabbits.asMap().entries.map(
                  (e) => _buildRabbitCard(context, e.value, e.key),
                ),
            const SizedBox(height: 48),
          ],
        ),
      ),
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
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              Text(
                '14 de mayo 2026  ·  Granja Mosquera',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        _Avatar('JL'),
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.85,
      ),
      itemCount: _metrics.length,
      itemBuilder: (_, i) => _MetricCard(
        metric: _metrics[i],
        context: context,
      ).animate().fadeIn(delay: (60 * i).ms, duration: 400.ms).slideY(
            begin: 0.08,
            end: 0,
          ),
    );
  }

  Widget _buildNextBirthBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.accent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRÓXIMO PARTO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.75),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Blanca #A12  →  18 mayo 2026',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'En 4 días',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms);
  }

  Widget _buildTableHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'CONEJAS ACTIVAS',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(letterSpacing: 0.8),
          ),
        ),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Nueva Coneja'),
          style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
        ),
      ],
    );
  }

  Widget _buildRabbitCard(BuildContext context, _RabbitRow r, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              children: [
                _RabbitAvatar(initial: r.name[0], color: r.status.textColor),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${r.name} #${r.id}', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      _StatusPill(status: r.status),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${r.weight} kg', style: Theme.of(context).textTheme.titleMedium),
                    if (r.nextBirth != null) ...[
                      const SizedBox(height: 4),
                      Text(r.nextBirth!, style: TextStyle(fontSize: 13, color: AppTheme.accent, fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
                const SizedBox(width: 16),
                Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textTertiary),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (80 + 40 * index).ms, duration: 400.ms).slideX(begin: 0.04, end: 0);
  }
}

// ─────────────────────────────────────────────
//  WIDGETS AUXILIARES
// ─────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar(this.initials);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: Text(initials, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }
}

class _Metric {
  final String label;
  final String value;
  final String trend;
  final bool? positive;
  const _Metric(this.label, this.value, this.trend, this.positive);
}

class _MetricCard extends StatelessWidget {
  final _Metric metric;
  final BuildContext context;

  const _MetricCard({required this.metric, required this.context});

  @override
  Widget build(BuildContext _) {
    final trendColor = metric.positive == null
        ? AppTheme.textTertiary
        : metric.positive!
            ? AppTheme.success
            : AppTheme.danger;

    final trendIcon = metric.positive == null
        ? Icons.remove_rounded
        : metric.positive!
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(metric.label.toUpperCase(), style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 12),
          Text(
            metric.value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 32),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(trendIcon, size: 16, color: trendColor),
              const SizedBox(width: 6),
              Text(metric.trend, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: trendColor)),
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
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
      alignment: Alignment.center,
      child: Text(initial, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final RabbitStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(color: status.bgColor, borderRadius: BorderRadius.circular(999)),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: status.textColor),
      ),
    );
  }
}