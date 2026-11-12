/// Modelo de un pesaje, mapeado a la tabla `pesajes` de Supabase.
///
/// Cada registro es el peso (en kg) que tenía un conejo en una fecha.
class PesoRegistro {
  final String id;
  final int conejoId;
  final DateTime fecha;
  final double pesoKg;
  final String? notas;

  const PesoRegistro({
    required this.id,
    required this.conejoId,
    required this.fecha,
    required this.pesoKg,
    this.notas,
  });

  static DateTime? _parseDate(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  factory PesoRegistro.fromJson(Map<String, dynamic> json) {
    return PesoRegistro(
      id: json['id']?.toString() ?? '',
      conejoId: (json['conejo_id'] as num?)?.toInt() ?? 0,
      fecha: _parseDate(json['fecha']) ?? DateTime.now(),
      pesoKg: (json['peso_kg'] as num?)?.toDouble() ?? 0,
      notas: json['notas'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'conejo_id': conejoId,
        'fecha': fecha.toIso8601String().split('T').first,
        'peso_kg': pesoKg,
        'notas': notas,
      };

  @override
  String toString() => 'PesoRegistro(conejo: $conejoId, $pesoKg kg, $fecha)';
}
