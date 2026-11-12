import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/responsive.dart';
import '../../models/peso_registro.dart';
import '../../models/rabbit.dart';
import '../../services/peso_service.dart';

/// Sección "Historial de peso" del detalle de un conejo.
///
/// Muestra la curva de peso con los pesajes registrados y permite añadir
/// pesajes nuevos. Si no hay historial, avisa de cómo empezar a generarlo.
class RabbitWeightHistorySection extends StatefulWidget {
  final Rabbit rabbit;

  /// Servicio de pesajes. Se puede inyectar uno propio (pruebas).
  final PesoService? service;

  const RabbitWeightHistorySection({
    super.key,
    required this.rabbit,
    this.service,
  });

  @override
  State<RabbitWeightHistorySection> createState() =>
      _RabbitWeightHistorySectionState();
}

class _RabbitWeightHistorySectionState extends State<RabbitWeightHistorySection> {
  late Future<List<PesoRegistro>> _historial;
  bool _registrando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  PesoService get _servicio => widget.service ?? PesoService();

  void _cargar() {
    _historial = _servicio.getHistorial(widget.rabbit.id);
  }

  Future<void> _registrarPeso() async {
    final datos = await showDialog<({double peso, DateTime fecha, String? notas})>(
      context: context,
      builder: (_) => _PesoDialog(pesoActual: widget.rabbit.weightKg),
    );
    if (datos == null || !mounted) return;

    setState(() => _registrando = true);
    final ok = await _servicio.registrar(
      conejoId: widget.rabbit.id,
      fecha: datos.fecha,
      pesoKg: datos.peso,
      notas: datos.notas,
    );
    if (!mounted) return;
    setState(() {
      _registrando = false;
      if (ok) _cargar();
    });

    if (ok) {
      AppSnackbar.success(context, 'Peso registrado');
    } else {
      AppSnackbar.error(
        context,
        'No se pudo guardar el peso (¿aplicaste la migración 020?)',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compacto = context.isMobile;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Padding(
        padding: EdgeInsets.all(compacto ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_weight_outlined,
                    size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'HISTORIAL DE PESO',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _registrando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton.icon(
                        onPressed: _registrarPeso,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(compacto ? 'Pesaje' : 'Registrar peso'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppTheme.accent,
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<PesoRegistro>>(
              future: _historial,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final registros = snapshot.data ?? const <PesoRegistro>[];
                if (registros.length < 2) {
                  return _buildSinHistorial(registros);
                }

                return _buildGrafico(context, registros, compacto);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Estado inicial: aun no hay curva que dibujar.
  Widget _buildSinHistorial(List<PesoRegistro> registros) {
    final actual = registros.isNotEmpty
        ? registros.last.pesoKg
        : widget.rabbit.weightKg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Column(
            children: [
              Icon(Icons.show_chart_rounded,
                  size: 28, color: AppTheme.textTertiary),
              const SizedBox(height: 8),
              Text(
                actual > 0
                    ? 'Peso actual: ${actual.toStringAsFixed(2)} kg'
                    : 'Sin peso registrado',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Registra al menos dos pesajes para ver la curva de evolución.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGrafico(
    BuildContext context,
    List<PesoRegistro> registros,
    bool compacto,
  ) {
    final spots = <FlSpot>[
      for (var i = 0; i < registros.length; i++)
        FlSpot(i.toDouble(), registros[i].pesoKg),
    ];

    final pesos = registros.map((r) => r.pesoKg).toList();
    final minPeso = pesos.reduce(math.min);
    final maxPeso = pesos.reduce(math.max);
    // Margen del eje Y para que la curva no toque los bordes.
    final margen = math.max(0.15, (maxPeso - minPeso) * 0.3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: compacto ? 160 : 200,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (spots.length - 1).toDouble(),
              minY: math.max(0, minPeso - margen),
              maxY: maxPeso + margen,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: AppTheme.borderLight, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ),
                ),
                // Solo se etiquetan la primera y la ultima fecha.
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final indice = value.toInt();
                      if (indice < 0 || indice >= registros.length) {
                        return const SizedBox.shrink();
                      }
                      if (indice != 0 && indice != registros.length - 1) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat('dd/MM').format(registros[indice].fecha),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppTheme.accent,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2.5,
                      strokeColor: AppTheme.accent,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.accent.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Flexible + ellipsis: con fuente grande los tres textos se recortan
        // en vez de desbordar la tarjeta.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Mín ${minPeso.toStringAsFixed(2)} kg',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
            Flexible(
              child: Text(
                '${registros.length} pesajes',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
            Flexible(
              child: Text(
                'Máx ${maxPeso.toStringAsFixed(2)} kg',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Diálogo para registrar un pesaje.
class _PesoDialog extends StatefulWidget {
  final double pesoActual;

  const _PesoDialog({required this.pesoActual});

  @override
  State<_PesoDialog> createState() => _PesoDialogState();
}

class _PesoDialogState extends State<_PesoDialog> {
  late final TextEditingController _pesoController;
  late DateTime _fecha;
  final TextEditingController _notasController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _pesoController = TextEditingController(
      text: widget.pesoActual > 0 ? widget.pesoActual.toStringAsFixed(2) : '',
    );
    _fecha = DateTime.now();
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  void _guardar() {
    final peso = double.tryParse(_pesoController.text.trim().replaceAll(',', '.'));
    if (peso == null || peso <= 0) {
      setState(() => _error = 'Ingresa un peso válido');
      return;
    }
    Navigator.of(context).pop((
      peso: peso,
      fecha: _fecha,
      notas: _notasController.text.trim().isEmpty
          ? null
          : _notasController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar peso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pesoController,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso (kg)',
              suffixText: 'kg',
              prefixIcon: Icon(Icons.monitor_weight_outlined),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fecha del pesaje'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(_fecha)),
            trailing: const Icon(Icons.calendar_today_rounded),
            onTap: _elegirFecha,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notasController,
            decoration: const InputDecoration(
              labelText: 'Notas (opcional)',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
