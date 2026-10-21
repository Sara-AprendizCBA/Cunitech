// lib/models/insight_recomendacion.dart

/// Recomendación generada por IA (Edge Function `generate-insights`).
class InsightRecomendacion {
  final String titulo;
  final String detalle;
  final String prioridad; // 'alta' | 'media' | 'baja'
  final String impacto;

  const InsightRecomendacion({
    required this.titulo,
    required this.detalle,
    required this.prioridad,
    this.impacto = '',
  });

  factory InsightRecomendacion.fromJson(Map<String, dynamic> json) {
    final p = (json['prioridad'] ?? 'media').toString().toLowerCase();
    return InsightRecomendacion(
      titulo: json['titulo']?.toString() ?? '',
      detalle: json['detalle']?.toString() ?? '',
      prioridad: const ['alta', 'media', 'baja'].contains(p) ? p : 'media',
      impacto: json['impacto']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'detalle': detalle,
    'prioridad': prioridad,
    'impacto': impacto,
  };

  @override
  String toString() => 'InsightRecomendacion($prioridad: $titulo)';
}

/// Resultado completo del panel de IA: diagnóstico general + recomendaciones.
class InsightPanel {
  final String diagnosticoGeneral;
  final List<InsightRecomendacion> recomendaciones;

  const InsightPanel({
    required this.diagnosticoGeneral,
    required this.recomendaciones,
  });

  factory InsightPanel.fromJson(Map<String, dynamic> json) {
    final lista = json['recomendaciones'];
    final recomendaciones = lista is List
        ? lista
              .whereType<Map>()
              .map(
                (e) => InsightRecomendacion.fromJson(
                  e.cast<String, dynamic>(),
                ),
              )
              .where((r) => r.titulo.isNotEmpty && r.detalle.isNotEmpty)
              .toList()
        : <InsightRecomendacion>[];
    return InsightPanel(
      diagnosticoGeneral: json['diagnostico_general']?.toString() ?? '',
      recomendaciones: recomendaciones,
    );
  }

  static const empty = InsightPanel(
    diagnosticoGeneral: '',
    recomendaciones: <InsightRecomendacion>[],
  );

  bool get isEmpty => recomendaciones.isEmpty && diagnosticoGeneral.isEmpty;
}
