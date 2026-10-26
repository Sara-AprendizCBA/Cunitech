import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/logger.dart';
import '../models/meta_mensual.dart';

class ReportesController extends GetxController {
  final supabase = Supabase.instance.client;
  String get _userId => supabase.auth.currentUser!.id;

  final totalConejos = 0.obs;
  final conejasGestantes = 0.obs;
  final nacimientosMes = 0.obs;
  final tasaSupervivencia = 0.0.obs;
  final pesoPromedio = 0.0.obs;
  final poblacionPorDia = <Map<String, dynamic>>[].obs;
  final nacimientosRecientes = <Map<String, dynamic>>[].obs;
  final montasRecientes = <Map<String, dynamic>>[].obs;
  final alertasSalud = <Map<String, dynamic>>[].obs;
  final metasMes = <MetaMensual>[].obs;
  final valoresActualesKpi = <String, double>{}.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadTotalConejos(),
        _loadConejasGestantes(),
        _loadNacimientosMes(),
        _loadTasaSupervivencia(),
        _loadPesoPromedio(),
        _loadPoblacionPorDia(),
        _loadActividadReciente(),
        _loadMetas(),
      ]);
    } catch (e) {
      logger.e('Error loadAll reportes', error: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadTotalConejos() async {
    try {
      final data = await supabase
          .from('conejo')
          .select('id_conejo');
      totalConejos.value = (data as List).length;
    } catch (e) {
      logger.e('Error loadTotalConejos', error: e);
    }
  }

  Future<void> _loadConejasGestantes() async {
    try {
      final data = await supabase
          .from('conejo')
          .select('id_conejo')
          .eq('genero', 'Hembra')
          .inFilter('reproductive_status', [
            'Servida',
            'Gestante',
            'Lactante',
            'Destete',
          ]);
      conejasGestantes.value = (data as List).length;
    } catch (e) {
      logger.e('Error loadConejasGestantes', error: e);
    }
  }

  Future<void> _loadNacimientosMes() async {
    try {
      final ahora = DateTime.now();
      final inicioMes = DateTime(ahora.year, ahora.month, 1);
      final data = await supabase
          .from('births')
          .select('id')
          .gte('birth_date', inicioMes.toIso8601String().split('T')[0]);
      nacimientosMes.value = (data as List).length;
    } catch (e) {
      logger.e('Error loadNacimientosMes', error: e);
    }
  }

  Future<void> _loadTasaSupervivencia() async {
    try {
      final data = await supabase
          .from('births')
          .select('live_kits, litter_size');

      if ((data as List).isEmpty) {
        tasaSupervivencia.value = 0;
        return;
      }

      var vivos = 0;
      var total = 0;
      for (final birth in data) {
        vivos += (birth['live_kits'] as num?)?.toInt() ?? 0;
        total += (birth['litter_size'] as num?)?.toInt() ?? 0;
      }
      tasaSupervivencia.value = total == 0 ? 0 : (vivos / total) * 100;
    } catch (e) {
      logger.e('Error loadTasaSupervivencia', error: e);
    }
  }

  Future<void> _loadPesoPromedio() async {
    try {
      final data = await supabase
          .from('conejo')
          .select('peso')
          .not('peso', 'is', null);

      if ((data as List).isEmpty) {
        pesoPromedio.value = 0;
        return;
      }

      var suma = 0.0;
      var count = 0;
      for (final rabbit in data) {
        final peso = (rabbit['peso'] as num?)?.toDouble();
        if (peso != null) {
          suma += peso;
          count++;
        }
      }
      pesoPromedio.value = count == 0 ? 0 : suma / count;
    } catch (e) {
      logger.e('Error loadPesoPromedio', error: e);
    }
  }

  Future<void> _loadPoblacionPorDia() async {
    try {
      final ahora = DateTime.now();

      final conejos = await supabase
          .from('conejo')
          .select('fecha_nacimiento')
          .not('fecha_nacimiento', 'is', null);

      final kits = await supabase
          .from('kits')
          .select('birth_date')
          .eq('estado_nacimiento', 'Vivo');

      final conejosList = (conejos as List).cast<Map<String, dynamic>>();
      final kitsList = (kits as List).cast<Map<String, dynamic>>();
      final resultado = <Map<String, dynamic>>[];

      for (var i = 29; i >= 0; i--) {
        final dia = ahora.subtract(Duration(days: i));
        final diaStr = dia.toIso8601String().split('T')[0];

        var totalConejos = 0;
        for (final conejo in conejosList) {
          final fechaNacimiento = conejo['fecha_nacimiento'] as String?;
          if (fechaNacimiento != null &&
              fechaNacimiento.compareTo(diaStr) <= 0) {
            totalConejos++;
          }
        }

        var totalKits = 0;
        for (final kit in kitsList) {
          final fechaNacimiento = kit['birth_date'] as String?;
          if (fechaNacimiento != null &&
              fechaNacimiento.split('T').first.compareTo(diaStr) <= 0) {
            totalKits++;
          }
        }

        resultado.add({
          'dia': diaStr,
          'conejos': totalConejos,
          'kits': totalKits,
          'total': totalConejos + totalKits,
        });
      }

      poblacionPorDia.assignAll(resultado);
    } catch (e) {
      logger.e('Error loadPoblacionPorDia', error: e);
      poblacionPorDia.clear();
    }
  }

  Future<void> _loadActividadReciente() async {
    try {
      final nacimientos = await supabase
          .from('births')
          .select('id, birth_date, live_kits, dead_kits, mother_id')
          .order('birth_date', ascending: false)
          .limit(5);
      final listaNac =
          (nacimientos as List).cast<Map<String, dynamic>>();
      for (final item in listaNac) {
        final madre = await supabase
            .from('conejo')
            .select('chapeta')
            .eq('id_conejo', item['mother_id'])
            .maybeSingle();
        item['chapeta_madre'] = madre?['chapeta'] ?? 'Sin ID';
      }
      nacimientosRecientes.assignAll(listaNac);

      final montas = await supabase
          .from('reproduccion')
          .select('id_reproduccion, fecha_monta, id_coneja, estado')
          .order('fecha_monta', ascending: false)
          .limit(5);
      final listaMontas =
          (montas as List).cast<Map<String, dynamic>>();
      for (final item in listaMontas) {
        final coneja = await supabase
            .from('conejo')
            .select('chapeta')
            .eq('id_conejo', item['id_coneja'])
            .maybeSingle();
        item['chapeta_coneja'] = coneja?['chapeta'] ?? 'Sin ID';
      }
      montasRecientes.assignAll(listaMontas);

      final alertas = await supabase
          .from('conejo')
          .select('id_conejo, chapeta, estado')
          .inFilter('estado', ['En tratamiento', 'Enfermo'])
          .limit(3);
      alertasSalud.assignAll(
        (alertas as List).cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      logger.e('Error loadActividadReciente', error: e);
    }
  }

  Future<void> _loadMetas() async {
    try {
      final ahora = DateTime.now();
      final data = await supabase
          .from('metas_mensuales')
          .select()
          .eq('anio', ahora.year)
          .eq('mes', ahora.month);

      final lista = (data as List)
          .map(
            (json) => MetaMensual.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
      metasMes.assignAll(lista);

      if (lista.isNotEmpty) {
        await Future.wait([
          _loadNacimientosMes(),
          _loadTasaSupervivencia(),
        ]);
      }

      final valores = <String, double>{};
      for (final meta in lista) {
        valores[meta.kpi] = await _calcularValorKpi(meta.kpi);
      }
      valoresActualesKpi.assignAll(valores);
    } catch (e) {
      logger.e('Error loadMetas', error: e);
    }
  }

  Future<double> _calcularValorKpi(String kpi) async {
    switch (kpi) {
      case 'prolificidad':
        final data = await supabase
            .from('births')
            .select('litter_size');
        final nacimientos = data as List;
        if (nacimientos.isEmpty) return 0;
        var totalGazapos = 0;
        for (final nacimiento in nacimientos) {
          totalGazapos +=
              (nacimiento['litter_size'] as num?)?.toInt() ?? 0;
        }
        return totalGazapos / nacimientos.length;

      case 'fertilidad':
        final montas = await supabase
            .from('reproduccion')
            .select('id_reproduccion');
        final partos = await supabase
            .from('reproduccion')
            .select('id_reproduccion')
            .eq('estado', 'Lactante');
        final totalMontas = (montas as List).length;
        final totalPartos = (partos as List).length;
        return totalMontas == 0 ? 0 : (totalPartos / totalMontas) * 100;

      case 'supervivencia':
        return tasaSupervivencia.value;

      case 'nacimientos':
        return nacimientosMes.value.toDouble();

      default:
        return 0;
    }
  }

  double progresoMeta(MetaMensual meta) {
    final actual = valoresActualesKpi[meta.kpi] ?? 0;
    if (meta.valorObjetivo == 0) return 0;
    return (actual / meta.valorObjetivo) * 100;
  }

  String estadoMeta(MetaMensual meta) {
    final progreso = progresoMeta(meta);
    if (progreso >= 100) return 'Cumplida';
    if (progreso >= 80) return 'Cerca';
    return 'En progreso';
  }

  String colorEstadoMeta(MetaMensual meta) {
    final progreso = progresoMeta(meta);
    if (progreso >= 100) return 'success';
    if (progreso >= 80) return 'warning';
    return 'danger';
  }

  Future<bool> crearMeta(MetaMensual meta) async {
    try {
      final data = meta.toJson()..['user_id'] = _userId;
      await supabase.from('metas_mensuales').insert(data);
      await _loadMetas();
      return true;
    } catch (e) {
      logger.e('Error crearMeta', error: e);
      return false;
    }
  }

  Future<bool> actualizarMeta(String id, MetaMensual meta) async {
    try {
      await supabase
          .from('metas_mensuales')
          .update(meta.toJson())
          .eq('id', id);
      await _loadMetas();
      return true;
    } catch (e) {
      logger.e('Error actualizarMeta', error: e);
      return false;
    }
  }

  Future<bool> eliminarMeta(String id) async {
    try {
      await supabase
          .from('metas_mensuales')
          .delete()
          .eq('id', id);
      await _loadMetas();
      return true;
    } catch (e) {
      logger.e('Error eliminarMeta', error: e);
      return false;
    }
  }

  double get mortalidad => 100 - tasaSupervivencia.value;

  double get tasaGestacion {
    if (totalConejos.value == 0) return 0;
    return (conejasGestantes.value / totalConejos.value) * 100;
  }

  String get mortalidadTexto {
    final total = totalConejos.value;
    if (total == 0) return 'Sin datos';
    return '${(100 - tasaSupervivencia.value).toStringAsFixed(1)}%';
  }

  String get mortalidadSubtitulo {
    if (totalConejos.value == 0) return 'Registra un conejo primero';
    return 'Según partos registrados';
  }

  String get pesoPromedioTexto {
    if (totalConejos.value == 0) return 'Sin datos';
    return '${pesoPromedio.value.toStringAsFixed(1)} kg';
  }

  String get pesoPromedioSubtitulo {
    if (totalConejos.value == 0) return 'Registra un conejo primero';
    return 'Promedio del criadero';
  }

  String get tasaGestacionTexto =>
      '${tasaGestacion.toStringAsFixed(0)}%';

  String get tasaGestacionSubtitulo {
    final total = totalConejos.value;
    if (total == 0) return 'Sin conejas registradas';
    return '${conejasGestantes.value} de $total en ciclo';
  }

  String get insightTitulo {
    if (totalConejos.value == 0) return 'Sin datos';
    if (nacimientosMes.value > 0) return 'Producción activa';
    if (conejasGestantes.value > 0) return 'En gestación';
    return 'Sin actividad reproductiva';
  }

  String get insightBadge {
    if (totalConejos.value == 0) return 'Sin datos';
    if (nacimientosMes.value > 0) return 'Producción activa';
    if (conejasGestantes.value > 0) return 'En gestación';
    return 'Sin actividad';
  }

  String get insightTexto {
    final total = totalConejos.value;
    final gestantes = conejasGestantes.value;
    final nacimientos = nacimientosMes.value;

    if (total == 0) {
      return 'Aún no hay conejos registrados. Comienza registrando '
          'tus primeros animales para ver las estadísticas.';
    }
    if (nacimientos > 0) {
      return 'Criadero activo con $total conejos. '
          '$nacimientos nacimiento(s) registrado(s) este mes. '
          '$gestantes coneja(s) en gestación actual.';
    }
    if (gestantes > 0) {
      return 'Hay $gestantes coneja(s) gestante(s) con partos '
          'aproximándose. No hay nacimientos registrados este mes.';
    }
    return 'Tienes $total conejos registrados. '
        'Registra una monta para iniciar el ciclo reproductivo.';
  }
}
