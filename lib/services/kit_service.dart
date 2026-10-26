import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';
import '../models/kit.dart';

class KitService {
  final _supabase = Supabase.instance.client;
  static const _tableName = 'kits';
  String get _userId => _supabase.auth.currentUser!.id;

  /// Obtener todas las crías
  Future<List<Kit>> getAllKits() async {
    try {
        final response = await _supabase
          .from(_tableName)
          .select();
      return (response as List)
          .map((json) => Kit.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.e('Error fetching kits', error: e);
      rethrow;
    }
  }

  /// Obtener crías por madre
  Future<List<Kit>> getKitsByMother(String motherId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('mother_id', int.parse(motherId))
          .order('birth_date', ascending: false);
      return (response as List)
          .map((json) => Kit.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.e('Error fetching kits by mother', error: e);
      rethrow;
    }
  }

  /// Obtener una cría por ID
  Future<Kit?> getKitById(String id) async {
    try {
        final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', id)
          .single();
      return Kit.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      logger.e('Error fetching kit', error: e);
      return null;
    }
  }

  /// Crear una nueva cría
  Future<Kit> createKit(Kit kit) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .insert({...kit.toJson(), 'user_id': _userId})
          .select()
          .single();
      return Kit.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      logger.e('Error creating kit', error: e);
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
      logger.e('Error updating kit', error: e);
      rethrow;
    }
  }

  /// Eliminar cría
  Future<void> deleteKit(String id) async {
    try {
        await _supabase
          .from(_tableName)
          .delete()
          .eq('id', id);
    } catch (e) {
      logger.e('Error deleting kit', error: e);
      rethrow;
    }
  }

  /// Obtener crías no destetadas
  Future<List<Kit>> getNotWeanedKits() async {
    try {
        final response = await _supabase
          .from(_tableName)
          .select()
          .isFilter('weaning_date', null);
      return (response as List)
          .map((json) => Kit.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.e('Error fetching not weaned kits', error: e);
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
      logger.e('Error updating kit weight', error: e);
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
      logger.e('Error marking kit as weaned', error: e);
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
      logger.e('Error getting kits stats', error: e);
      rethrow;
    }
  }
}