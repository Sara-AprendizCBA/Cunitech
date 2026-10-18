import 'package:get/get.dart';

import '../core/utils/logger.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';

class UserController extends GetxController {
  final _service = UserService();

  final users = <UserProfile>[].obs;
  final isLoading = false.obs;

  // Filtros
  final searchQuery = ''.obs;
  final rolFilter = 'todos'.obs;

  // ────── Getters derivados ──────

  List<UserProfile> get filteredUsers {
    var list = users.toList();
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      list = list
          .where((u) =>
              u.nombre.toLowerCase().contains(q) ||
              (u.email?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    if (rolFilter.value != 'todos') {
      list = list.where((u) => u.rol == rolFilter.value).toList();
    }
    return list;
  }

  // Stats
  int get totalUsers => users.length;
  int get totalAdmins => users.where((u) => u.esAdmin).length;
  int get totalVeterinarios => users.where((u) => u.esVeterinario).length;
  int get totalAyudantes => users.where((u) => u.esAyudante).length;
  int get totalSinRol => users.where((u) => u.esUsuario).length;

  // ────── Ciclo de vida ──────

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      users.assignAll(await _service.getAll());
    } catch (e) {
      logger.e('Error loadAll usuarios', error: e);
    } finally {
      isLoading.value = false;
    }
  }

  // ────── Acciones ──────

  Future<bool> cambiarRol(String idUsuario, String nuevoRol) async {
    final ok = await _service.updateRol(idUsuario, nuevoRol);
    if (ok) await loadAll();
    return ok;
  }

  Future<bool> toggleActivo(String idUsuario, bool activo) async {
    final ok = await _service.updateActivo(idUsuario, activo);
    if (ok) await loadAll();
    return ok;
  }

  Future<bool> eliminarUsuario(String idUsuario) async {
    final ok = await _service.deleteUser(idUsuario);
    if (ok) await loadAll();
    return ok;
  }

  Future<bool> crearUsuario({
    required String email,
    required String password,
    required String nombre,
    required String rol,
  }) async {
    try {
      final ok = await _service.createUser(
        email: email,
        password: password,
        nombre: nombre,
        rol: rol,
      );
      if (ok) await loadAll();
      return ok;
    } on UnimplementedError {
      // La Edge Function aún no está lista
      return false;
    } catch (e) {
      logger.e('Error crearUsuario', error: e);
      return false;
    }
  }

  // ────── Filtros ──────

  void setSearch(String q) => searchQuery.value = q;
  void setRolFilter(String r) => rolFilter.value = r;
  void clearFilters() {
    searchQuery.value = '';
    rolFilter.value = 'todos';
  }
}
