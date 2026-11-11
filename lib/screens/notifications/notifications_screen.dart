import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifications = <_NotificationItem>[];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notificaciones',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: notifications.isEmpty
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 30,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        'Sin notificaciones',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        'Los avisos de tu criadero aparecerán aquí.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560, maxHeight: 400),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: ListView.builder(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                            child: _NotificationCard(
                              icon: item.icon,
                              title: item.title,
                              subtitle: item.subtitle,
                              time: item.time,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _NotificationItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? time;

  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, size: 20, color: AppTheme.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (time != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          time!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
