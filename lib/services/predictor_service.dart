// lib/services/predictor_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/logger.dart';

/// Resultado de una estimación biológica: fecha probable y su rango (±1 día).
class PrediccionFecha {
  final DateTime fecha;
  final DateTime rangoInicio;
  final DateTime rangoFin;
  final int diasUsados;
  final bool basadoEnHistorial;

  const PrediccionFecha({
    required this.fecha,
    required this.rangoInicio,
    required this.rangoFin,
    required this.diasUsados,
    required this.basadoEnHistorial,
  });

  /// ¿Hoy cae dentro del rango estimado?
  bool get esHoy =>
      !DateTime.now().isBefore(rangoInicio) &&
      !DateTime.now().isAfter(rangoFin);
}

/// Servicio de IA predictiva: estima fechas biológicas a partir del historial
/// real de partos de la base de datos.
class PredictorService {
  final _supabase = Supabase.instance.client;

  /// Días de gestación estándar en conejas cuando no hay historial.
  static const int diasGestacionEstandar = 31;

  /// Rango óptimo de palpación (día 11 a 14 tras la monta).
  static const int palpacionDiaMin = 11;
  static const int palpacionDiaMax = 14;

  /// Días hasta el destete tras el parto.
  static const int diasDestete = 35;

  /// Formato 'yyyy-MM-dd' para comparar con columnas tipo date.
  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Estima el parto de una coneja usando el promedio de gestación de sus
  /// últimos 3 partos (por `mother_id`). Si no hay historial usa 31 días.
  Future<PrediccionFecha> estimarParto(
    String conejaId, {
    DateTime? fechaMonta,
  }) async {
    final monta = fechaMonta ?? DateTime.now();
    final dias = await _promedioGestacion(conejaId);
    final fecha = monta.add(Duration(days: dias));
    return PrediccionFecha(
      fecha: fecha,
      rangoInicio: fecha.subtract(const Duration(days: 1)),
      rangoFin: fecha.add(const Duration(days: 1)),
      diasUsados: dias,
      basadoEnHistorial: dias != diasGestacionEstandar,
    );
  }

  /// Calcula el promedio de días de gestación de los últimos 3 partos.
  /// Cruza `births` (mother_id / birth_date) con la monta previa más cercana
  /// de esa coneja. Devuelve el estándar si no hay datos suficientes.
  Future<int> _promedioGestacion(String conejaId) async {
    final id = int.tryParse(conejaId);
    if (id == null) return diasGestacionEstandar;

    try {
      final partos = await _supabase
          .from('births')
          .select('birth_date')
          .eq('mother_id', id)
          .order('birth_date', ascending: false)
          .limit(3);

      final fechasParto = (partos as List)
          .map((row) {
            final raw = row['birth_date'];
            return raw == null ? null : DateTime.tryParse(raw.toString());
          })
          .whereType<DateTime>()
          .toList();

      if (fechasParto.isEmpty) return diasGestacionEstandar;

      final dias = <int>[];
      for (final parto in fechasParto) {
        final monta = await _montaPrevia(id, parto);
        if (monta != null) {
          final gestacion = parto.difference(monta).inDays;
          if (gestacion >= 25 && gestacion <= 40) dias.add(gestacion);
        }
      }

      if (dias.isEmpty) return diasGestacionEstandar;
      return (dias.reduce((a, b) => a + b) / dias.length).round();
    } catch (e) {
      logger.e('Error calculando gestación promedio', error: e);
      return diasGestacionEstandar;
    }
  }

  /// Busca la fecha de monta previa más cercana a un parto dado (misma coneja).
  Future<DateTime?> _montaPrevia(int conejaId, DateTime parto) async {
    try {
      final rows = await _supabase
          .from('reproduccion')
          .select('fecha_monta')
          .eq('id_coneja', conejaId)
          .lte('fecha_monta', _dateOnly(parto))
          .order('fecha_monta', ascending: false)
          .limit(1);
      final lista = rows as List;
      if (lista.isEmpty) return null;
      final raw = lista.first['fecha_monta'];
      return raw == null ? null : DateTime.tryParse(raw.toString());
    } catch (e) {
      return null;
    }
  }

  /// Rango óptimo de palpación para una monta (día 11 a 14 tras la monta).
  PrediccionFecha estimarPalpacion(DateTime fechaMonta) {
    final inicio = fechaMonta.add(const Duration(days: palpacionDiaMin));
    final fin = fechaMonta.add(const Duration(days: palpacionDiaMax));
    return PrediccionFecha(
      fecha: inicio,
      rangoInicio: inicio,
      rangoFin: fin,
      diasUsados: palpacionDiaMin,
      basadoEnHistorial: false,
    );
  }

  /// Fecha de destete estimada (parto + 35 días).
  PrediccionFecha estimarDestete(DateTime fechaParto) {
    final fecha = fechaParto.add(const Duration(days: diasDestete));
    return PrediccionFecha(
      fecha: fecha,
      rangoInicio: fecha.subtract(const Duration(days: 1)),
      rangoFin: fecha.add(const Duration(days: 1)),
      diasUsados: diasDestete,
      basadoEnHistorial: false,
    );
  }

  /// Formatea una fecha como "15 Nov" (capitaliza el mes).
  static String formatearCorta(DateTime fecha) {
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${fecha.day} ${meses[fecha.month - 1]}';
  }
}
