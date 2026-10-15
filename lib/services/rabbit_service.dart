import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rabbit.dart';

class RabbitService {
  final _supabase = Supabase.instance.client;
  static const _tableName = 'conejo';
  static const _idColumn = 'id_conejo';

  String get _userId => _supabase.auth.currentUser!.id;

  /// id_conejo es int4 en la BD; en la app se maneja como String
  Object _id(String id) => int.tryParse(id) ?? id;

  Future<String?> uploadPhoto(XFile file) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = '$userId/$fileName';

      await _supabase.storage
          .from('rabbit-photos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      return _supabase.storage.from('rabbit-photos').getPublicUrl(path);
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }

  /// CONSULTAR: todos los conejos
  Future<List<Rabbit>> getAllRabbits() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', _userId)
          .order(_idColumn);
      return (response as List)
          .map((json) => Rabbit.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching rabbits: $e');
      rethrow;
    }
  }

  /// CONSULTAR: un conejo por ID
  Future<Rabbit?> getRabbitById(String id) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq(_idColumn, _id(id))
          .eq('user_id', _userId)
          .single();
      return Rabbit.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching rabbit: $e');
      return null;
    }
  }

  /// Conejas (hembras)
  Future<List<Rabbit>> getBreedersOnly() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('genero', 'Hembra')
          .eq('user_id', _userId);
      return (response as List)
          .map((json) => Rabbit.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching breeders: $e');
      rethrow;
    }
  }

  /// CREAR
  Future<Rabbit> createRabbit(Rabbit rabbit) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .insert(rabbit.toInsertJson())
          .select()
          .single();
      return Rabbit.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error creating rabbit: $e');
      rethrow;
    }
  }

  /// EDITAR
  Future<Rabbit> updateRabbit(String id, Rabbit rabbit) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .update(rabbit.toInsertJson())
          .eq(_idColumn, _id(id))
          .eq('user_id', _userId)
          .select()
          .single();
      return Rabbit.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error updating rabbit: $e');
      rethrow;
    }
  }

  /// ELIMINAR
  Future<void> deleteRabbit(String id) async {
    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq(_idColumn, _id(id))
          .eq('user_id', _userId);
    } catch (e) {
      print('Error deleting rabbit: $e');
      rethrow;
    }
  }

  /// Estadísticas generales
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final allRabbits = await getAllRabbits();
      final totalRabbits = allRabbits.length;
      final totalBreeders = allRabbits.where((r) => r.isBreeder).length;
      final healthyCount = allRabbits
          .where((r) => r.healthStatus == 'Saludable')
          .length;
      final sickCount = allRabbits
          .where((r) => r.healthStatus.contains('Tratamiento'))
          .length;

      return {
        'total_rabbits': totalRabbits,
        'breeders': totalBreeders,
        'healthy': healthyCount,
        'sick': sickCount,
        'survival_rate': totalRabbits > 0
            ? ((healthyCount / totalRabbits) * 100).toStringAsFixed(1)
            : '0',
      };
    } catch (e) {
      print('Error getting statistics: $e');
      rethrow;
    }
  }
}
