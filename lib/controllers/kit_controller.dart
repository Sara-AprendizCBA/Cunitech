import 'package:get/get.dart';
import '../models/kit.dart';
import '../services/kit_service.dart';

class KitController extends GetxController {
  final KitService _kitService = KitService();

  // Observables
  final kits = <Kit>[].obs;
  final isLoading = false.obs;
  final error = Rxn<String>();
  final stats = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllKits();
    loadStats();
  }

  /// Cargar todas las crías
  Future<void> loadAllKits() async {
    try {
      isLoading(true);
      error(null);
      final data = await _kitService.getAllKits();
      kits.assignAll(data);
    } catch (e) {
      error('Error cargando crías: $e');
      print('Error: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Cargar estadísticas de crías
  Future<void> loadStats() async {
    try {
      final data = await _kitService.getKitsStats();
      stats.assignAll(data);
    } catch (e) {
      print('Error loading kits stats: $e');
    }
  }

  /// Cargar crías por madre
  Future<List<Kit>> getKitsByMother(String motherId) async {
    try {
      return await _kitService.getKitsByMother(motherId);
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  /// Crear cría
  Future<void> createKit(Kit kit) async {
    try {
      isLoading(true);
      error(null);
      final newKit = await _kitService.createKit(kit);
      kits.add(newKit);
      await loadStats();
      Get.snackbar('Éxito', 'Cría registrada correctamente',
          snackPosition: SnackPosition.TOP);
    } catch (e) {
      error('Error creando cría: $e');
      Get.snackbar('Error', 'No se pudo registrar la cría',
          snackPosition: SnackPosition.TOP);
      print('Error: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Actualizar cría
  Future<void> updateKit(String id, Kit kit) async {
    try {
      isLoading(true);
      error(null);
      final updated = await _kitService.updateKit(id, kit);
      final index = kits.indexWhere((k) => k.id == id);
      if (index != -1) {
        kits[index] = updated;
      }
      await loadStats();
      Get.snackbar('Éxito', 'Cría actualizada correctamente',
          snackPosition: SnackPosition.TOP);
    } catch (e) {
      error('Error actualizando cría: $e');
      Get.snackbar('Error', 'No se pudo actualizar la cría',
          snackPosition: SnackPosition.TOP);
      print('Error: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Eliminar cría
  Future<void> deleteKit(String id) async {
    try {
      isLoading(true);
      error(null);
      await _kitService.deleteKit(id);
      kits.removeWhere((k) => k.id == id);
      await loadStats();
      Get.snackbar('Éxito', 'Cría eliminada correctamente',
          snackPosition: SnackPosition.TOP);
    } catch (e) {
      error('Error eliminando cría: $e');
      Get.snackbar('Error', 'No se pudo eliminar la cría',
          snackPosition: SnackPosition.TOP);
      print('Error: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Actualizar peso
  Future<void> updateWeight(String kitId, double newWeight) async {
    try {
      await _kitService.updateWeight(kitId, newWeight);
      final kit = kits.firstWhere((k) => k.id == kitId);
      final index = kits.indexOf(kit);
      kits[index] = kit.copyWith(currentWeight: newWeight);
      await loadStats();
      Get.snackbar('Éxito', 'Peso actualizado',
          snackPosition: SnackPosition.TOP);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar el peso',
          snackPosition: SnackPosition.TOP);
      print('Error: $e');
    }
  }

  /// Marcar como destetada
  Future<void> markAsWeaned(String kitId) async {
    try {
      await _kitService.markAsWeaned(kitId);
      final kit = kits.firstWhere((k) => k.id == kitId);
      final index = kits.indexOf(kit);
      kits[index] = kit.copyWith(weaningDate: DateTime.now());
      Get.snackbar('Éxito', 'Cría marcada como destetada',
          snackPosition: SnackPosition.TOP);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo marcar como destetada',
          snackPosition: SnackPosition.TOP);
      print('Error: $e');
    }
  }

  /// Obtener cría por ID
  Kit? getKitById(String id) {
    try {
      return kits.firstWhere((k) => k.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtener crías no destetadas
  List<Kit> getNotWeanedKits() {
    return kits.where((k) => k.weaningDate == null).toList();
  }
}