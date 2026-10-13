import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import '../../controllers/reportes_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/meta_mensual.dart';
import '../../services/pdf_service.dart';

String _getMonthName(int month) => const [
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
    ][month - 1];

class _ReportActivity {
  final DateTime? fecha;
  final IconData icono;
  final Color color;
  final String titulo;
  final String subtitulo;

  const _ReportActivity({
    required this.fecha,
    required this.icono,
    required this.color,
    required this.titulo,
    required this.subtitulo,
  });
}

String _tiempoRelativo(DateTime fecha) {
  final diff = DateTime.now().difference(fecha);
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays < 30) return 'hace ${diff.inDays} días';
  if (diff.inDays < 365) return 'hace ${(diff.inDays / 30).floor()} meses';
  return 'hace ${(diff.inDays / 365).floor()} años';
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  static final reportesController = Get.put(ReportesController());

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _exportando = false;

  ReportesController get reportesController =>
      ReportsScreen.reportesController;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      color: AppTheme.bgLight,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 40),

            // Main Chart
            _buildPopulationChart(context),
            const SizedBox(height: 40),

            // Summary Cards
            Text(
              'Resumen General',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Obx(() => _buildSummaryGrid(context)),

            const SizedBox(height: 48),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _buildMetasSection(context),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 5,
                        child: _buildRecentActivity(context),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildMetasSection(context),
                    const SizedBox(height: 24),
                    _buildRecentActivity(context),
                  ],
                );
              },
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reportes y Estadísticas',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Cunicultura CBA · '
              '${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
        if (!isMobile)
          ElevatedButton.icon(
            onPressed:
                _exportando ? null : () => _exportarReporte(context),
            icon: _exportando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded),
            label: Text(
              _exportando ? 'Generando…' : 'Exportar Reporte',
            ),
          ),
      ],
    );
  }

  Future<void> _exportarReporte(BuildContext context) async {
    if (_exportando) return;
    setState(() => _exportando = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      await reportesController.loadAll();

      await PdfService().exportarReporte(
        controller: reportesController,
        nombreCriadero: 'Cunicultura CBA',
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Reporte descargado')),
      );
    } catch (e) {
      debugPrint('Error exportar reporte: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Widget _buildPopulationChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Crecimiento de Población",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Text(
                "Últimos 30 días",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 320,
            child: Obx(() {
              final data = reportesController.poblacionPorDia.toList();
              final spots = <FlSpot>[];
              for (var i = 0; i < data.length; i++) {
                spots.add(
                  FlSpot(
                    i.toDouble(),
                    (data[i]['total'] as int).toDouble(),
                  ),
                );
              }

              if (spots.isEmpty || spots.every((spot) => spot.y == 0)) {
                return Container(
                  height: 280,
                  alignment: Alignment.center,
                  child: const Text(
                    'Sin datos para mostrar.\n'
                    'Registra conejos y partos para ver el crecimiento.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }

              final valores = spots.map((spot) => spot.y).toList();
              final maxValor = valores.reduce(math.max);
              final minY = 0.0;
              final maxY = math.max(10.0, maxValor * 1.1).toDouble();

              return LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (spots.length - 1).toDouble(),
                  minY: minY,
                  maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.borderLight,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final dia = DateTime.parse(data[index]['dia'] as String);
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${dia.day}/${dia.month}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: AppTheme.accent,
                    barWidth: 4,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 5,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: AppTheme.accent,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.accent.withValues(alpha: 0.08),
                    ),
                  ),
                ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final cards = [
      _buildReportSummary(
        context,
        'Mortalidad',
        reportesController.mortalidadTexto,
        Icons.trending_down_rounded,
        AppTheme.success,
        reportesController.mortalidadSubtitulo,
      ),
      _buildReportSummary(
        context,
        'Peso Promedio',
        reportesController.pesoPromedioTexto,
        Icons.scale_rounded,
        AppTheme.accent,
        reportesController.pesoPromedioSubtitulo,
      ),
      _buildReportSummary(
        context,
        'Conejas en Ciclo',
        reportesController.tasaGestacionTexto,
        Icons.favorite_rounded,
        const Color(0xFF9E7C5E),
        reportesController.tasaGestacionSubtitulo,
      ),
    ];

    return isMobile
        ? Column(children: [for (final card in cards) ...[card, const SizedBox(height: 12)]])
        : Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 24),
        Expanded(
          child: cards[1],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: cards[2],
        ),
      ],
    );
  }

  Widget _buildReportSummary(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String trend,
  ) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 24),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            trend,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetasSection(BuildContext context) {
    return Obx(() {
      final metas = reportesController.metasMes.toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Metas del Mes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (metas.isNotEmpty)
                IconButton(
                  tooltip: 'Agregar meta',
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _MetaFormDialog(
                      controller: reportesController,
                    ),
                  ),
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (metas.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                children: [
                  const Text(
                    'Aún no has configurado metas para este mes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => _MetaFormDialog(
                        controller: reportesController,
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Agregar meta'),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth;
                return Wrap(
                  runSpacing: 16,
                  children: [
                    for (final meta in metas)
                      SizedBox(
                        width: cardWidth,
                        child: _buildMetaCard(context, meta),
                      ),
                  ],
                );
              },
            ),
        ],
      );
    });
  }

  Widget _buildMetaCard(BuildContext context, MetaMensual meta) {
    final actual = reportesController.valoresActualesKpi[meta.kpi] ?? 0;
    final progreso = reportesController.progresoMeta(meta);
    final estado = reportesController.estadoMeta(meta);
    final colorEstado = switch (reportesController.colorEstadoMeta(meta)) {
      'success' => AppTheme.success,
      'warning' => AppTheme.warning,
      _ => AppTheme.danger,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  meta.kpiLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colorEstado.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Text(
                  estado,
                  style: TextStyle(
                    color: colorEstado,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Opciones',
                onPressed: () => _mostrarOpcionesMeta(context, meta),
                icon: const Icon(
                  Icons.settings_rounded,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${actual.toStringAsFixed(1)} / '
            '${meta.valorObjetivo.toStringAsFixed(1)} ${meta.unidad}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (progreso / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppTheme.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(colorEstado),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarOpcionesMeta(
    BuildContext context,
    MetaMensual meta,
  ) async {
    final accion = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    meta.kpiLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.edit_rounded,
                color: AppTheme.accent,
              ),
              title: const Text('Editar meta'),
              onTap: () => Navigator.of(sheetContext).pop('editar'),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.danger,
              ),
              title: const Text(
                'Eliminar meta',
                style: TextStyle(color: AppTheme.danger),
              ),
              onTap: () => Navigator.of(sheetContext).pop('eliminar'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!context.mounted) return;

    if (accion == 'editar') {
      await showDialog<void>(
        context: context,
        builder: (_) => _MetaFormDialog(
          controller: reportesController,
          metaInicial: meta,
        ),
      );
    } else if (accion == 'eliminar') {
      await _confirmarEliminarMeta(context, meta);
    }
  }

  Future<void> _confirmarEliminarMeta(
    BuildContext context,
    MetaMensual meta,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar meta'),
        content: Text(
          '¿Eliminar la meta de ${meta.kpiLabel}? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final ok = await reportesController.eliminarMeta(meta.id!);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Meta eliminada' : 'Error al eliminar'),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Obx(() {
      final actividades = <_ReportActivity>[];

      for (final birth in reportesController.nacimientosRecientes) {
        actividades.add(
          _ReportActivity(
            fecha: DateTime.tryParse(birth['birth_date']?.toString() ?? ''),
            icono: Icons.child_care_rounded,
            color: AppTheme.success,
            titulo: 'Nacimiento registrado',
            subtitulo: '${birth['live_kits'] ?? 0} vivos · '
                '${birth['dead_kits'] ?? 0} muertos · '
                '${birth['chapeta_madre'] ?? 'Sin ID'}',
          ),
        );
      }

      for (final mating in reportesController.montasRecientes) {
        actividades.add(
          _ReportActivity(
            fecha: DateTime.tryParse(mating['fecha_monta']?.toString() ?? ''),
            icono: Icons.favorite_rounded,
            color: AppTheme.accent,
            titulo: 'Monta registrada',
            subtitulo: '${mating['chapeta_coneja'] ?? 'Sin ID'} · '
                '${mating['estado'] ?? ''}',
          ),
        );
      }

      for (final alert in reportesController.alertasSalud) {
        actividades.add(
          _ReportActivity(
            fecha: null,
            icono: Icons.warning_rounded,
            color: AppTheme.danger,
            titulo: 'Alerta de salud',
            subtitulo: '${alert['chapeta'] ?? 'Conejo'} · '
                '${alert['estado'] ?? ''}',
          ),
        );
      }

      actividades.sort((a, b) {
        if (a.fecha == null && b.fecha == null) return 0;
        if (a.fecha == null) return 1;
        if (b.fecha == null) return -1;
        return b.fecha!.compareTo(a.fecha!);
      });
      final recientes = actividades.take(4).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actividad Reciente',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: recientes.isEmpty
                ? const Text(
                    'Sin actividad reciente. Registra conejos, montas o partos.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < recientes.length; i++) ...[
                        _activityRow(
                          recientes[i].titulo,
                          recientes[i].subtitulo,
                          recientes[i].fecha == null
                              ? 'Estado actual'
                              : _tiempoRelativo(recientes[i].fecha!),
                          recientes[i].icono,
                          recientes[i].color,
                        ),
                        if (i < recientes.length - 1)
                          const Divider(height: 32),
                      ],
                    ],
                  ),
          ),
        ],
      );
    });
  }

  Widget _activityRow(
    String title,
    String subtitle,
    String time,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                subtitle,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          time,
          style: TextStyle(fontSize: 13, color: AppTheme.textTertiary),
        ),
      ],
    );
  }
}

