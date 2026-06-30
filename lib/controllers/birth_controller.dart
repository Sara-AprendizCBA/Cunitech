import 'package:get/get.dart';
import '../models/birth.dart';
import '../services/birth_service.dart';

class BirthController extends GetxController {
  final BirthService _birthService = BirthService();

  // Observables
  final births = <Birth>[].obs;
  final recentBirths = <Birth>[].obs;
  final isLoading = false.obs;
  final error = Rxn<String>();
  final stats = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllBirths();
    loadRecentBirths();
    loadReproductionStats();
  }

  /// Cargar todos los partos
  Future<void> loadAllBirths() async {
    try {
      isLoading(true);
      error(null);
      final data = await _birthService.getAllBirths();
      births.assignAll(data);
    } catch (e) {
      error('Error cargando partos: $e');
      print('Error: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Cargar partos recientes
  Future<void> loadRecentBirths({int days = 30}) async {
    try {
      isLoading(true);
      error(null);
      final data = await _birthService.getRecentBirths(days: days);
      recentBirths.assignAll(data);
    } catch (e) {
      error('Error cargando partos recientes: $e');
      print('Error: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Cargar partos por madre
  Future<List<Birth>> getBirthsByMother(String motherId) async {
    try {
      return await _birthService.getBirthsByMother(motherId);
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  /// Cargar estadísticas de reproducción
  Future<void> loadReproductionStats() async {
    try {
      final data = await _birthService.getReproductionStats();
      stats.assignAll(data);
    } catch (e) {
      print('Error loading reproduction stats: $e');
    }
  }

  /// Crear parto
  Future<void> createBirth(Birth birth) async {
    try {
      isLoading(true);
      error(null);
      final newBirth = await _birthService.createBirth(birth);
      births.add(newBirth);
      await loadRecentBirths();
      await loadReproductionStats();
      Get.back();
      Get.snackbar('Éxito', 'Parto registrado correctamente',
          snackPosition: SnackPosition.TOP);
    } catch (e) {
      error('Error creando parto: $e');
      Get.snackbar('Error', 'No se pudo registrar el parto',
          snackPosition: SnackPosition.TOP);
      print('Error: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Actualizar parto
  Future<void> updateBirth(String id, Birth birth) async {
    try {
      isLoading(true);
      error(null);
      final updated = await _birthService.updateBirth(id, birth);
      final index = births.indexWhere((b) => b.id == id);
      if (index != -1) {
        births[index] = updated;
      }
      await loadReproductionStats();
      Get.back();
      Get.snackbar('Éxito', 'Parto actualizado correctamente',
          snackPosition: SnackPosition.TOP);
    } catch (e) {
      error('Error actualizando parto: $e');
      Get.snackbar('Error', 'No se pudo actualizar el parto',
          snackPosition: SnackPosition.TOP);
      print('Error: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Eliminar parto
  Future<void> deleteBirth(String id) async {
    try {
      isLoading(true);
      error(null);
      await _birthService.deleteBirth(id);
      births.removeWhere((b) => b.id == id);
      await loadReproductionStats();
      Get.snackbar('Éxito', 'Parto eliminado correctamente',
          snackPosition: SnackPosition.TOP);
    } catch (e) {
      error('Error eliminando parto: $e');
      Get.snackbar('Error', 'No se pudo eliminar el parto',
          snackPosition: SnackPosition.TOP);
      print('Error: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Obtener parto por ID
  Birth? getBirthById(String id) {
    try {
      return births.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtener tasa de supervivencia promedio
  String getAverageSurvivalRate() {
    if (births.isEmpty) return '0%';
    final total = births.fold<int>(0, (sum, b) => sum + b.survivalRate);
    return '${(total / births.length).toStringAsFixed(1)}%';
  }

  /// Obtener próximos partos esperados
  List<Birth> getUpcomingBirths() {
    // Esto requeriría datos de matings con expected_birth_date
    return [];
  }
}