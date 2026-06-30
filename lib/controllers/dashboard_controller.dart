import 'package:get/get.dart';
import '../models/rabbit.dart';
import '../models/birth.dart';
import 'rabbit_controller.dart';
import 'birth_controller.dart';
import 'kit_controller.dart';

class DashboardController extends GetxController {
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
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
    // Escuchar cambios en otros controladores
    ever(rabbitController.rabbits, (_) => updateDashboardMetrics());
    ever(birthController.births, (_) => updateDashboardMetrics());
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

      updateDashboardMetrics();
      generateAlerts();
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      isLoading(false);
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
      final totalRate = birthController.births
          .fold<int>(0, (sum, b) => sum + b.survivalRate);
      final avgRate = (totalRate / birthController.births.length).toStringAsFixed(1);
      survivalRate.value = '$avgRate%';
    } else {
      survivalRate.value = '0%';
    }

    // Conejas activas (reproductoras saludables)
    final activeList = rabbitController.rabbits
        .where((r) =>
            r.isBreeder &&
            r.healthStatus == 'Saludable' &&
            r.gender == 'Hembra')
        .toList();
    activeRabbits.assignAll(activeList);

    // Próximos partos esperados
    final upcoming = rabbitController.rabbits
        .where((r) => r.expectedBirthDate != null && r.expectedBirthDate!.isAfter(DateTime.now()))
        .toList();
    
    // Crear Birth objects simulados para mostrar en el banner
    final upcomingList = upcoming.map((r) {
      return Birth(
        id: r.id,
        motherId: r.id,
        birthDate: r.expectedBirthDate ?? DateTime.now(),
        litterSize: 0,
        averageWeight: 0,
      );
    }).toList();
    upcomingBirths.assignAll(upcomingList);
  }

  /// Generar alertas del sistema
  void generateAlerts() {
    int alertCount = 0;

    // Alerta: conejos enfermos
    final sickRabbits = rabbitController.rabbits
        .where((r) => r.healthStatus.contains('Tratamiento'))
        .length;
    alertCount += sickRabbits;

    // Alerta: conejos no alimentados recientemente (más de 2 días)
    final notFedRabbits = rabbitController.rabbits.where((r) {
      if (r.lastFeedingDate == null) return true;
      final daysSinceFeeding =
          DateTime.now().difference(r.lastFeedingDate!).inDays;
      return daysSinceFeeding > 2;
    }).length;
    alertCount += notFedRabbits;

    // Alerta: próximos partos en menos de 3 días
    final soonBirths = rabbitController.rabbits.where((r) {
      if (r.expectedBirthDate == null) return false;
      final daysUntilBirth = r.expectedBirthDate!.difference(DateTime.now()).inDays;
      return daysUntilBirth >= 0 && daysUntilBirth <= 3;
    }).length;
    alertCount += soonBirths;

    alerts.value = alertCount;
  }

  /// Obtener próximo parto esperado
  Rabbit? getNextExpectedBirth() {
    try {
      return rabbitController.rabbits
          .where((r) => r.expectedBirthDate != null && r.expectedBirthDate!.isAfter(DateTime.now()))
          .reduce((a, b) =>
              a.expectedBirthDate!.isBefore(b.expectedBirthDate!) ? a : b);
    } catch (e) {
      return null;
    }
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