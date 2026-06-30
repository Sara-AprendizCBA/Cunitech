import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kit.dart';

class KitService {
  final _supabase = Supabase.instance.client;
  static const _tableName = 'kits';

  /// Obtener todas las crías
  Future<List<Kit>> getAllKits() async {
    try {
      final response = await _supabase.from(_tableName).select();
      return (response as List)
          .map((json) => Kit.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching kits: $e');
      rethrow;
    }
  }

  /// Obtener crías por madre
  Future<List<Kit>> getKitsByMother(String motherId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('mother_id', motherId)
          .order('birth_date', ascending: false);
      return (response as List)
          .map((json) => Kit.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching kits by mother: $e');
      rethrow;
    }
  }

  /// Obtener una cría por ID
  Future<Kit?> getKitById(String id) async {
    try {
      final response =
          await _supabase.from(_tableName).select().eq('id', id).single();
      return Kit.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching kit: $e');
      return null;
    }
  }

  /// Crear una nueva cría
  Future<Kit> createKit(Kit kit) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .insert(kit.toJson())
          .select()
          .single();
      return Kit.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error creating kit: $e');
      rethrow;
    }
  }

  /// Actualizar cría
  Future<Kit> updateKit(String id, Kit kit) async {
    try {
      final data = kit.toJson();
      data.remove('id');
      final response = await _supabase
          .from(_tableName)
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Kit.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error updating kit: $e');
      rethrow;
    }
  }

  /// Eliminar cría
  Future<void> deleteKit(String id) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', id);
    } catch (e) {
      print('Error deleting kit: $e');
      rethrow;
    }
  }

  /// Obtener crías no destetadas
  Future<List<Kit>> getNotWeanedKits() async {
    try {
      final response =
          await _supabase.from(_tableName).select().isFilter('weaning_date', true);
      return (response as List)
          .map((json) => Kit.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching not weaned kits: $e');
      rethrow;
    }
  }

  /// Actualizar peso de cría
  Future<void> updateWeight(String kitId, double newWeight) async {
    try {
      await _supabase
          .from(_tableName)
          .update({'current_weight': newWeight})
          .eq('id', kitId);
    } catch (e) {
      print('Error updating kit weight: $e');
      rethrow;
    }
  }

  /// Marcar como destetada
  Future<void> markAsWeaned(String kitId) async {
    try {
      await _supabase
          .from(_tableName)
          .update({'weaning_date': DateTime.now().toIso8601String()})
          .eq('id', kitId);
    } catch (e) {
      print('Error marking kit as weaned: $e');
      rethrow;
    }
  }

  /// Obtener estadísticas de crías
  Future<Map<String, dynamic>> getKitsStats() async {
    try {
      final allKits = await getAllKits();
      
      final totalKits = allKits.length;
      final healthyKits =
          allKits.where((k) => k.healthStatus == 'Saludable').length;
      final avgWeight = totalKits > 0
          ? (allKits.fold<double>(0, (sum, k) => sum + k.currentWeight) /
                  totalKits)
              .toStringAsFixed(2)
          : '0';
      final totalGain = allKits.fold<double>(
          0, (sum, k) => sum + (k.currentWeight - k.birthWeight));

      return {
        'total_kits': totalKits,
        'healthy_kits': healthyKits,
        'avg_weight': avgWeight,
        'total_weight_gain': totalGain.toStringAsFixed(2),
      };
    } catch (e) {
      print('Error getting kits stats: $e');
      rethrow;
    }
  }
}