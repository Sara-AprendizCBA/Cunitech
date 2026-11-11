import 'package:flutter/material.dart';

/// Indicador de carga con el conejo de CUNITECH saltando.
///
/// Pensado para estados de carga de pantalla completa o de listados.
class LoadingRabbit extends StatefulWidget {
  final double size;
  final String? label;

  const LoadingRabbit({super.key, this.size = 110, this.label});

  @override
  State<LoadingRabbit> createState() => _LoadingRabbitState();
}

class _LoadingRabbitState extends State<LoadingRabbit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounce;
  late final Animation<double> _squash;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _squash = Tween<double>(begin: 1, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Cargando',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _bounce.value),
                  child: Transform.scale(
                    scaleX: _squash.value,
                    scaleY: 2 - _squash.value,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/images/logo_cunitech.png',
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
              ),
            ),
            if (widget.label != null) ...[
              const SizedBox(height: 16),
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
