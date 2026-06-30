import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/birth.dart';

class BirthService {
  final _supabase = Supabase.instance.client;
  static const _tableName = 'births';

  /// Obtener todos los partos
  Future<List<Birth>> getAllBirths() async {
    try {
      final response = await _supabase.from(_tableName).select();
      return (response as List)
          .map((json) => Birth.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching births: $e');
      rethrow;
    }
  }

  /// Obtener partos por madre
  Future<List<Birth>> getBirthsByMother(String motherId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('mother_id', motherId)
          .order('birth_date', ascending: false);
      return (response as List)
          .map((json) => Birth.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching births by mother: $e');
      rethrow;
    }
  }

  /// Obtener un parto por ID
  Future<Birth?> getBirthById(String id) async {
    try {
      final response =
          await _supabase.from(_tableName).select().eq('id', id).single();
      return Birth.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching birth: $e');
      return null;
    }
  }

  /// Crear un nuevo parto
  Future<Birth> createBirth(Birth birth) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .insert(birth.toJson())
          .select()
          .single();
      return Birth.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error creating birth: $e');
      rethrow;
    }
  }

  /// Actualizar parto
  Future<Birth> updateBirth(String id, Birth birth) async {
    try {
      final data = birth.toJson();
      data.remove('id');
      final response = await _supabase
          .from(_tableName)
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Birth.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error updating birth: $e');
      rethrow;
    }
  }

  /// Eliminar parto
  Future<void> deleteBirth(String id) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', id);
    } catch (e) {
      print('Error deleting birth: $e');
      rethrow;
    }
  }

  /// Obtener partos recientes (últimos 30 días)
  Future<List<Birth>> getRecentBirths({int days = 30}) async {
    try {
      final since =
          DateTime.now().subtract(Duration(days: days)).toIso8601String();
      final response = await _supabase
          .from(_tableName)
          .select()
          .gte('birth_date', since)
          .order('birth_date', ascending: false);
      return (response as List)
          .map((json) => Birth.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching recent births: $e');
      rethrow;
    }
  }

  /// Obtener próximos partos esperados
  Future<List<Birth>> getUpcomingBirths({int days = 30}) async {
    try {
      // Esto requeriría una tabla de matings con expected_birth_date
      // Por ahora retornamos una lista vacía
      return [];
    } catch (e) {
      print('Error fetching upcoming births: $e');
      rethrow;
    }
  }

  /// Obtener estadísticas de reproducción
  Future<Map<String, dynamic>> getReproductionStats() async {
    try {
      final allBirths = await getAllBirths();
      
      final totalBirths = allBirths.length;
      final totalKits = allBirths.fold<int>(0, (sum, b) => sum + b.liveKits);
      final deadKits = allBirths.fold<int>(0, (sum, b) => sum + b.deadKits);
      final avgSurvivalRate = allBirths.isNotEmpty
          ? (allBirths.fold<int>(0, (sum, b) => sum + b.survivalRate) /
                  allBirths.length)
              .toStringAsFixed(1)
          : '0';

      return {
        'total_births': totalBirths,
        'total_live_kits': totalKits,
        'total_dead_kits': deadKits,
        'avg_survival_rate': avgSurvivalRate,
        'avg_litter_size': totalBirths > 0
            ? ((allBirths.fold<int>(0, (sum, b) => sum + b.litterSize) /
                    totalBirths))
                .toStringAsFixed(1)
            : '0',
      };
    } catch (e) {
      print('Error getting reproduction stats: $e');
      rethrow;
    }
  }
}