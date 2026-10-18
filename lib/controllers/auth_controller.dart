import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/logger.dart';

class AuthController extends GetxController {
  final currentUser = Rxn<Map<String, dynamic>>();
  final currentRol = 'usuario'.obs;
  final isLoading = false.obs;

  StreamSubscription<AuthState>? _authSub;

  // Evitan recargas duplicadas/concurrentes del mismo usuario
  String? _loadingUserId;
  String? _loadedUserId;

  // ────── Getters por rol ──────

  bool get isAdmin => currentRol.value == 'admin';
  bool get isVeterinario => currentRol.value == 'veterinario';
  bool get isAyudante => currentRol.value == 'ayudante';
  bool get isUsuarioSinRol => currentRol.value == 'usuario';
  bool get isLoggedIn => Supabase.instance.client.auth.currentUser != null;

  // ────── Ciclo de vida ──────

  @override
  void onInit() {
    super.onInit();

    // Nos suscribimos antes de cargar: `onAuthStateChange` es un ReplaySubject,
    // así que reentrega el último evento (initialSession / tokenRefreshed) y no
    // perdemos eventos emitidos durante el arranque.
    _authSub =
        Supabase.instance.client.auth.onAuthStateChange.listen(_onAuthChange);

    loadCurrentUser();
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }

  void _onAuthChange(AuthState data) {
    switch (data.event) {
      case AuthChangeEvent.signedOut:
        _loadedUserId = null;
        _loadingUserId = null;
        currentUser.value = null;
        currentRol.value = 'usuario';
        break;

      // El login de este proyecto hace setSession(refreshToken), que dispara
      // `tokenRefreshed` (NO `signedIn`). Al arrancar con sesión persistida
      // llega `initialSession`. Ambos deben recargar el rol.
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
        if (data.session != null) {
          loadCurrentUser();
        }
        break;

      default:
        break;
    }
  }

  Future<void> loadCurrentUser() async {
    final authUser = Supabase.instance.client.auth.currentUser;

    if (authUser == null) {
      currentUser.value = null;
      currentRol.value = 'usuario';
      _loadedUserId = null;
      return;
    }

    // Nada que hacer si ya está cargado o cargándose este mismo usuario.
    if (_loadingUserId == authUser.id) return;
    if (_loadedUserId == authUser.id && currentUser.value != null) return;

    _loadingUserId = authUser.id;
    isLoading.value = true;
    try {
      final data = await Supabase.instance.client
          .from('usuario')
          .select('id_usuario, nombre, email, rol, activo')
          .eq('id_usuario', authUser.id)
          .single();

      currentUser.value = data;
      currentRol.value = data['rol'] as String? ?? 'usuario';
      _loadedUserId = authUser.id;
    } catch (e) {
      logger.e('Error loadCurrentUser', error: e);
      currentRol.value = 'usuario';
    } finally {
      isLoading.value = false;
      _loadingUserId = null;
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    currentUser.value = null;
    currentRol.value = 'usuario';
  }
}
