import 'package:flutter/material.dart';

/// Da feedback táctil a cualquier widget (FAB, botones, tarjetas) reduciendo
/// su escala mientras el puntero está presionado, sin robar el gesto al hijo.
class PressableScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;
  final bool enabled;

  const PressableScale({
    super.key,
    required this.child,
    this.pressedScale = 0.94,
    this.enabled = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || !widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
