import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rabbit.dart';

class RabbitService {
  final _supabase = Supabase.instance.client;
  static const _tableName = 'rabbits';

  /// Obtener todos los conejos
  Future<List<Rabbit>> getAllRabbits() async {
    try {
      final response = await _supabase.from(_tableName).select();
      return (response as List)
          .map((json) => Rabbit.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching rabbits: $e');
      rethrow;
    }
  }

  /// Obtener un conejo por ID
  Future<Rabbit?> getRabbitById(String id) async {
    try {
      final response =
          await _supabase.from(_tableName).select().eq('id', id).single();
      return Rabbit.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching rabbit: $e');
      return null;
    }
  }

  /// Obtener conejas reproductoras
  Future<List<Rabbit>> getBreedersOnly() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('is_breeder', true)
          .eq('gender', 'Hembra');
      return (response as List)
          .map((json) => Rabbit.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching breeders: $e');
      rethrow;
    }
  }

  /// Crear un nuevo conejo
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

  /// Actualizar conejo
  Future<Rabbit> updateRabbit(String id, Rabbit rabbit) async {
    try {
      final data = rabbit.toJson();
      data.remove('id');
      final response = await _supabase
          .from(_tableName)
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Rabbit.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error updating rabbit: $e');
      rethrow;
    }
  }

  /// Eliminar conejo
  Future<void> deleteRabbit(String id) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', id);
    } catch (e) {
      print('Error deleting rabbit: $e');
      rethrow;
    }
  }

  /// Actualizar último registro de alimentación
  Future<void> updateLastFeeding(String rabbbitId) async {
    try {
      await _supabase
          .from(_tableName)
          .update({'last_feeding_date': DateTime.now().toIso8601String()})
          .eq('id', rabbbitId);
    } catch (e) {
      print('Error updating feeding: $e');
      rethrow;
    }
  }

  /// Actualizar última fecha de tratamiento
  Future<void> updateLastTreatment(String rabbbitId) async {
    try {
      await _supabase
          .from(_tableName)
          .update({'last_treatment_date': DateTime.now().toIso8601String()})
          .eq('id', rabbbitId);
    } catch (e) {
      print('Error updating treatment: $e');
      rethrow;
    }
  }

  /// Actualizar fecha de parto esperada
  Future<void> updateExpectedBirthDate(
      String rabbbitId, DateTime expectedDate) async {
    try {
      await _supabase
          .from(_tableName)
          .update({'expected_birth_date': expectedDate.toIso8601String()})
          .eq('id', rabbbitId);
    } catch (e) {
      print('Error updating expected birth date: $e');
      rethrow;
    }
  }

  /// Incrementar contador de partos
  Future<void> incrementLitterCount(String rabbbitId) async {
    try {
      final rabbit = await getRabbitById(rabbbitId);
      if (rabbit != null) {
        await updateRabbit(
            rabbbitId, rabbit.copyWith(litterCount: rabbit.litterCount + 1));
      }
    } catch (e) {
      print('Error incrementing litter count: $e');
      rethrow;
    }
  }

  /// Obtener estadísticas generales
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
        'survival_rate': totalRabbits > 0 ? ((healthyCount / totalRabbits) * 100).toStringAsFixed(1) : '0',
      };
    } catch (e) {
      print('Error getting statistics: $e');
      rethrow;
    }
  }
}