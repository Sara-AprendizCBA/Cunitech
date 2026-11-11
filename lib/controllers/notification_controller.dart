import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotification {
  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final AppNotificationType type;
  final String? entityId;

  const AppNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.type,
    this.entityId,
  });
}

enum AppNotificationType { health, reproduction, feeding, general }

/// Tipo de alerta generado por [NotificationController].
extension AppNotificationTypeX on AppNotificationType {
  String get label => switch (this) {
        AppNotificationType.health => 'Salud',
        AppNotificationType.reproduction => 'Reproducción',
        AppNotificationType.feeding => 'Alimentación',
        AppNotificationType.general => 'General',
      };
}

/// Gestiona las alertas del criadero y las mantiene sincronizadas con
/// Supabase Realtime (tablas `conejo` y `reproduccion`).
class NotificationController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _rabbitSub;
  StreamSubscription<List<Map<String, dynamic>>>? _reproSub;

  @override
  void onInit() {
    super.onInit();
    refreshNotifications();
    _subscribeRealtime();
  }

  @override
  void onClose() {
    _rabbitSub?.cancel();
    _reproSub?.cancel();
    super.onClose();
  }

  void _subscribeRealtime() {
    try {
      _rabbitSub = _supabase
          .from('conejo')
          .stream(primaryKey: ['id_conejo'])
          .listen((_) => refreshNotifications());
    } catch (_) {}
    try {
      _reproSub = _supabase
          .from('reproduccion')
          .stream(primaryKey: ['id_reproduccion'])
          .listen((_) => refreshNotifications());
    } catch (_) {}
  }

  Future<void> refreshNotifications() async {
    isLoading.value = true;
    final list = <AppNotification>[];
    final now = DateTime.now();

    await _collectHealthAlerts(list, now);
    await _collectReproductionAlerts(list, now);

    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifications.value = list.take(20).toList();
    unreadCount.value = notifications.length;
    isLoading.value = false;
  }

  Future<void> _collectHealthAlerts(
    List<AppNotification> list,
    DateTime now,
  ) async {
    try {
      final rows = await _supabase
          .from('conejo')
          .select('id_conejo, chapeta, estado')
          .neq('estado', 'Saludable')
          .limit(30);

      for (final row in rows) {
        final estado = (row['estado'] as String? ?? '').trim();
        if (estado.isEmpty) continue;
        final id = row['id_conejo']?.toString() ?? '';
        final chapeta = (row['chapeta'] as String? ?? '').trim();
        list.add(AppNotification(
          id: 'health_$id',
          title: 'Estado: $estado',
          subtitle: chapeta.isEmpty
              ? 'Un conejo requiere atención'
              : '$chapeta requiere atención',
          timestamp: now,
          type: estado.toLowerCase().contains('enfermo')
              ? AppNotificationType.health
              : AppNotificationType.general,
          entityId: id,
        ));
      }
    } catch (_) {
      // Si la consulta falla se conserva lo ya recolectado.
    }
  }

  Future<void> _collectReproductionAlerts(
    List<AppNotification> list,
    DateTime now,
  ) async {
    try {
      final rows = await _supabase
          .from('reproduccion')
          .select('id_reproduccion, estado, fecha_probable_parto, fecha_monta')
          .eq('estado', 'Gestante')
          .limit(30);

      for (final row in rows) {
        final id = row['id_reproduccion']?.toString() ?? '';
        final fecha = DateTime.tryParse(
            (row['fecha_probable_parto'] ?? row['fecha_monta'] ?? '').toString());
        if (fecha == null) continue;

        final dias = fecha.difference(now).inDays;
        if (dias > 7 || dias < -3) continue;

        list.add(AppNotification(
          id: 'repro_$id',
          title: dias >= 0 ? 'Parto próximo' : 'Parto atrasado',
          subtitle: dias >= 0
              ? 'Parto estimado en $dias día${dias == 1 ? '' : 's'}'
              : 'Parto estimado hace ${-dias} día${dias == -1 ? '' : 's'}',
          timestamp: fecha,
          type: AppNotificationType.reproduction,
          entityId: id,
        ));
      }
    } catch (_) {
      // Si la consulta falla se conserva lo ya recolectado.
    }
  }
}
