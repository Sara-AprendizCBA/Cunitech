import 'package:flutter/material.dart';
import '../../models/mating.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

class BreedingCard extends StatelessWidget {
  final Mating mating;

  const BreedingCard({super.key, required this.mating});

  @override
  Widget build(BuildContext context) {
    final daysToBirth = mating.expectedBirthDate?.difference(DateTime.now()).inDays;

    final bool isUrgent = daysToBirth != null && daysToBirth <= 7;
    // En celular la tarjeta se compacta (padding e icono mas pequenos).
    final isMobile = context.isMobile;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 10 : 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 24),
            child: Row(
              children: [
                // Icon
                Container(
                  width: isMobile ? 44 : 64,
                  height: isMobile ? 44 : 64,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    size: isMobile ? 22 : 32,
                    color: AppTheme.accent,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 24),

                // Main Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Monta ${mating.id}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: isMobile ? 15 : null,
                                  ),
                            ),
                          ),
                          _StatusChip(status: mating.status),
                        ],
                      ),
                      SizedBox(height: isMobile ? 8 : 12),
                      Text(
                        "Coneja: ${mating.doeId}   •   Macho: ${mating.buckId}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: isMobile ? 12 : null,
                            ),
                      ),
                      if (daysToBirth != null) ...[
                        SizedBox(height: isMobile ? 8 : 12),
                        Row(
                          children: [
                            Icon(
                              Icons.event_rounded,
                              size: isMobile ? 16 : 18,
                              color: isUrgent ? AppTheme.danger : AppTheme.accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Parto estimado: en $daysToBirth días",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isMobile ? 12 : 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isUrgent ? AppTheme.danger : AppTheme.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Action
                Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: AppTheme.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isGestation = status.toLowerCase().contains("gestación");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isGestation
            ? AppTheme.accent.withValues(alpha: 0.1)
            : AppTheme.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isGestation ? AppTheme.accent : AppTheme.info,
        ),
      ),
    );
  }
}
