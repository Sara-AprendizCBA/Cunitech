import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

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
    return Container(
      padding: const EdgeInsets.all(28),
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 32, color: color),
          ),

          const SizedBox(height: 32),

          // Value
          Text(
            value,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 36,
                  height: 1.0,
                ),
          ),

          const SizedBox(height: 8),

          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Trend
          if (trend != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  isNegative ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                  size: 16,
                  color: isNegative ? AppTheme.danger : AppTheme.success,
                ),
                const SizedBox(width: 6),
                Text(
                  trend!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isNegative ? AppTheme.danger : AppTheme.success,
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