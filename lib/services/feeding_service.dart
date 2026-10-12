import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/logger.dart';
import '../models/alimentacion_jaula.dart';

class FeedingService {
  final supabase = Supabase.instance.client;

  Future<List<AlimentacionJaula>> getAll() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('alimentacion')
          .select()
          .eq('user_id', userId)
          .order('fecha', ascending: false)
          .limit(100);
      return (data as List)
          .map((e) => AlimentacionJaula.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.e('Error getAll feedings', error: e);
      return [];
    }
  }

  Future<bool> create(AlimentacionJaula item) async {
    try {
      await supabase.from('alimentacion').insert(item.toJson());
      return true;
    } catch (e) {
      logger.e('Error create feeding', error: e);
      return false;
    }
  }

  Future<bool> update(String id, AlimentacionJaula item) async {
    try {
      await supabase
          .from('alimentacion')
          .update(item.toJson())
          .eq('id', id);
      return true;
    } catch (e) {
      logger.e('Error update feeding', error: e);
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await supabase.from('alimentacion').delete().eq('id', id);
      return true;
    } catch (e) {
      logger.e('Error delete feeding', error: e);
      return false;
    }
  }
}
