import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rabbit.dart';
import '../models/birth.dart';
import 'rabbit_controller.dart';
import 'birth_controller.dart';
import 'kit_controller.dart';

class DashboardController extends GetxController {
  RealtimeChannel? _realtimeChannel;

  final rabbitController = Get.put(RabbitController());
  final birthController = Get.put(BirthController());
  final kitController = Get.put(KitController());

  // Observables para el Dashboard
  final totalRabbits = 0.obs;
  final totalBirths = 0.obs;
  final survivalRate = '0%'.obs;
  final alerts = 0.obs;
  final upcomingBirths = <Birth>[].obs;
  final activeRabbits = <Rabbit>[].obs;
  final overduePregnancies = <Rabbit>[].obs;
  final isLoading = false.obs;

  // Valores derivados para las tarjetas del resumen
  final rabbitsThisMonth = 0.obs;
  final birthsThisMonth = 0.obs;
  final liveKitsTotal = 0.obs;
  final healthAlerts = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
    _realtimeChannel = Supabase.instance.client
        .channel('dashboard_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conejo',
          callback: (_) => loadDashboardData(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'births',
          callback: (_) => loadDashboardData(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'kits',
          callback: (_) => loadDashboardData(),
        )
        .subscribe();
    // Escuchar cambios en otros controladores
    ever(rabbitController.rabbits, (_) {
      updateDashboardMetrics();
      loadActiveRabbits();
      generateAlerts();
    });
    ever(birthController.births, (_) => updateDashboardMetrics());
  }

  @override
  void onClose() {
    _realtimeChannel?.unsubscribe();
    super.onClose();
  }

  /// Cargar todos los datos del dashboard
  Future<void> loadDashboardData() async {
    try {
      isLoading(true);

      // Cargar datos en paralelo
      await Future.wait([
        rabbitController.loadAllRabbits(),
        birthController.loadAllBirths(),
        birthController.loadReproductionStats(),
        kitController.loadAllKits(),
      ]);

      await loadActiveRabbits();
      updateDashboardMetrics();
      await generateAlerts();
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Cargar conejas activas desde Supabase con filtros de usuario y estado
  Future<void> loadActiveRabbits() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      activeRabbits.clear();
      return;
    }

    try {
      final rows = await supabase
          .from('conejo')
          .select()
          .eq('user_id', userId)
          .eq('genero', 'Hembra')
          .inFilter('reproductive_status', [
            'Vacía',
            'Servida',
            'Gestante',
            'Lactante',
          ])
          .neq('estado', 'Vendida')
          .order('nombre');
      activeRabbits.assignAll(
        (rows as List)
            .map((row) => Rabbit.fromJson(row as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      activeRabbits.clear();
      debugPrint('Error loading active rabbits: $e');
    }
  }

  /// Actualizar métricas del dashboard
  void updateDashboardMetrics() {
    // Total de conejos
    totalRabbits.value = rabbitController.rabbits.length;

    // Total de partos
    totalBirths.value = birthController.births.length;

    // Tasa de supervivencia promedio
    if (birthController.births.isNotEmpty) {
      final totalRate = birthController.births.fold<int>(
        0,
        (sum, b) => sum + b.survivalRate,
      );
      final avgRate = (totalRate / birthController.births.length)
          .toStringAsFixed(1);
      survivalRate.value = '$avgRate%';
    } else {
      survivalRate.value = '0%';
    }

    // Conejos registrados este mes
    final now = DateTime.now();
    rabbitsThisMonth.value = rabbitController.rabbits
        .where((r) =>
            r.registrationDate.year == now.year &&
            r.registrationDate.month == now.month)
        .length;

    // Partos de este mes
    birthsThisMonth.value = birthController.births
        .where((b) =>
            b.birthDate.year == now.year && b.birthDate.month == now.month)
        .length;

    // Crías vivas acumuladas
    liveKitsTotal.value = birthController.births.fold<int>(
      0,
      (sum, b) => sum + b.liveKits,
    );

    // Conejos en tratamiento
    healthAlerts.value = rabbitController.rabbits
        .where((r) => r.healthStatus.contains('Tratamiento'))
        .length;

    // Próximos partos esperados
    final upcoming = rabbitController.rabbits
        .where(
          (r) =>
              r.expectedBirthDate != null &&
              r.expectedBirthDate!.isAfter(DateTime.now()),
        )
        .toList();

    // Crear Birth objects simulados para mostrar en el banner
    final upcomingList = upcoming.map((r) {
      return Birth(
        id: r.id,
        motherId: int.tryParse(r.id),
        birthDate: r.expectedBirthDate ?? DateTime.now(),
        litterSize: 0,
        averageWeight: 0,
      );
    }).toList();
    upcomingBirths.assignAll(upcomingList);
  }

  /// Generar alertas locales y reproductivas desde Supabase
  Future<void> generateAlerts() async {
    int alertCount = 0;

    // Alerta: conejos enfermos
    final sickRabbits = rabbitController.rabbits
        .where((r) => r.healthStatus.contains('Tratamiento'))
        .length;
    alertCount += sickRabbits;

    // Alerta: conejos no alimentados recientemente (más de 2 días)
    final notFedRabbits = rabbitController.rabbits.where((r) {
      if (r.lastFeedingDate == null) return true;
      final daysSinceFeeding = DateTime.now()
          .difference(r.lastFeedingDate!)
          .inDays;
      return daysSinceFeeding > 2;
    }).length;
    alertCount += notFedRabbits;

    await loadAlerts(baseAlertCount: alertCount);
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Cuenta los tratamientos con fecha de próxima aplicación en los próximos
  /// 7 días. Devuelve 0 si la tabla `tratamientos` aún no existe.
  Future<int> _countTratamientosProximos(
    String userId,
    DateTime today,
    DateTime inSevenDays,
  ) async {
    try {
      final rows = await Supabase.instance.client
          .from('tratamientos')
          .select('id')
          .eq('user_id', userId)
          .gte('fecha_proxima', _dateOnly(today))
          .lte('fecha_proxima', _dateOnly(inSevenDays));
      return (rows as List).length;
    } catch (e) {
      debugPrint('Error counting upcoming treatments: $e');
      return 0;
    }
  }

  /// Consultar alertas reproductivas con fechas de calendario locales
  Future<void> loadAlerts({int baseAlertCount = 0}) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      overduePregnancies.clear();
      alerts.value = baseAlertCount;
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final inSevenDays = today.add(const Duration(days: 7));
    final overdueCutoff = today.subtract(const Duration(days: 33));
    final palpationCutoff = today.subtract(const Duration(days: 14));

    final tratamientosProximos = await _countTratamientosProximos(
      userId,
      today,
      inSevenDays,
    );

    try {
      final upcomingBirths = await supabase
          .from('conejo')
          .select('id_conejo')
          .eq('user_id', userId)
          .eq('reproductive_status', 'Gestante')
          .gte('expected_birth_date', _dateOnly(tomorrow))
          .lte('expected_birth_date', _dateOnly(inSevenDays));

      final birthsToday = await supabase
          .from('conejo')
          .select('id_conejo')
          .eq('user_id', userId)
          .eq('reproductive_status', 'Gestante')
          .eq('expected_birth_date', _dateOnly(today));

      final overdueRows = await supabase
          .from('conejo')
          .select()
          .eq('user_id', userId)
          .eq('reproductive_status', 'Gestante')
          .lt('mating_date', _dateOnly(overdueCutoff));

      final unpalpatedBirths = await supabase
          .from('conejo')
          .select('id_conejo')
          .eq('user_id', userId)
          .eq('reproductive_status', 'Servida')
          .lte('mating_date', _dateOnly(palpationCutoff));

      overduePregnancies.assignAll(
        (overdueRows as List)
            .map((row) => Rabbit.fromJson(row as Map<String, dynamic>))
            .toList(),
      );
      alerts.value =
          baseAlertCount +
          upcomingBirths.length +
          birthsToday.length +
          overdueRows.length +
          unpalpatedBirths.length +
          tratamientosProximos;
    } catch (e) {
      debugPrint('Error loading reproductive alerts: $e');
      alerts.value = baseAlertCount + tratamientosProximos;
    }
  }

  /// Obtener próximo parto esperado
  Rabbit? getNextExpectedBirth() {
    if (overduePregnancies.isNotEmpty) {
      final overdue = overduePregnancies.toList()
        ..sort(
          (a, b) => (a.matingDate ?? DateTime.now()).compareTo(
            b.matingDate ?? DateTime.now(),
          ),
        );
      return overdue.first;
    }

    final gestating =
        activeRabbits
            .where(
              (rabbit) =>
                  rabbit.gender == 'Hembra' &&
                  rabbit.reproductiveStatus == 'Gestante' &&
                  rabbit.expectedBirthDate != null,
            )
            .toList()
          ..sort(
            (a, b) => a.expectedBirthDate!.compareTo(b.expectedBirthDate!),
          );
    return gestating.isEmpty ? null : gestating.first;
  }

  /// Obtener conejos enfermos
  List<Rabbit> getSickRabbits() {
    return rabbitController.rabbits
        .where((r) => r.healthStatus.contains('Tratamiento'))
        .toList();
  }

  /// Obtener estadísticas rápidas
  Map<String, dynamic> getQuickStats() {
    return {
      'total_rabbits': totalRabbits.value,
      'total_births': totalBirths.value,
      'survival_rate': survivalRate.value,
      'alerts': alerts.value,
      'active_rabbits': activeRabbits.length,
      'sick_rabbits': getSickRabbits().length,
      'total_kits': kitController.kits.length,
    };
  }

  /// Refrescar datos (pull to refresh)
  Future<void> refreshData() async {
    await loadDashboardData();
  }

  /// Obtener datos de un conejo específico con su historial
  Future<Map<String, dynamic>> getRabbitDetails(String rabbitId) async {
    final rabbit = rabbitController.getRabbitById(rabbitId);
    if (rabbit == null) return {};

    final births = await birthController.getBirthsByMother(rabbitId);
    final kits = await kitController.getKitsByMother(rabbitId);

    return {
      'rabbit': rabbit,
      'births': births,
      'kits': kits,
      'total_births': births.length,
      'total_kits': kits.length,
      'avg_survival_rate': births.isNotEmpty
          ? (births.fold<int>(0, (sum, b) => sum + b.survivalRate) /
                    births.length)
                .toStringAsFixed(1)
          : '0',
    };
  }
}
