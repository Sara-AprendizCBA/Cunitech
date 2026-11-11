import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotification {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final IconDataType type;
  final String? rabbitId;

  const AppNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
    this.rabbitId,
  });
}

enum IconDataType { bell, health, reproduction, warning }

class NotificationController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxInt unreadCount = 0.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _rabbitSub;
  StreamSubscription<List<Map<String, dynamic>>>? _reproSub;

  @override
  void onInit() {
    super.onInit();
    _loadNotifications();
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
          .listen((_) => _loadNotifications());
    } catch (_) {}
    try {
      _reproSub = _supabase
          .from('reproduccion')
          .stream(primaryKey: ['id_reproduccion'])
          .listen((_) => _loadNotifications());
    } catch (_) {}
  }

  Future<void> _loadNotifications() async {
    final list = <AppNotification>[];

    try {
      final rows = await _supabase
          .from('conejo')
          .select('id_conejo, chapeta, estado, fecha_nacimiento')
          .neq('estado', 'Saludable')
          .limit(50);

      for (final row in rows) {
        final estado = (row['estado'] as String? ?? '').trim();
        final chapeta = (row['chapeta'] as String? ?? '').trim();
        if (estado.isEmpty) continue;
        final id = row['id_conejo']?.toString() ?? '';
        list.add(AppNotification(
          id: 'health_$id',
          title: 'Estado: $estado',
          subtitle:
              chapeta.isEmpty ? 'Un conejo requiere atencion' : '$chapeta requiere atencion',
          time: _formatTime(DateTime.now()),
          type: estado.toLowerCase().contains('enfermo')
              ? IconDataType.warning
              : IconDataType.health,
          rabbitId: id,
        ));
      }
    } catch (_) {
      // Sin datos: se mantiene la lista vacia.
    }

    notifications.value = list.take(20).toList();
    unreadCount.value = notifications.length;
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
