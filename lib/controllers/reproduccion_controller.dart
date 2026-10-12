import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/logger.dart';
import '../models/reproduccion.dart';
import '../services/reproduccion_service.dart';

class ReproduccionController extends GetxController {
  final _service = ReproduccionService();

  final reproducciones = <Reproduccion>[].obs;
  final conejas = <Map<String, dynamic>>[].obs;
  final machos = <Map<String, dynamic>>[].obs;
  final nacimientos = <Map<String, dynamic>>[].obs;
  final crias = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  String get _userId => Supabase.instance.client.auth.currentUser!.id;

  List<Reproduccion> get servidas =>
      reproducciones.where((r) => r.estado == 'Servida').toList();

  List<Reproduccion> get gestantes =>
      reproducciones.where((r) => r.estado == 'Gestante').toList();

  List<Reproduccion> get fallidas =>
      reproducciones.where((r) => r.estado == 'Fallida').toList();

  List<Reproduccion> get proximasPalpaciones =>
      servidas.where((r) => r.tocaPalpacion).toList();

  List<Reproduccion> get partosProximos {
    final hoy = DateTime.now();
    final en7 = hoy.add(const Duration(days: 7));
    return gestantes.where((r) {
      final fechaProbable = r.fechaProbableParto;
      return fechaProbable != null &&
          fechaProbable.isAfter(hoy) &&
          fechaProbable.isBefore(en7);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadAll();
    loadConejos();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      reproducciones.assignAll(await _service.getAll());
      await Future.wait([loadNacimientos(), loadCrias()]);
    } catch (e) {
      logger.e('Error loading reproducciones', error: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadNacimientos() async {
    try {
      final data = await Supabase.instance.client
          .from('births')
          .select(
            'id, birth_date, mother_id, father_id, litter_size, live_kits, '
            'dead_kits, adopted_kits, average_weight, notes, reproduccion_id',
          )
          .eq('user_id', _userId)
          .order('birth_date', ascending: false);
      nacimientos.assignAll((data as List).cast<Map<String, dynamic>>());
    } catch (e) {
      logger.e('Error loadNacimientos', error: e);
    }
  }

  Future<void> loadCrias() async {
    try {
      final data = await Supabase.instance.client
          .from('kits')
          .select(
            'id, birth_id, chapeta, mother_id, father_id, birth_date, '
            'age_days, health_status, estado_nacimiento, weaning_date, '
            'parto_numero, kit_numero, current_weight',
          )
          .eq('user_id', _userId)
          .order('birth_date', ascending: false);
      crias.assignAll((data as List).cast<Map<String, dynamic>>());
    } catch (e) {
      logger.e('Error loadCrias', error: e);
    }
  }

  Future<void> loadConejos() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('conejo')
          .select('id_conejo, chapeta, genero, reproductive_status')
          .eq('user_id', userId);

      debugPrint('=== CONEJOS CARGADOS ===');
      debugPrint('Total: ${(data as List).length}');
      for (final c in data) {
        debugPrint(
          '  ${c['chapeta']} · ${c['genero']} · ${c['reproductive_status']}',
        );
      }

      final all = (data as List).cast<Map<String, dynamic>>();
      final generosUnicos = all
          .map((c) => c['genero']?.toString())
          .where((g) => g != null)
          .toSet();
      debugPrint('Valores únicos de genero: $generosUnicos');

      conejas.assignAll(all.where((c) => c['genero'] == 'Hembra').toList());
      machos.assignAll(all.where((c) => c['genero'] == 'Macho').toList());

      debugPrint('Hembras: ${conejas.length}, Machos: ${machos.length}');
    } catch (e) {
      logger.e('Error loading conejos', error: e);
    }
  }

  Future<bool> createMonta(Reproduccion r) async {
    final ok = await _service.create(r);
    if (ok) await loadAll();
    return ok;
  }

  Future<bool> updateReproduccion(int id, Reproduccion r) async {
    final ok = await _service.update(id, r);
    if (ok) await loadAll();
    return ok;
  }

  Future<bool> deleteReproduccion(int id) async {
    final ok = await _service.delete(id);
    if (ok) await loadAll();
    return ok;
  }

  Future<bool> confirmarPrenez(Reproduccion r) {
    return updateReproduccion(
      r.idReproduccion!,
      r.copyWith(
        estado: 'Gestante',
        fechaPalpacion: DateTime.now(),
        fechaProbableParto:
            ReproduccionService.calcularProbableParto(r.fechaMonta),
      ),
    );
  }

  Future<bool> registrarFalla(Reproduccion r) {
    return updateReproduccion(
      r.idReproduccion!,
      r.copyWith(
        estado: 'Fallida',
        fechaPalpacion: DateTime.now(),
      ),
    );
  }

  Future<bool> registrarParto(
    Reproduccion r, {
    required DateTime fechaParto,
    required int numVivos,
    required int numMuertos,
    int numAdoptados = 0,
    double? pesoPromedio,
    String? notas,
  }) async {
    final ok = await _service.registrarPartoConNacimiento(
      r,
      fechaParto: fechaParto,
      numVivos: numVivos,
      numMuertos: numMuertos,
      numAdoptados: numAdoptados,
      pesoPromedio: pesoPromedio,
      notas: notas,
    );
    if (ok) await loadAll();
    return ok;
  }
}
