import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/rabbit.dart';
import 'rabbit_controller.dart';

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
  final RabbitController _rabbitController = Get.find<RabbitController>();

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

  void _loadNotifications() {
    final list = <AppNotification>[];
    final rabbits = _rabbitController.rabbits;

    for (final r in rabbits) {
      if ((r.healthStatus).toLowerCase() == 'enfermo') {
        list.add(AppNotification(
          id: 'health_${r.id}',
          title: 'Conejo enfermo',
          subtitle: '${r.displayId} requiere atención',
          time: _formatTime(DateTime.now()),
          type: IconDataType.health,
          rabbitId: r.id,
        ));
      }
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
