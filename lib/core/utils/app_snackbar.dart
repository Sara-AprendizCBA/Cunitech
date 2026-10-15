import 'package:flutter/material.dart';

enum SnackType { success, error, warning, info }

class AppSnackbar {
  static void _show(
    BuildContext context,
    String message,
    SnackType type, {
    Duration? duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    final (Color bg, Color fg, Color iconBg, IconData icon) = switch (type) {
      SnackType.success => (
          const Color(0xFF1F2937),
          Colors.white,
          const Color(0xFF10B981),
          Icons.check_circle_rounded,
        ),
      SnackType.error => (
          const Color(0xFF1F2937),
          Colors.white,
          const Color(0xFFEF4444),
          Icons.error_rounded,
        ),
      SnackType.warning => (
          const Color(0xFF1F2937),
          Colors.white,
          const Color(0xFFF59E0B),
          Icons.warning_amber_rounded,
        ),
      SnackType.info => (
          const Color(0xFF1F2937),
          Colors.white,
          const Color(0xFF3B82F6),
          Icons.info_rounded,
        ),
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: fg,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          duration: duration ??
              (type == SnackType.error
                  ? const Duration(seconds: 5)
                  : const Duration(seconds: 3)),
          elevation: 6,
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      _show(context, message, SnackType.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, SnackType.error);

  static void warning(BuildContext context, String message) =>
      _show(context, message, SnackType.warning);

  static void info(BuildContext context, String message) =>
      _show(context, message, SnackType.info);
}
