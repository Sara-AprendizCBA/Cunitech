import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/logger.dart';
import '../models/peso_registro.dart';

/// Acceso a la tabla `pesajes` (historial de peso por conejo).
///
/// Si la tabla aun no existe (falta aplicar la migracion 020) el historial se
/// devuelve vacio en vez de romper la pantalla.
class PesoService {
  final _supabase = Supabase.instance.client;

  static const String _tabla = 'pesajes';
  static const String _select =
      'id, conejo_id, fecha, peso_kg, notas, created_at';

  /// Historial de pesajes de un conejo, del mas antiguo al mas reciente.
  Future<List<PesoRegistro>> getHistorial(String conejoId) async {
    final id = int.tryParse(conejoId);
    if (id == null) return [];

    try {
      final data = await _supabase
          .from(_tabla)
          .select(_select)
          .eq('conejo_id', id)
          .order('fecha', ascending: true);
      return (data as List)
          .map((e) => PesoRegistro.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.w('No se pudo leer el historial de pesos', error: e);
      return [];
    }
  }

  /// Registra un pesaje. Devuelve `true` si se guardo.
  Future<bool> registrar({
    required String conejoId,
    required DateTime fecha,
    required double pesoKg,
    String? notas,
  }) async {
    final id = int.tryParse(conejoId);
    if (id == null || pesoKg <= 0) return false;

    try {
      await _supabase.from(_tabla).insert({
        'conejo_id': id,
        'fecha': fecha.toIso8601String().split('T').first,
        'peso_kg': pesoKg,
        'notas': notas,
      });
      return true;
    } catch (e) {
      logger.e('Error registrando el peso', error: e);
      return false;
    }
  }
}
