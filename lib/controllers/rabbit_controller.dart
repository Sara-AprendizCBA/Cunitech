import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  Future<bool> createRabbit(Rabbit rabbit) async {
    try {
      isLoading(true);
      error(null);
      final newRabbit = await _rabbitService.createRabbit(rabbit);
      rabbits.add(newRabbit);
      return true;
    } catch (e) {
      error('Error creando conejo: $e');
      print('Error: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Actualizar conejo
  Future<bool> updateRabbit(String id, Rabbit rabbit) async {
    try {
      isLoading(true);
      error(null);
      final updated = await _rabbitService.updateRabbit(id, rabbit);
      final index = rabbits.indexWhere((r) => r.id == id);
      if (index != -1) {
        rabbits[index] = updated;
      }
      return true;
    } catch (e) {
      error('Error actualizando conejo: $e');
      print('Error: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Eliminar conejo
  Future<bool> deleteRabbit(String id) async {
    try {
      isLoading(true);
      error(null);
      await _rabbitService.deleteRabbit(id);
      rabbits.removeWhere((r) => r.id == id);
      return true;
    } on PostgrestException catch (e) {
      // 23503 = tiene registros relacionados (lactancia, reproducción,
      // tratamiento, o es madre/padre de otro conejo)
      error('Error eliminando conejo: ${e.message}');
      print('Error: $e');
      return false;
    } catch (e) {
      error('Error eliminando conejo: $e');
      print('Error: $e');
      return false;
    } finally {
      isLoading(false);
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
        .where(
          (r) =>
              r.displayId.toLowerCase().contains(query.toLowerCase()) ||
              r.id.toLowerCase().contains(query.toLowerCase()) ||
              r.breed.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}
