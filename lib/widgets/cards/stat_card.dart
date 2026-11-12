import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool isNegative;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    // En celular la tarjeta se compacta: padding, icono y numeros mas
    // pequenos para que no se vea una caja gigante.
    final isMobile = context.isMobile;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 28),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: isMobile ? 22 : 32, color: color),
          ),

          SizedBox(height: isMobile ? 12 : 32),

          // Value
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 22 : 36,
                  height: 1.0,
                ),
          ),

          SizedBox(height: isMobile ? 4 : 8),

          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: isMobile ? 13 : null,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Trend
          if (trend != null) ...[
            SizedBox(height: isMobile ? 8 : 16),
            Row(
              children: [
                Icon(
                  isNegative ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                  size: isMobile ? 14 : 16,
                  color: isNegative ? AppTheme.danger : AppTheme.success,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trend!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: isNegative ? AppTheme.danger : AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scaleXY(
          begin: 0.96,
          end: 1.0,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
