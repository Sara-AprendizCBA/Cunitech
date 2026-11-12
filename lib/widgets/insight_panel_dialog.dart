import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_loading.dart';
import '../../models/insight_recomendacion.dart';
import '../../services/insight_service.dart';
import '../../services/tts_service.dart';

/// Panel holográfico de CUNITECH Insight.
///
/// Incluye un botón de voz que lee en voz alta el diagnóstico y las
/// recomendaciones de la IA.
class InsightPanelDialog extends StatefulWidget {
  /// Servicio de insights. Se puede inyectar uno propio (pruebas).
  final InsightService? service;

  const InsightPanelDialog({super.key, this.service});

  @override
  State<InsightPanelDialog> createState() => _InsightPanelDialogState();
}

class _InsightPanelDialogState extends State<InsightPanelDialog> {
  late final Future<InsightPanel> _panelFuture;
  InsightPanel _panel = InsightPanel.empty;

  @override
  void initState() {
    super.initState();
    _panelFuture = (widget.service ?? InsightService()).obtenerRecomendaciones();
  }

  @override
  void dispose() {
    // Si el usuario cierra el panel mientras suena, se corta la voz.
    TtsService.instance.detener();
    super.dispose();
  }

  /// Texto que se lee en voz alta: diagnóstico + recomendaciones.
  String get _textoParaLeer {
    final partes = <String>[];
    if (_panel.diagnosticoGeneral.isNotEmpty) {
      partes.add(_panel.diagnosticoGeneral);
    }
    for (final r in _panel.recomendaciones) {
      partes.add('${r.titulo}. ${r.detalle}');
    }
    return partes.join(' ');
  }

  Future<void> _alternarVoz() async {
    final tts = TtsService.instance;
    if (tts.hablando.value) {
      await tts.detener();
      return;
    }
    await tts.hablar(_textoParaLeer);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: MediaQuery.of(context).size.height - 40,
            ),
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                        color: AppTheme.accentLight.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: AppTheme.accentLight,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'CUNITECH Insight',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            _buildBotonVoz(),
                            IconButton(
                              tooltip: 'Cerrar',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppTheme.accentLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Flexible(
                          child: SingleChildScrollView(
                            child: FutureBuilder<InsightPanel>(
                              future: _panelFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const AppLoadingIndicator(
                                    size: 64,
                                    label: 'Analizando recomendaciones…',
                                  );
                                }
                                if (snapshot.hasError ||
                                    !snapshot.hasData ||
                                    snapshot.data!.recomendaciones.isEmpty) {
                                  return const Text(
                                    'No hay recomendaciones disponibles.',
                                    style: TextStyle(color: Colors.white70),
                                  );
                                }
                                final panel = snapshot.data!;
                                _panel = panel;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (panel.diagnosticoGeneral.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Text(
                                          panel.diagnosticoGeneral,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ...panel.recomendaciones.map(
                                      (r) => _buildInsightCard(r),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Botón de voz: reproduce o detiene la lectura del análisis.
  Widget _buildBotonVoz() {
    return ValueListenableBuilder<bool>(
      valueListenable: TtsService.instance.hablando,
      builder: (context, hablando, _) {
        return IconButton(
          tooltip: hablando ? 'Detener lectura' : 'Leer en voz alta',
          onPressed: _alternarVoz,
          icon: Icon(
            hablando ? Icons.stop_rounded : Icons.volume_up_rounded,
            color: AppTheme.accentLight,
          ),
        );
      },
    );
  }

  Widget _buildInsightCard(InsightRecomendacion r) {
    final prioridad = r.prioridad.toLowerCase();
    final color = prioridad == 'alta'
        ? Colors.redAccent
        : prioridad == 'media'
            ? Colors.orangeAccent
            : Colors.greenAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  r.prioridad.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            r.detalle,
            style: const TextStyle(color: Colors.white70),
          ),
          if (r.impacto.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              r.impacto,
              style: TextStyle(
                color: color,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
