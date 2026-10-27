import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_loading.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/insight_recomendacion.dart';
import '../../models/rabbit.dart';
import '../../services/insight_service.dart';
import '../chat/voice_assistant_screen.dart';
import '../rabbits/rabbit_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final DashboardController dashboardController = Get.put(
    DashboardController(),
  );
  final InsightService _insightService = InsightService();
  late Future<InsightPanel> _insightFuture;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _insightFuture = _insightService.obtenerRecomendaciones();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isTablet = ResponsiveBuildContext(context).isTablet;
    final isDesktop = !isMobile && !isTablet;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      floatingActionButton: null,
      body: Obx(() {
        // Este Obx principal controla el loading y todo el contenido
        if (dashboardController.isLoading.value) {
          return const AppLoadingIndicator(label: 'Cargando criadero…');
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(context.adaptivePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: isMobile ? 24 : (isTablet ? 32 : 40)),
              _sectionLabel(context, 'RESUMEN GENERAL'),
              SizedBox(height: isMobile ? 12 : 16),
              _buildMetricsGrid(context),
              SizedBox(height: isMobile ? 24 : (isTablet ? 32 : 40)),
              _buildNextBirthBanner(context),
              SizedBox(height: isMobile ? 24 : (isTablet ? 32 : 40)),
              _buildTableHeader(context),
              SizedBox(height: isMobile ? 12 : 16),
              _buildActiveRabbits(context),
              SizedBox(height: isMobile ? 32 : (isTablet ? 40 : 48)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${DateTime.now().day} de ${_getMonthName(DateTime.now().month)} · Cunicultura CBA',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
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
    final isMobile = context.isMobile;

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
        return Obx(
          () => _MetricCard(
            label: _getMetricLabel(i),
            value: _getMetricValue(i),
            trend: _getMetricTrend(i),
            positive: _getMetricPositive(i),
          ),
        );
      },
    );
  }

  // Métodos auxiliares para evitar leer .value fuera de Obx
  String _getMetricLabel(int i) {
    switch (i) {
      case 0:
        return 'Total Conejos';
      case 1:
        return 'Partos';
      case 2:
        return 'Supervivencia';
      case 3:
        return 'Alertas';
      default:
        return '';
    }
  }

  String _getMetricValue(int i) {
    switch (i) {
      case 0:
        return dashboardController.totalRabbits.value.toString();
      case 1:
        return dashboardController.totalBirths.value.toString();
      case 2:
        return dashboardController.survivalRate.value;
      case 3:
        return dashboardController.alerts.value.toString();
      default:
        return '0';
    }
  }

  String _getMetricTrend(int i) {
    switch (i) {
      case 0:
        return '${dashboardController.rabbitsThisMonth.value} este mes';
      case 1:
        return '${dashboardController.birthsThisMonth.value} este mes';
      case 2:
        return '${dashboardController.liveKitsTotal.value} crías vivas';
      case 3:
        return dashboardController.alerts.value == 0
            ? 'Todo al día'
            : 'Requieren atención';
      default:
        return '';
    }
  }

  bool? _getMetricPositive(int i) {
    switch (i) {
      case 0:
        return true;
      case 1:
        return true;
      case 2:
        return null;
      case 3:
        return dashboardController.alerts.value == 0 ? null : false;
      default:
        return null;
    }
  }

  Widget _buildNextBirthBanner(BuildContext context) {
    final nextBirth = dashboardController.getNextExpectedBirth();
    if (nextBirth == null) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.isMobile ? 16 : 24,
          vertical: context.isMobile ? 12 : 20,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Text(
          'No hay partos próximos programados',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    final isOverdue = dashboardController.overduePregnancies.any(
      (rabbit) => rabbit.id == nextBirth.id,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final matingDate = nextBirth.matingDate;
    final dueDate =
        nextBirth.expectedBirthDate ??
        (matingDate == null ? null : matingDate.add(const Duration(days: 31)));
    final daysUntil = dueDate == null
        ? null
        : DateTime(
            dueDate.year,
            dueDate.month,
            dueDate.day,
          ).difference(today).inDays;

    final Color background;
    final Color foreground;
    final IconData icon;
    final String message;
    if (isOverdue) {
      background = const Color(0xFFFEE2E2);
      foreground = const Color(0xFF991B1B);
      icon = Icons.warning_rounded;
      message = 'URGENTE: día 34+';
    } else if (daysUntil == 0) {
      background = const Color(0xFFB91C1C);
      foreground = Colors.white;
      icon = Icons.priority_high_rounded;
      message = '¡PARTO HOY!';
    } else if (daysUntil != null && daysUntil >= 1 && daysUntil <= 3) {
      background = const Color(0xFFFEE2E2);
      foreground = const Color(0xFF991B1B);
      icon = Icons.notifications_active_rounded;
      message = 'Preparar nido';
    } else if (daysUntil != null && daysUntil <= 7) {
      background = const Color(0xFFFEF3C7);
      foreground = const Color(0xFF92400E);
      icon = Icons.event_available_rounded;
      message = 'Preparar nido pronto';
    } else {
      background = AppTheme.surfaceLight;
      foreground = AppTheme.textSecondary;
      icon = Icons.event_available_rounded;
      message = daysUntil == null ? 'Parto esperado' : 'En $daysUntil días';
    }

    final formattedDueDate = dueDate == null
        ? 'Fecha sin registrar'
        : '${dueDate.day}/${dueDate.month}/${dueDate.year}';
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: () => _showBirthInfoDialog(context, nextBirth),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: context.isMobile ? 16 : 24,
            vertical: context.isMobile ? 12 : 20,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: foreground.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${nextBirth.displayId} · $formattedDueDate',
                      style: TextStyle(color: foreground),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBirthInfoDialog(BuildContext context, Rabbit rabbit) {
    final matingDate = rabbit.matingDate;
    final dueDate =
        rabbit.expectedBirthDate ??
        (matingDate == null ? null : matingDate.add(const Duration(days: 31)));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysRemaining = dueDate == null
        ? null
        : DateTime(
            dueDate.year,
            dueDate.month,
            dueDate.day,
          ).difference(today).inDays;
    final isOverdue = dashboardController.overduePregnancies.any(
      (item) => item.id == rabbit.id,
    );
    final alertColor =
        (daysRemaining != null && daysRemaining <= 2) || isOverdue
        ? AppTheme.danger
        : AppTheme.warning;
    final formattedDate = dueDate == null
        ? 'Sin registrar'
        : '${dueDate.day}/${dueDate.month}/${dueDate.year}';

    Get.dialog<void>(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: alertColor),
            const SizedBox(width: 12),
            const Expanded(child: Text('Parto próximo')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _birthInfoRow('Coneja', rabbit.displayId),
              _birthInfoRow('Fecha probable', formattedDate),
              _birthInfoRow(
                'Días restantes',
                daysRemaining == null
                    ? 'Sin fecha'
                    : daysRemaining == 0
                    ? 'HOY'
                    : daysRemaining < 0
                    ? 'Atrasado ${daysRemaining.abs()} días'
                    : '$daysRemaining días',
              ),
              SizedBox(height: context.isMobile ? 12 : 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Recomendaciones:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (daysRemaining != null && daysRemaining > 3)
                const Text('Vigilar el comportamiento de la coneja')
              else if (daysRemaining != null && daysRemaining >= 1)
                const Text(
                  'Preparar nido con material limpio\n'
                  'Verificar que tenga agua fresca\n'
                  'Evitar manipulación',
                )
              else if (daysRemaining == 0)
                const Text(
                  'Estar atento al parto HOY\n'
                  'No molestar a la coneja\n'
                  'Alejar al macho',
                )
              else
                const Text(
                  'El parto supera la fecha prevista.\n'
                  'Contactar al veterinario y vigilar a la coneja.',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cerrar')),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              Get.to(
                () => RabbitDetailScreen(rabbit: rabbit),
                transition: Transition.rightToLeft,
                duration: const Duration(milliseconds: 300),
              );
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Ver coneja'),
          ),
        ],
      ),
    );
  }

  Widget _birthInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Text(
      'CONEJAS ACTIVAS',
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(letterSpacing: 0.8),
    );
  }

  Widget _buildActiveRabbits(BuildContext context) {
    return Obx(() {
      final list = dashboardController.activeRabbits;
      if (list.isEmpty) {
        return Container(
          padding: EdgeInsets.all(context.isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: const Center(
            child: Text('No hay conejas reproductoras activas'),
          ),
        );
      }

      return Column(
        children: list.asMap().entries.map((e) {
          return _buildRabbitCard(context, e.value, e.key);
        }).toList(),
      );
    });
  }

  Widget _buildRabbitCard(BuildContext context, Rabbit rabbit, int index) {
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
          onTap: () => Get.to(
            () => RabbitDetailScreen(rabbit: rabbit),
            transition: Transition.rightToLeft,
            duration: const Duration(milliseconds: 300),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.isMobile ? 16 : 24,
              vertical: 18,
            ),
            child: Row(
              children: [
                _RabbitAvatar(
                  initial: rabbit.displayId[0].toUpperCase(),
                  color: AppTheme.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rabbit.displayId,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      _StatusPill(
                        status: rabbit.isBreeder ? 'Reproductora' : 'Normal',
                      ),
                    ],
                  ),
                ),
                if (!context.isMobile)
                  Text(
                    '${rabbit.weightKg} kg',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppTheme.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (80 + 40 * index).ms);
  }

  // ── Orbe flotante (FAB) de CUNITECH Insight ────────────
  Widget _buildInsightFab(BuildContext context, bool isDesktop) {
    return Container(
      margin: EdgeInsets.only(
        right: isDesktop ? 10 : 2,
        bottom: isDesktop ? 10 : 2,
      ),
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.accent, Color(0xFF6B5339)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.45),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _showHolographicPanel(context),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFFFDF6EC),
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Panel holográfico (diálogo con efecto de vidrio) ───
  void _showHolographicPanel(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CUNITECH Insight',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, _, __) {
        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(
                            color: AppTheme.accentLight.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  color: AppTheme.accentLight,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'CUNITECH Insight',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Cerrar',
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: AppTheme.accentLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Flexible(
                              child: SingleChildScrollView(
                                child: FutureBuilder<InsightPanel>(
                                  future: _insightFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return _buildPanelLoading();
                                    }
                                    final panel =
                                        snapshot.data ?? InsightPanel.empty;
                                    if (panel.isEmpty) {
                                      return const Text(
                                        'No hay recomendaciones por ahora.',
                                        style: TextStyle(
                                          color: Color(0xFFE8DED0),
                                        ),
                                      );
                                    }
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (panel
                                            .diagnosticoGeneral
                                            .isNotEmpty) ...[
                                          _panelSectionLabel('DIAGNÓSTICO GENERAL'),
                                          const SizedBox(height: 8),
                                          _buildDiagnostico(
                                            panel.diagnosticoGeneral,
                                          ),
                                          const SizedBox(height: 18),
                                        ],
                                        _panelSectionLabel('RECOMENDACIONES'),
                                        const SizedBox(height: 4),
                                        for (final r in panel.recomendaciones)
                                          _buildPanelItem(context, r),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Widget _panelSectionLabel(String text) => Text(
    text,
    style: TextStyle(
      color: AppTheme.accentLight.withValues(alpha: 0.9),
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
    ),
  );

  Widget _buildPanelLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.accent,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Analizando tu criadero...',
              style: TextStyle(color: Color(0xFFE8DED0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnostico(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accentLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.accentLight.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.insights_rounded,
            color: AppTheme.accentLight,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelItem(BuildContext context, InsightRecomendacion r) {
    final color = _priorityColor(r.prioridad);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(_priorityIcon(r.prioridad), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _priorityLabel(r.prioridad),
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  r.detalle,
                  style: const TextStyle(
                    color: Color(0xFFE8DED0),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                if (r.impacto.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Impacto esperado: ${r.impacto}',
                    style: const TextStyle(
                      color: AppTheme.accentLight,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String prioridad) {
    switch (prioridad) {
      case 'alta':
        return const Color(0xFFD98C82);
      case 'baja':
        return const Color(0xFF9DCBA2);
      case 'media':
      default:
        return const Color(0xFFE0C27A);
    }
  }

  IconData _priorityIcon(String prioridad) {
    switch (prioridad) {
      case 'alta':
        return Icons.warning_amber_rounded;
      case 'baja':
        return Icons.check_circle_rounded;
      case 'media':
      default:
        return Icons.bolt_rounded;
    }
  }

  String _priorityLabel(String prioridad) {
    switch (prioridad) {
      case 'alta':
        return 'ALTA';
      case 'baja':
        return 'BAJA';
      case 'media':
      default:
        return 'MEDIA';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return months[month - 1];
  }
}

// ───────────────── WIDGETS AUXILIARES ─────────────────
class _MetricCard extends StatelessWidget {
  final String label, value, trend;
  final bool? positive;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.positive,
  });

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
      padding: EdgeInsets.all(context.isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: (context.isMobile
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.headlineMedium)
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: context.isMobile ? null : 32,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(trendIcon, size: 16, color: trendColor),
              const SizedBox(width: 6),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: trendColor,
                ),
              ),
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
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
    ),
    alignment: Alignment.center,
    child: Text(
      initial,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFD4A76A),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      status,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );
}
