// lib/models/tratamiento.dart

/// Modelo de una aplicación sanitaria (vacuna, tratamiento o desparasitación),
/// mapeado a la tabla `tratamientos` de Supabase.
class Tratamiento {
  final String id;
  final int? conejoId;
  final String? jaulaGrupo;
  final String tipo; // vacuna, tratamiento, desparasitacion
  final String producto;
  final String? dosis;
  final String? via;
  final DateTime fechaAplicacion;
  final DateTime? fechaProxima;
  final String? notas;
  final String? nombreConejo; // chapeta (viene del join con `conejo`)

  Tratamiento({
    required this.id,
    this.conejoId,
    this.jaulaGrupo,
    required this.tipo,
    required this.producto,
    this.dosis,
    this.via,
    required this.fechaAplicacion,
    this.fechaProxima,
    this.notas,
    this.nombreConejo,
  });

  static DateTime? _parseDate(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  /// Formato 'yyyy-MM-dd' para columnas tipo date.
  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  factory Tratamiento.fromJson(Map<String, dynamic> json) {
    // La chapeta llega del join embebido: { ..., 'conejo': { 'chapeta': 'M-01' } }
    final conejo = json['conejo'];
    final chapeta = conejo is Map ? conejo['chapeta'] as String? : null;

    return Tratamiento(
      id: json['id']?.toString() ?? '',
      conejoId: (json['conejo_id'] as num?)?.toInt(),
      jaulaGrupo: json['jaula_grupo'] as String?,
      tipo: json['tipo'] as String? ?? 'tratamiento',
      producto: json['producto'] as String? ?? '',
      dosis: json['dosis'] as String?,
      via: json['via'] as String?,
      fechaAplicacion: _parseDate(json['fecha_aplicacion']) ?? DateTime.now(),
      fechaProxima: _parseDate(json['fecha_proxima']),
      notas: json['notas'] as String?,
      nombreConejo: chapeta,
    );
  }

  /// Payload para Supabase (sin id, user_id ni created_at: los gestiona la BD).
  Map<String, dynamic> toJson() {
    return {
      'conejo_id': conejoId,
      'jaula_grupo': jaulaGrupo,
      'tipo': tipo,
      'producto': producto,
      'dosis': dosis,
      'via': via,
      'fecha_aplicacion': _dateOnly(fechaAplicacion),
      'fecha_proxima': fechaProxima == null ? null : _dateOnly(fechaProxima!),
      'notas': notas,
    };
  }

  @override
  String toString() =>
      'Tratamiento(id: $id, tipo: $tipo, producto: $producto, conejo: $nombreConejo)';
}
