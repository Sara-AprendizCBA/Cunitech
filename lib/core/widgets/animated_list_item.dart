import 'package:flutter/material.dart';

class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;

  const AnimatedListItem({
    super.key,
    required this.child,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    const baseMs = 320;
    final delayMs = (index > 8 ? 8 : index) * 35;
    final totalMs = baseMs + delayMs;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: totalMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final progress = delayMs == 0
            ? value
            : ((value * totalMs - delayMs) / baseMs).clamp(0.0, 1.0);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
