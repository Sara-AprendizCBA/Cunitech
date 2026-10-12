import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/logger.dart';
import '../models/reproduccion.dart';

class ReproduccionService {
  final supabase = Supabase.instance.client;

  String get _userId => supabase.auth.currentUser!.id;

  Future<List<Reproduccion>> getAll() async {
    try {
      final data = await supabase
          .from('reproduccion')
          .select()
          .eq('user_id', _userId)
          .order('fecha_monta', ascending: false);
      return (data as List)
          .map((json) =>
              Reproduccion.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.e('Error fetching reproductions', error: e);
      return [];
    }
  }

  Future<bool> create(Reproduccion item) async {
    try {
      // Solo auto-calcular si el item no tiene fecha (fallback defensivo).
      final actualizada = item.fechaProbableParto != null
          ? item
          : item.copyWith(
              fechaProbableParto: calcularProbableParto(item.fechaMonta),
            );
      final data = actualizada.toJson()..['user_id'] = _userId;
      await supabase.from('reproduccion').insert(data);
      await _syncConejoStatus(actualizada);
      return true;
    } catch (e) {
      logger.e('Error creating reproduction', error: e);
      return false;
    }
  }

  Future<bool> update(int id, Reproduccion item) async {
    try {
      // Solo auto-calcular si el item no tiene fecha (fallback defensivo).
      final actualizada = item.fechaProbableParto != null
          ? item
          : item.copyWith(
              fechaProbableParto: calcularProbableParto(item.fechaMonta),
            );
      final data = actualizada.toJson()..['user_id'] = _userId;
      await supabase
          .from('reproduccion')
          .update(data)
          .eq('id_reproduccion', id)
          .eq('user_id', _userId);
      await _syncConejoStatus(actualizada);
      return true;
    } catch (e) {
      logger.e('Error updating reproduction', error: e);
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await supabase
          .from('reproduccion')
          .delete()
          .eq('id_reproduccion', id)
          .eq('user_id', _userId);
      return true;
    } catch (e) {
      logger.e('Error deleting reproduction', error: e);
      return false;
    }
  }

  Future<bool> registrarPartoConNacimiento(
    Reproduccion r, {
    required DateTime fechaParto,
    required int numVivos,
    required int numMuertos,
    int numAdoptados = 0,
    double? pesoPromedio,
    String? notas,
  }) async {
    try {
      final fechaStr = _dateToJson(fechaParto);
      final actualizada = r.copyWith(
        estado: 'Lactante',
        fechaParto: fechaParto,
        numVivos: numVivos,
        numMuertos: numMuertos,
        numAdoptados: numAdoptados,
        numeroCrias: numVivos + numAdoptados,
        pesoPromedioCamada: pesoPromedio,
        notas: notas,
      );

      await supabase
          .from('reproduccion')
          .update({
            'estado': 'Lactante',
            'fecha_parto': fechaStr,
            'num_vivos': numVivos,
            'num_muertos': numMuertos,
            'num_adoptados': numAdoptados,
            'numero_crias': numVivos + numAdoptados,
            'peso_promedio_camada': pesoPromedio,
            'notas': notas,
          })
          .eq('id_reproduccion', r.idReproduccion!)
          .eq('user_id', _userId);

      await _syncConejoStatus(actualizada);

      final birthData = {
        'reproduccion_id': r.idReproduccion,
        'mother_id': r.idConeja,
        'father_id': r.idConejopadre,
        'birth_date': fechaStr,
        'litter_size': numVivos + numMuertos + numAdoptados,
        'live_kits': numVivos,
        'dead_kits': numMuertos,
        'adopted_kits': numAdoptados,
        'average_weight': pesoPromedio ?? 0,
        'notes': notas ?? '',
        'user_id': _userId,
      };

      final existingBirth = await supabase
          .from('births')
          .select('id')
          .eq('reproduccion_id', r.idReproduccion!)
          .eq('user_id', _userId)
          .limit(1)
          .maybeSingle();

      late final String birthId;
      if (existingBirth != null) {
        birthId = existingBirth['id'] as String;
        await supabase
            .from('births')
            .update(birthData)
            .eq('id', birthId)
            .eq('user_id', _userId);
      } else {
        final inserted = await supabase
            .from('births')
            .insert(birthData)
            .select('id')
            .single();
        birthId = inserted['id'] as String;
      }

      await _generarKits(
        birthId: birthId,
        reproduccion: r,
        fechaParto: fechaParto,
        numVivos: numVivos,
        numMuertos: numMuertos,
      );
      return true;
    } catch (e) {
      logger.e('Error registrarPartoConNacimiento', error: e);
      return false;
    }
  }

  Future<void> _generarKits({
    required String birthId,
    required Reproduccion reproduccion,
    required DateTime fechaParto,
    required int numVivos,
    required int numMuertos,
  }) async {
    final madre = await supabase
        .from('conejo')
        .select('chapeta')
        .eq('id_conejo', reproduccion.idConeja)
        .eq('user_id', _userId)
        .single();
    final chapetaMadre = madre['chapeta'] as String? ?? 'SIN-ID';

    final partos = await supabase
        .from('reproduccion')
        .select('id_reproduccion')
        .eq('id_coneja', reproduccion.idConeja)
        .eq('user_id', _userId)
        .lte('fecha_parto', _dateToJson(fechaParto));
    final partoNumero = (partos as List).length;
    final fechaStr = _dateToJson(fechaParto);

    final existingKits = await supabase
        .from('kits')
        .select('kit_numero')
        .eq('birth_id', birthId)
        .eq('user_id', _userId);
    final kitNumbers = (existingKits as List)
        .map((kit) => (kit as Map<String, dynamic>)['kit_numero'])
        .whereType<int>()
        .toSet();

    for (var i = 1; i <= numVivos; i++) {
      if (kitNumbers.contains(i)) continue;
      await supabase.from('kits').insert({
        'birth_id': birthId,
        'mother_id': reproduccion.idConeja,
        'father_id': reproduccion.idConejopadre,
        'birth_date': fechaStr,
        'chapeta': '$chapetaMadre-$partoNumero$i',
        'parto_numero': partoNumero,
        'kit_numero': i,
        'estado_nacimiento': 'Vivo',
        'health_status': 'Saludable',
        'age_days': 0,
        'user_id': _userId,
      });
    }

    for (var i = 1; i <= numMuertos; i++) {
      final kitNum = numVivos + i;
      if (kitNumbers.contains(kitNum)) continue;
      await supabase.from('kits').insert({
        'birth_id': birthId,
        'mother_id': reproduccion.idConeja,
        'father_id': reproduccion.idConejopadre,
        'birth_date': fechaStr,
        'chapeta': '$chapetaMadre-$partoNumero$kitNum',
        'parto_numero': partoNumero,
        'kit_numero': kitNum,
        'estado_nacimiento': 'Muerto',
        'health_status': 'Muerto',
        'age_days': 0,
        'user_id': _userId,
      });
    }
  }

  static DateTime calcularProbableParto(DateTime monta) =>
      monta.add(const Duration(days: 31));

  Future<void> _syncConejoStatus(Reproduccion r) async {
    final statusConejo = switch (r.estado) {
      'Servida' => 'Servida',
      'Gestante' => 'Gestante',
      'Lactante' => 'Lactante',
      'Fallida' => 'Vacía',
      _ => 'Vacía',
    };

    await supabase
        .from('conejo')
        .update({
          'reproductive_status': statusConejo,
          'mating_date': _dateToJson(r.fechaMonta),
          'expected_birth_date': r.fechaProbableParto == null
              ? null
              : _dateToJson(r.fechaProbableParto!),
          'actual_birth_date': r.fechaParto == null
              ? null
              : _dateToJson(r.fechaParto!),
          'actual_litter_size': r.numeroCrias,
          'next_mating_date': r.fechaDestete != null
              ? _dateToJson(
                  r.fechaDestete!.add(const Duration(days: 42)),
                )
              : null,
        })
        .eq('id_conejo', r.idConeja)
        .eq('user_id', _userId);
  }

  static String _dateToJson(DateTime date) =>
      date.toIso8601String().split('T').first;
}
