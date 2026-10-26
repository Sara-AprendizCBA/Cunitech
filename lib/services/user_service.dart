import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/logger.dart';
import '../models/user_profile.dart';

class UserService {
  final supabase = Supabase.instance.client;

  String? _lastError;
  String? get lastError => _lastError;

  /// Lista todos los usuarios (la RLS deja al admin ver todos).
  Future<List<UserProfile>> getAll() async {
    try {
      final data = await supabase
          .from('usuario')
          .select('id_usuario, nombre, email, rol, activo, created_by')
          .order('rol', ascending: true)
          .order('nombre', ascending: true);
      return (data as List)
          .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.e('Error getAll usuarios', error: e);
      return [];
    }
  }

  /// Actualiza el rol de un usuario (admin por RLS).
  Future<bool> updateRol(String idUsuario, String nuevoRol) async {
    try {
      await supabase
          .from('usuario')
          .update({'rol': nuevoRol})
          .eq('id_usuario', idUsuario);
      return true;
    } catch (e) {
      logger.e('Error updateRol', error: e);
      return false;
    }
  }

  /// Activa o desactiva un usuario (admin por RLS).
  Future<bool> updateActivo(String idUsuario, bool activo) async {
    try {
      await supabase
          .from('usuario')
          .update({'activo': activo})
          .eq('id_usuario', idUsuario);
      return true;
    } catch (e) {
      logger.e('Error updateActivo', error: e);
      return false;
    }
  }

  /// Elimina un usuario (solo admin por policy DELETE).
  Future<bool> deleteUser(String idUsuario) async {
    try {
      await supabase.from('usuario').delete().eq('id_usuario', idUsuario);
      return true;
    } catch (e) {
      logger.e('Error deleteUser', error: e);
      return false;
    }
  }

  /// Crea un usuario nuevo.
  ///
  /// Invoca la Edge Function `create-user`, que crea el registro en
  /// auth.users, inserta la fila en `usuario` y devuelve el `id_usuario`.
  /// La contraseña la define el admin. La función valida que el solicitante
  /// tenga rol `admin`.
  ///
  /// Devuelve el `id_usuario` o `null` si falló. El mensaje real del error
  /// queda disponible en [lastError].
  Future<String?> createUser({
    required String email,
    required String password,
    required String nombre,
    required String rol,
  }) async {
    _lastError = null;
    try {
      final response = await supabase.functions.invoke(
        'create-user',
        body: {
          'email': email,
          'password': password,
          'nombre': nombre,
          'rol': rol,
        },
      );
      final data = response.data;
      if (response.status == 200 &&
          data is Map &&
          data['id_usuario'] is String) {
        return data['id_usuario'] as String;
      }
      _lastError = _extractError(data, response.status);
      return null;
    } on FunctionException catch (e) {
      _lastError = _extractError(e.details, e.status);
      return null;
    } catch (e) {
      logger.e('Error createUser', error: e);
      _lastError = 'No se pudo conectar con el servidor.';
      return null;
    }
  }

  String _extractError(dynamic data, int status) {
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }
    if (status == 0) {
      return 'No se pudo conectar con el servidor.';
    }
    return 'No se pudo crear el usuario (código $status).';
  }
}
