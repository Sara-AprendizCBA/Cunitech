import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/logger.dart';
import '../models/alimentacion_jaula.dart';
import '../services/feeding_service.dart';

class FeedingController extends GetxController {
  final _service = FeedingService();

  final feedings = <AlimentacionJaula>[].obs;
  final jaulasDelUsuario = <String>[].obs;
  final isLoading = false.obs;

  List<AlimentacionJaula> get registrosDeHoy {
    final hoy = DateTime.now();
    return feedings
        .where(
          (f) =>
              f.fecha.year == hoy.year &&
              f.fecha.month == hoy.month &&
              f.fecha.day == hoy.day,
        )
        .toList();
  }

  int get jaulasRegistradasHoy =>
      registrosDeHoy.map((f) => f.jaula).toSet().length;

  int get totalJaulas => jaulasDelUsuario.length;

  double get kgRegistradosHoy =>
      registrosDeHoy.fold(0.0, (sum, f) => sum + f.cantidadKg);

  double get porcentajeHoy =>
      totalJaulas == 0 ? 0 : (jaulasRegistradasHoy / totalJaulas) * 100;

  List<String> get jaulasPendientesHoy {
    final registradas = registrosDeHoy.map((f) => f.jaula).toSet();
    return jaulasDelUsuario.where((j) => !registradas.contains(j)).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadAll();
    loadJaulas();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      feedings.assignAll(await _service.getAll());
    } catch (e) {
      logger.e('Error loadAll feeding', error: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadJaulas() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('conejo')
          .select('cage_number')
          .eq('user_id', userId)
          .not('cage_number', 'is', null);

      final jaulas = (data as List)
          .map((e) => e['cage_number'] as String?)
          .where((j) => j != null && j.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList()
        ..sort();

      jaulasDelUsuario.assignAll(jaulas);
    } catch (e) {
      logger.e('Error loadJaulas', error: e);
      jaulasDelUsuario.clear();
    }
  }

  Future<bool> createFeeding(AlimentacionJaula item) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final itemConUser = AlimentacionJaula(
      jaula: item.jaula,
      fecha: item.fecha,
      cantidadKg: item.cantidadKg,
      tipoComida: item.tipoComida,
      estado: item.estado,
      notas: item.notas,
      userId: userId,
    );
    final ok = await _service.create(itemConUser);
    if (ok) await loadAll();
    return ok;
  }

  Future<bool> updateFeeding(String id, AlimentacionJaula item) async {
    final ok = await _service.update(id, item);
    if (ok) await loadAll();
    return ok;
  }

  Future<bool> deleteFeeding(String id) async {
    final ok = await _service.delete(id);
    if (ok) await loadAll();
    return ok;
  }
}
