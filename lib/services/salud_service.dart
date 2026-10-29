// lib/services/salud_service.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/auth_controller.dart';
import '../core/utils/logger.dart';
import '../models/tratamiento.dart';

/// Acceso a la tabla `tratamientos` (módulo Salud).
class SaludService {
  final _supabase = Supabase.instance.client;

  static const String _tableName = 'tratamientos';

  bool get _puedeGestionar {
    if (!Get.isRegistered<AuthController>()) return false;
    return Get.find<AuthController>().isVeterinario;
  }

  // Trae la fila + la chapeta del conejo vía la FK conejo_id -> conejo.id_conejo.
  static const String _select =
      'id, conejo_id, jaula_grupo, tipo, producto, dosis, via, '
      'fecha_aplicacion, fecha_proxima, notas, conejo(chapeta)';

  /// Formato 'yyyy-MM-dd' para columnas tipo date.
  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// CONSULTAR: todas las aplicaciones (más recientes primero).
  /// La RLS permite SELECT a cualquier usuario autenticado (admin/operario ven todo).
  Future<List<Tratamiento>> getAll() async {
    try {
      final data = await _supabase
          .from(_tableName)
          .select(_select)
          .order('fecha_aplicacion', ascending: false);
      return (data as List)
          .map((e) => Tratamiento.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.e('Error getAll tratamientos', error: e);
      return [];
    }
  }

  /// CREAR (solo veterinario por RLS).
  Future<bool> create(Tratamiento t) async {
    if (!_puedeGestionar) {
      logger.w('Intento de crear tratamiento sin rol veterinario');
      return false;
    }
    try {
      await _supabase.from(_tableName).insert(t.toJson());
      return true;
    } catch (e) {
      logger.e('Error create tratamiento', error: e);
      return false;
    }
  }

  /// EDITAR (solo veterinario por RLS).
  Future<bool> update(Tratamiento t) async {
    if (!_puedeGestionar) {
      logger.w('Intento de editar tratamiento sin rol veterinario');
      return false;
    }
    try {
      await _supabase.from(_tableName).update(t.toJson()).eq('id', t.id);
      return true;
    } catch (e) {
      logger.e('Error update tratamiento', error: e);
      return false;
    }
  }

  /// ELIMINAR (solo veterinario por RLS).
  Future<bool> delete(String id) async {
    if (!_puedeGestionar) {
      logger.w('Intento de eliminar tratamiento sin rol veterinario');
      return false;
    }
    try {
      await _supabase.from(_tableName).delete().eq('id', id);
      return true;
    } catch (e) {
      logger.e('Error delete tratamiento', error: e);
      return false;
    }
  }

  /// Aplicaciones cuya `fecha_proxima` cae dentro de los próximos 7 días.
  Future<List<Tratamiento>> getProximas() async {
    try {
      final hoy = DateTime.now();
      final desde = DateTime(hoy.year, hoy.month, hoy.day);
      final hasta = desde.add(const Duration(days: 7));
      final data = await _supabase
          .from(_tableName)
          .select(_select)
          .not('fecha_proxima', 'is', null)
          .gte('fecha_proxima', _dateOnly(desde))
          .lte('fecha_proxima', _dateOnly(hasta))
          .order('fecha_proxima', ascending: true);
      return (data as List)
          .map((e) => Tratamiento.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.e('Error getProximas tratamientos', error: e);
      return [];
    }
  }
}
