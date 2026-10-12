class MetaMensual {
  final String? id;
  final String? userId;
  final int anio;
  final int mes;
  final String kpi;
  final double valorObjetivo;
  final String unidad;
  final String prioridad;
  final String? notas;

  const MetaMensual({
    this.id,
    this.userId,
    required this.anio,
    required this.mes,
    required this.kpi,
    required this.valorObjetivo,
    required this.unidad,
    this.prioridad = 'media',
    this.notas,
  });

  factory MetaMensual.fromJson(Map<String, dynamic> json) {
    return MetaMensual(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      anio: (json['anio'] as num).toInt(),
      mes: (json['mes'] as num).toInt(),
      kpi: json['kpi'] as String,
      valorObjetivo: (json['valor_objetivo'] as num).toDouble(),
      unidad: json['unidad'] as String,
      prioridad: json['prioridad'] as String? ?? 'media',
      notas: json['notas'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'anio': anio,
        'mes': mes,
        'kpi': kpi,
        'valor_objetivo': valorObjetivo,
        'unidad': unidad,
        'prioridad': prioridad,
        'notas': notas,
      };

  String get kpiLabel => switch (kpi) {
        'prolificidad' => 'Prolificidad',
        'fertilidad' => 'Fertilidad',
        'supervivencia' => 'Supervivencia',
        'nacimientos' => 'Nacimientos',
        _ => kpi,
      };
}
