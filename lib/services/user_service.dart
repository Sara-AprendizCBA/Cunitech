import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/logger.dart';
import '../models/user_profile.dart';

class UserService {
  final supabase = Supabase.instance.client;

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
  /// auth.users, inserta la fila en `usuario` y envía un correo al correo
  /// personal con el enlace para crear la contraseña. La función valida que
  /// el solicitante tenga rol `admin`.
  Future<bool> createUser({
    required String personalEmail,
    required String laboralEmail,
    required String nombre,
    required String rol,
  }) async {
    try {
      final response = await supabase.functions.invoke(
        'create-user',
        body: {
          'personalEmail': personalEmail,
          'laboralEmail': laboralEmail,
          'nombre': nombre,
          'rol': rol,
        },
      );
      return response.status == 200;
    } catch (e) {
      logger.e('Error createUser', error: e);
      return false;
    }
  }
}
