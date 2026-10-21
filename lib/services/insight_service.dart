// lib/services/insight_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/logger.dart';
import '../models/insight_recomendacion.dart';

/// Recolecta métricas reales del criadero y pide recomendaciones a la Edge
/// Function `generate-insights` (Gemini). Ante cualquier error devuelve una
/// lista vacía para que la UI no se rompa.
class InsightService {
  final _supabase = Supabase.instance.client;

  /// Formato 'yyyy-MM-dd' para columnas tipo date.
  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Devuelve el panel de IA (diagnóstico + recomendaciones) del criadero.
  Future<InsightPanel> obtenerRecomendaciones() async {
    try {
      final contexto = await _construirContexto();
      final response = await _supabase.functions.invoke(
        'generate-insights',
        body: {'contexto': contexto},
      );

      if (response.status < 200 || response.status >= 300) {
        logger.e('generate-insights respondió ${response.status}');
        return InsightPanel.empty;
      }

      final data = response.data;
      if (data is! Map) return InsightPanel.empty;
      return InsightPanel.fromJson(data.cast<String, dynamic>());
    } catch (e) {
      logger.e('Error obtenerRecomendaciones', error: e);
      return InsightPanel.empty;
    }
  }

  /// Recolecta las métricas del criadero. Cada consulta es tolerante a fallos:
  /// si una tabla/columna no existe, el valor queda en 0.
  Future<Map<String, dynamic>> _construirContexto() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return {};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hace30 = today.subtract(const Duration(days: 30));
    final en7 = today.add(const Duration(days: 7));

    final totalConejos = await _contar(
      _supabase.from('conejo').select('id_conejo').eq('user_id', userId),
    );
    final conejasActivas = await _contar(
      _supabase
          .from('conejo')
          .select('id_conejo')
          .eq('user_id', userId)
          .eq('genero', 'Hembra')
          .inFilter('reproductive_status', [
            'Vacía',
            'Servida',
            'Gestante',
            'Lactante',
          ])
          .neq('estado', 'Vendida'),
    );
    final machos = await _contar(
      _supabase
          .from('conejo')
          .select('id_conejo')
          .eq('user_id', userId)
          .eq('genero', 'Macho'),
    );
    final enTratamiento = await _contar(
      _supabase
          .from('conejo')
          .select('id_conejo')
          .eq('user_id', userId)
          .ilike('estado', '%Tratamiento%'),
    );
    final partos30Dias = await _contar(
      _supabase
          .from('births')
          .select('id')
          .gte('birth_date', _dateOnly(hace30)),
    );
    final criasVivas = await _sumarCriasVivas();
    final proximosPartos = await _contar(
      _supabase
          .from('conejo')
          .select('id_conejo')
          .eq('user_id', userId)
          .eq('reproductive_status', 'Gestante')
          .gte('expected_birth_date', _dateOnly(today))
          .lte('expected_birth_date', _dateOnly(en7)),
    );
    final tratamientosProximos = await _contar(
      _supabase
          .from('tratamientos')
          .select('id')
          .gte('fecha_proxima', _dateOnly(today))
          .lte('fecha_proxima', _dateOnly(en7)),
    );

    return {
      'fecha': _dateOnly(today),
      'total_conejos': totalConejos,
      'conejas_activas': conejasActivas,
      'machos': machos,
      'conejos_en_tratamiento': enTratamiento,
      'partos_ultimos_30_dias': partos30Dias,
      'crias_vivas_total': criasVivas,
      'proximos_partos_7_dias': proximosPartos,
      'tratamientos_proximos_7_dias': tratamientosProximos,
    };
  }

  /// Cuenta las filas de una consulta; 0 si falla.
  Future<int> _contar(Future<dynamic> query) async {
    try {
      final rows = await query;
      return rows is List ? rows.length : 0;
    } catch (e) {
      return 0;
    }
  }

  /// Suma `live_kits` de los partos recientes (últimos 100); 0 si falla.
  Future<int> _sumarCriasVivas() async {
    try {
      final rows = await _supabase
          .from('births')
          .select('live_kits')
          .order('birth_date', ascending: false)
          .limit(100);
      return rows.fold<int>(
        0,
        (sum, r) => sum + ((r['live_kits'] as num?)?.toInt() ?? 0),
      );
    } catch (e) {
      return 0;
    }
  }
}
