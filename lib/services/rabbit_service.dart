import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rabbit.dart';

class RabbitService {
  final _supabase = Supabase.instance.client;
  static const _tableName = 'conejo';
  static const _idColumn = 'id_conejo';

  /// id_conejo es int4 en la BD; en la app se maneja como String
  Object _id(String id) => int.tryParse(id) ?? id;

  /// CONSULTAR: todos los conejos
  Future<List<Rabbit>> getAllRabbits() async {
    try {
      final response =
          await _supabase.from(_tableName).select().order(_idColumn);
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
      final response =
          await _supabase.from(_tableName).select().eq('genero', 'Hembra');
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
          .insert(rabbit.toJson())
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
          .update(rabbit.toJson())
          .eq(_idColumn, _id(id))
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
      await _supabase.from(_tableName).delete().eq(_idColumn, _id(id));
    } catch (e) {
      print('Error deleting rabbit: $e');
      rethrow;
    }
  }

  // Estas columnas no existen en la tabla conejo (no usar en la presentación)
  Future<void> updateLastFeeding(String rabbitId) async {}
  Future<void> updateLastTreatment(String rabbitId) async {}
  Future<void> updateExpectedBirthDate(
      String rabbitId, DateTime expectedDate) async {}
  Future<void> incrementLitterCount(String rabbitId) async {}

  /// Estadísticas generales
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final allRabbits = await getAllRabbits();
      final totalRabbits = allRabbits.length;
      final totalBreeders = allRabbits.where((r) => r.isBreeder).length;
      final healthyCount =
          allRabbits.where((r) => r.healthStatus == 'Saludable').length;
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