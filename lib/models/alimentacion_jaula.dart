class AlimentacionJaula {
  final String? id;
  final String jaula;
  final DateTime fecha;
  final double cantidadKg;
  final String? tipoComida;
  final String estado;
  final String? notas;
  final String? userId;

  AlimentacionJaula({
    this.id,
    required this.jaula,
    required this.fecha,
    required this.cantidadKg,
    this.tipoComida,
    this.estado = 'Completado',
    this.notas,
    this.userId,
  });

  factory AlimentacionJaula.fromJson(Map<String, dynamic> json) {
    return AlimentacionJaula(
      id: json['id'] as String?,
      jaula: json['jaula'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      cantidadKg: (json['cantidad_kg'] as num).toDouble(),
      tipoComida: json['tipo_comida'] as String?,
      estado: json['estado'] as String? ?? 'Completado',
      notas: json['notas'] as String?,
      userId: json['user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'jaula': jaula,
        'fecha': fecha.toIso8601String().split('T')[0],
        'cantidad_kg': cantidadKg,
        'tipo_comida': tipoComida,
        'estado': estado,
        'notas': notas,
        'user_id': userId,
      };
}
