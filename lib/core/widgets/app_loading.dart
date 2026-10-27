import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppLoadingIndicator extends StatelessWidget {
  final String? label;

  const AppLoadingIndicator({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
          )
              .animate(onPlay: (controller) {
                controller.repeat(reverse: true);
              })
              .scale(
                begin: const Offset(0.92, 0.92),
                end: const Offset(1, 1),
                duration: 900.ms,
                curve: Curves.easeInOut,
              ),
          if (label != null) ...[
            const SizedBox(height: 14),
            Text(
              label!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AppLoadingList extends StatelessWidget {
  final int itemCount;
  final bool shrinkWrap;

  const AppLoadingList({
    super.key,
    this.itemCount = 4,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.cardTheme.color ?? theme.colorScheme.surface;
    final base = theme.colorScheme.onSurface.withValues(alpha: 0.06);
    final highlight = theme.colorScheme.onSurface.withValues(alpha: 0.14);

    final cards = List.generate(
      itemCount,
      (_) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            _ShimmerBlock(
              width: 48,
              height: 48,
              radius: 24,
              color: base,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBlock(
                    width: double.infinity,
                    height: 14,
                    radius: 7,
                    color: base,
                  ),
                  const SizedBox(height: 10),
                  _ShimmerBlock(
                    width: 140,
                    height: 11,
                    radius: 6,
                    color: base,
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(onPlay: (controller) {
            controller.repeat();
          })
          .shimmer(duration: 1200.ms, color: highlight),
    );

    if (shrinkWrap) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: cards,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Color color;

  const _ShimmerBlock({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
