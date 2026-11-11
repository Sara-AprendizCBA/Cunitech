import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Indicador de carga con un conejo café dibujado desde cero.
///
/// Salta, aplica squash & stretch y proyecta una sombra que cambia
/// según la altura del salto.
class LoadingRabbit extends StatefulWidget {
  final double size;
  final String? label;

  const LoadingRabbit({super.key, this.size = 100, this.label});

  @override
  State<LoadingRabbit> createState() => _LoadingRabbitState();
}

class _LoadingRabbitState extends State<LoadingRabbit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = widget.size;

    return Semantics(
      label: 'Cargando',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final t = _controller.value;
                  // 0 en el suelo, 1 en el punto más alto.
                  final lift = math.sin(math.pi * t);
                  final grounded = 1 - lift;

                  // Squash al tocar el suelo, stretch en el aire.
                  final scaleX = 1 + 0.045 * grounded - 0.05 * lift;
                  final scaleY = 1 - 0.045 * grounded + 0.06 * lift;

                  final shadowScale = 1 - 0.35 * lift;
                  final shadowOpacity = 0.18 - 0.08 * lift;

                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        bottom: size * 0.02,
                        child: Transform.scale(
                          scaleX: shadowScale,
                          scaleY: shadowScale,
                          child: Container(
                            width: size * 0.46,
                            height: size * 0.11,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(
                                alpha: shadowOpacity,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, -lift * size * 0.22),
                        child: Transform.scale(
                          scaleX: scaleX,
                          scaleY: scaleY,
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            width: size,
                            height: size,
                            child: const CustomPaint(
                              painter: _RabbitPainter(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (widget.label != null) ...[
              const SizedBox(height: 14),
              Text(
                widget.label!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RabbitPainter extends CustomPainter {
  const _RabbitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fur = Paint()..color = AppTheme.accent;
    final furDark = Paint()..color = const Color(0xFF7E5F45);
    final belly = Paint()..color = const Color(0xFFE3CDB6);
    final innerEar = Paint()..color = const Color(0xFFF0D9C3);
    final ink = Paint()..color = const Color(0xFF3B2416);
    final highlight = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final cheek = Paint()..color = const Color(0xFFE8BFA6);

    // Cola.
    canvas.drawCircle(Offset(w * 0.19, h * 0.67), w * 0.075, belly);

    // Patas.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.38, h * 0.86),
        width: w * 0.20,
        height: h * 0.10,
      ),
      furDark,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.62, h * 0.86),
        width: w * 0.20,
        height: h * 0.10,
      ),
      furDark,
    );

    // Orejas (detrás de la cabeza).
    _drawEar(canvas, size, Offset(w * 0.42, h * 0.20), -0.22, fur, innerEar);
    _drawEar(canvas, size, Offset(w * 0.62, h * 0.19), 0.22, fur, innerEar);

    // Cuerpo.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.52, h * 0.67),
        width: w * 0.64,
        height: h * 0.45,
      ),
      fur,
    );

    // Panza.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.52, h * 0.72),
        width: w * 0.34,
        height: h * 0.24,
      ),
      belly,
    );

    // Cabeza.
    canvas.drawCircle(Offset(w * 0.53, h * 0.42), w * 0.20, fur);

    // Mejillas.
    canvas.drawCircle(Offset(w * 0.44, h * 0.47), w * 0.045, cheek);
    canvas.drawCircle(Offset(w * 0.62, h * 0.47), w * 0.045, cheek);

    // Ojos.
    canvas.drawCircle(Offset(w * 0.46, h * 0.40), w * 0.021, ink);
    canvas.drawCircle(Offset(w * 0.60, h * 0.40), w * 0.021, ink);
    canvas.drawCircle(Offset(w * 0.465, h * 0.394), w * 0.007, highlight);
    canvas.drawCircle(Offset(w * 0.605, h * 0.394), w * 0.007, highlight);

    // Nariz.
    final nose = Path()
      ..moveTo(w * 0.53, h * 0.455)
      ..lineTo(w * 0.515, h * 0.47)
      ..lineTo(w * 0.545, h * 0.47)
      ..close();
    canvas.drawPath(nose, ink);

    // Boca.
    canvas.drawLine(
      Offset(w * 0.53, h * 0.47),
      Offset(w * 0.53, h * 0.49),
      ink,
    );
  }

  void _drawEar(
    Canvas canvas,
    Size size,
    Offset center,
    double angle,
    Paint fur,
    Paint innerEar,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width * 0.14,
        height: size.height * 0.34,
      ),
      fur,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, size.height * 0.01),
        width: size.width * 0.07,
        height: size.height * 0.22,
      ),
      innerEar,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