class _MetaFormDialog extends StatefulWidget {
  final ReportesController controller;
  final MetaMensual? metaInicial;

  const _MetaFormDialog({
    required this.controller,
    this.metaInicial,
  });

  @override
  State<_MetaFormDialog> createState() => _MetaFormDialogState();
}

class _MetaFormDialogState extends State<_MetaFormDialog> {
  static const _kpis = [
    'prolificidad',
    'fertilidad',
    'supervivencia',
    'nacimientos',
  ];
  static const _prioridades = ['alta', 'media', 'baja'];

  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _notasController = TextEditingController();
  late String _kpi;
  late String _unidad;
  late String _prioridad;
  MetaMensual? _existing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final meta = widget.metaInicial;
    if (meta != null) {
      _kpi = meta.kpi;
      _existing = meta;
      _unidad = _unidadPara(meta.kpi);
      _valorController.text = meta.valorObjetivo.toString();
      _notasController.text = meta.notas ?? '';
      _prioridad = meta.prioridad;
      return;
    }

    final metasExistentes = widget.controller.metasMes.toList();
    final kpisConMeta = metasExistentes.map((meta) => meta.kpi).toSet();
    final primerKpiLibre = _kpis.firstWhere(
      (kpi) => !kpisConMeta.contains(kpi),
      orElse: () => _kpis.first,
    );
    final coincidencias = metasExistentes
        .where((meta) => meta.kpi == primerKpiLibre)
        .toList();
    _kpi = primerKpiLibre;
    _existing = coincidencias.isEmpty ? null : coincidencias.first;
    _unidad = _unidadPara(_kpi);
    _valorController.text = _existing?.valorObjetivo.toString() ?? '';
    _notasController.text = _existing?.notas ?? '';
    _prioridad = _existing?.prioridad ?? 'media';
  }

  String _unidadPara(String kpi) => switch (kpi) {
        'prolificidad' => 'gazapos',
        'fertilidad' || 'supervivencia' => '%',
        'nacimientos' => 'unidades',
        _ => 'unidades',
      };

  void _onKpiChanged(String? value) {
    if (value == null) return;
    final coincidencias = widget.controller.metasMes
        .where((meta) => meta.kpi == value)
        .toList();
    setState(() {
      _kpi = value;
      _existing = coincidencias.isEmpty ? null : coincidencias.first;
      _unidad = _unidadPara(value);
      _valorController.text = _existing?.valorObjetivo.toString() ?? '';
      _notasController.text = _existing?.notas ?? '';
      _prioridad = _existing?.prioridad ?? 'media';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ahora = DateTime.now();
    final meta = MetaMensual(
      id: _existing?.id,
      anio: ahora.year,
      mes: ahora.month,
      kpi: _kpi,
      valorObjetivo: double.parse(_valorController.text.trim()),
      unidad: _unidad,
      prioridad: _prioridad,
      notas: _notasController.text.trim().isEmpty
          ? null
          : _notasController.text.trim(),
    );

    final existingId = _existing?.id;
    final ok = existingId == null
        ? await widget.controller.crearMeta(meta)
        : await widget.controller.actualizarMeta(existingId, meta);
    if (ok) {
      navigator.pop();
      return;
    }

    if (mounted) setState(() => _saving = false);
    messenger.showSnackBar(
      const SnackBar(content: Text('Error al guardar la meta')),
    );
  }

  @override
  void dispose() {
    _valorController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 520;
    return AlertDialog(
      title: const Text('Configurar meta mensual'),
      content: SizedBox(
        width: isMobile ? double.maxFinite : 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _kpi,
                  decoration: const InputDecoration(
                    labelText: 'KPI',
                    prefixIcon: Icon(Icons.flag_rounded),
                  ),
                  items: [
                    for (final kpi in _kpis)
                      DropdownMenuItem(value: kpi, child: Text(_labelKpi(kpi))),
                  ],
                  onChanged: _saving ? null : _onKpiChanged,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _valorController,
                  decoration: InputDecoration(
                    labelText: 'Valor objetivo',
                    suffixText: _unidad,
                    prefixIcon: const Icon(Icons.track_changes_rounded),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Ingresa un valor mayor que cero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _prioridad,
                  decoration: const InputDecoration(
                    labelText: 'Prioridad',
                    prefixIcon: Icon(Icons.priority_high_rounded),
                  ),
                  items: [
                    for (final prioridad in _prioridades)
                      DropdownMenuItem(
                        value: prioridad,
                        child: Text(_capitalize(prioridad)),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _prioridad = value);
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notasController,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  maxLines: 3,
                  minLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_saving ? 'Guardando…' : 'Guardar'),
        ),
      ],
    );
  }

  static String _labelKpi(String kpi) => switch (kpi) {
        'prolificidad' => 'Prolificidad',
        'fertilidad' => 'Fertilidad',
        'supervivencia' => 'Supervivencia',
        'nacimientos' => 'Nacimientos',
        _ => kpi,
      };

  static String _capitalize(String value) =>
      '${value[0].toUpperCase()}${value.substring(1)}';
}
