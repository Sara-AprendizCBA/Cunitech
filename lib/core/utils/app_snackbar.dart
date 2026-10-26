import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum SnackType { success, error, warning, info }

class AppSnackbar {
  static void _show(
    BuildContext context,
    String message,
    SnackType type, {
    Duration? duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    final (Color bg, IconData icon) = switch (type) {
      SnackType.success => (
          AppTheme.successDark,
          Icons.check_circle_outline,
        ),
      SnackType.error => (
          AppTheme.dangerDark,
          Icons.error_outline,
        ),
      SnackType.warning => (
          AppTheme.warningDark,
          Icons.warning_amber_outlined,
        ),
      SnackType.info => (
          AppTheme.infoDark,
          Icons.info_outline,
        ),
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Material(
                color: bg,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(20),
          padding: EdgeInsets.zero,
          duration: duration ?? const Duration(seconds: 3),
          elevation: 0,
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
