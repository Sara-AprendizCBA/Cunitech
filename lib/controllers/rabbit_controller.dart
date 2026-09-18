import 'package:get/get.dart';
import '../models/rabbit.dart';
import '../services/rabbit_service.dart';

class RabbitController extends GetxController {
  final RabbitService _rabbitService = RabbitService();

  // Observables
  final rabbits = <Rabbit>[].obs;
  final breeders = <Rabbit>[].obs;
  final isLoading = false.obs;
  final error = Rxn<String>();
  final stats = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllRabbits();
    loadStatistics();
  }

  /// Cargar todos los conejos
  Future<void> loadAllRabbits() async {
    try {
      isLoading(true);
      error(null);
      final data = await _rabbitService.getAllRabbits();
      rabbits.assignAll(data);
    } catch (e) {
      error('Error cargando conejos: $e');
      print('Error: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Cargar conejas reproductoras
  Future<void> loadBreeders() async {
    try {
      isLoading(true);
      error(null);
      final data = await _rabbitService.getBreedersOnly();
      breeders.assignAll(data);
    } catch (e) {
      error('Error cargando reproductoras: $e');
      print('Error: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Cargar estadísticas
  Future<void> loadStatistics() async {
    try {
      final data = await _rabbitService.getStatistics();
      stats.assignAll(data);
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  /// Crear conejo
  Future<void> createRabbit(Rabbit rabbit) async {
    try {
      isLoading(true);
      error(null);
      final newRabbit = await _rabbitService.createRabbit(rabbit);
      rabbits.add(newRabbit);
      Get.snackbar('Éxito', 'Conejo creado correctamente',
          snackPosition: SnackPosition.TOP);
    } catch (e) {
      error('Error creando conejo: $e');
      Get.snackbar('Error', 'No se pudo crear el conejo',
          snackPosition: SnackPosition.TOP);
      print('Error: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Actualizar conejo
  Future<void> updateRabbit(String id, Rabbit rabbit) async {
    try {
      isLoading(true);
      error(null);
      final updated = await _rabbitService.updateRabbit(id, rabbit);
      final index = rabbits.indexWhere((r) => r.id == id);
      if (index != -1) {
        rabbits[index] = updated;
      }
      Get.snackbar('Éxito', 'Conejo actualizado correctamente',
          snackPosition: SnackPosition.TOP);
    } catch (e) {
      error('Error actualizando conejo: $e');
      Get.snackbar('Error', 'No se pudo actualizar el conejo',
          snackPosition: SnackPosition.TOP);
      print('Error: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Eliminar conejo
  Future<void> deleteRabbit(String id) async {
    try {
      isLoading(true);
      error(null);
      await _rabbitService.deleteRabbit(id);
      rabbits.removeWhere((r) => r.id == id);
      Get.snackbar('Éxito', 'Conejo eliminado correctamente',
          snackPosition: SnackPosition.TOP);
    } catch (e) {
      error('Error eliminando conejo: $e');
      Get.snackbar('Error', 'No se pudo eliminar el conejo',
          snackPosition: SnackPosition.TOP);
      print('Error: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Registrar alimentación
  Future<void> recordFeeding(String rabbbitId) async {
    try {
      await _rabbitService.updateLastFeeding(rabbbitId);
      // Recargar datos
      await loadAllRabbits();
      Get.snackbar('Éxito', 'Alimentación registrada',
          snackPosition: SnackPosition.TOP);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo registrar la alimentación',
          snackPosition: SnackPosition.TOP);
      print('Error: $e');
    }
  }

  /// Registrar tratamiento
  Future<void> recordTreatment(String rabbbitId) async {
    try {
      await _rabbitService.updateLastTreatment(rabbbitId);
      // Recargar datos
      await loadAllRabbits();
      Get.snackbar('Éxito', 'Tratamiento registrado',
          snackPosition: SnackPosition.TOP);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo registrar el tratamiento',
          snackPosition: SnackPosition.TOP);
      print('Error: $e');
    }
  }

  /// Obtener conejo por ID
  Rabbit? getRabbitById(String id) {
    try {
      return rabbits.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Filtrar conejos por salud
  List<Rabbit> filterByHealth(String health) {
    return rabbits.where((r) => r.healthStatus == health).toList();
  }

  /// Buscar conejos
  List<Rabbit> searchRabbits(String query) {
    return rabbits
        .where((r) =>
            r.name.toLowerCase().contains(query.toLowerCase()) ||
            r.id.toLowerCase().contains(query.toLowerCase()) ||
            r.breed.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}