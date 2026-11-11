import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'loading_rabbit.dart';

class AppLoadingIndicator extends StatelessWidget {
  final String? label;
  final double size;

  const AppLoadingIndicator({super.key, this.label, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return LoadingRabbit(size: size, label: label);
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
