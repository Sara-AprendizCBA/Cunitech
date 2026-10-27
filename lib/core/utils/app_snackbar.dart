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
                elevation: 10,
                shadowColor: bg.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.white, size: 18),
                      ),
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
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: messenger.hideCurrentSnackBar,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        visualDensity: VisualDensity.compact,
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
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          padding: EdgeInsets.zero,
          duration: duration ?? const Duration(seconds: 3),
          elevation: 0,
          dismissDirection: DismissDirection.horizontal,
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
