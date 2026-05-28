import 'package:flutter/material.dart';
import '../../models/mating.dart';
import '../../core/theme/app_theme.dart';

class BreedingCard extends StatelessWidget {
  final Mating mating;

  const BreedingCard({super.key, required this.mating});

  @override
  Widget build(BuildContext context) {
    final daysToBirth = mating.expectedBirthDate != null
        ? mating.expectedBirthDate!.difference(DateTime.now()).inDays
        : null;

    final bool isUrgent = daysToBirth != null && daysToBirth <= 7;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 32,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(width: 24),

                // Main Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Monta ${mating.id}",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          _StatusChip(status: mating.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Coneja: ${mating.doeId}   •   Macho: ${mating.buckId}",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      if (daysToBirth != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.event_rounded,
                              size: 18,
                              color: isUrgent ? AppTheme.danger : AppTheme.accent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Parto estimado: en $daysToBirth días",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isUrgent ? AppTheme.danger : AppTheme.accent,
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
            ? AppTheme.accent.withOpacity(0.1)
            : AppTheme.info.withOpacity(0.1),
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