class Reproduccion {
  final int? idReproduccion;
  final int idConeja;
  final int? idConejopadre;
  final DateTime fechaMonta;
  final DateTime? fechaParto;
  final int? numeroCrias;
  final String? userId;
  final String estado;
  final DateTime? fechaPalpacion;
  final DateTime? fechaProbableParto;
  final DateTime? fechaNidal;
  final DateTime? fechaDestete;
  final int numVivos;
  final int numMuertos;
  final int numAdoptados;
  final double? pesoPromedioCamada;
  final String? notas;

  Reproduccion({
    this.idReproduccion,
    required this.idConeja,
    this.idConejopadre,
    required this.fechaMonta,
    this.fechaParto,
    this.numeroCrias,
    this.userId,
    this.estado = 'Servida',
    this.fechaPalpacion,
    this.fechaProbableParto,
    this.fechaNidal,
    this.fechaDestete,
    this.numVivos = 0,
    this.numMuertos = 0,
    this.numAdoptados = 0,
    this.pesoPromedioCamada,
    this.notas,
  });

  factory Reproduccion.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) =>
        value == null ? null : DateTime.parse(value as String);

    return Reproduccion(
      idReproduccion: json['id_reproduccion'] as int?,
      idConeja: json['id_coneja'] as int,
      idConejopadre: json['id_conejopadre'] as int?,
      fechaMonta: DateTime.parse(json['fecha_monta'] as String),
      fechaParto: parseDate(json['fecha_parto']),
      numeroCrias: json['numero_crias'] as int?,
      userId: json['user_id'] as String?,
      estado: json['estado'] as String? ?? 'Servida',
      fechaPalpacion: parseDate(json['fecha_palpacion']),
      fechaProbableParto: parseDate(json['fecha_probable_parto']),
      fechaNidal: parseDate(json['fecha_nidal']),
      fechaDestete: parseDate(json['fecha_destete']),
      numVivos: json['num_vivos'] as int? ?? 0,
      numMuertos: json['num_muertos'] as int? ?? 0,
      numAdoptados: json['num_adoptados'] as int? ?? 0,
      pesoPromedioCamada:
          (json['peso_promedio_camada'] as num?)?.toDouble(),
      notas: json['notas'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_coneja': idConeja,
        'id_conejopadre': idConejopadre,
        'fecha_monta': _dateToJson(fechaMonta),
        'fecha_parto': _dateToJson(fechaParto),
        'numero_crias': numeroCrias,
        'user_id': userId,
        'estado': estado,
        'fecha_palpacion': _dateToJson(fechaPalpacion),
        'fecha_probable_parto': _dateToJson(fechaProbableParto),
        'fecha_nidal': _dateToJson(fechaNidal),
        'fecha_destete': _dateToJson(fechaDestete),
        'num_vivos': numVivos,
        'num_muertos': numMuertos,
        'num_adoptados': numAdoptados,
        'peso_promedio_camada': pesoPromedioCamada,
        'notas': notas,
      };

  static String? _dateToJson(DateTime? date) =>
      date?.toIso8601String().split('T').first;

  bool get estaServida => estado == 'Servida';
  bool get estaGestante => estado == 'Gestante';
  bool get estaFallida => estado == 'Fallida';

  int? get diasDesdeMonta => DateTime.now().difference(fechaMonta).inDays;

  bool get tocaPalpacion {
    final dias = diasDesdeMonta;
    return estado == 'Servida' && dias != null && dias >= 12 && dias <= 16;
  }

  Reproduccion copyWith({
    int? idReproduccion,
    int? idConeja,
    int? idConejopadre,
    DateTime? fechaMonta,
    DateTime? fechaParto,
    int? numeroCrias,
    String? userId,
    String? estado,
    DateTime? fechaPalpacion,
    DateTime? fechaProbableParto,
    DateTime? fechaNidal,
    DateTime? fechaDestete,
    int? numVivos,
    int? numMuertos,
    int? numAdoptados,
    double? pesoPromedioCamada,
    String? notas,
  }) {
    return Reproduccion(
      idReproduccion: idReproduccion ?? this.idReproduccion,
      idConeja: idConeja ?? this.idConeja,
      idConejopadre: idConejopadre ?? this.idConejopadre,
      fechaMonta: fechaMonta ?? this.fechaMonta,
      fechaParto: fechaParto ?? this.fechaParto,
      numeroCrias: numeroCrias ?? this.numeroCrias,
      userId: userId ?? this.userId,
      estado: estado ?? this.estado,
      fechaPalpacion: fechaPalpacion ?? this.fechaPalpacion,
      fechaProbableParto: fechaProbableParto ?? this.fechaProbableParto,
      fechaNidal: fechaNidal ?? this.fechaNidal,
      fechaDestete: fechaDestete ?? this.fechaDestete,
      numVivos: numVivos ?? this.numVivos,
      numMuertos: numMuertos ?? this.numMuertos,
      numAdoptados: numAdoptados ?? this.numAdoptados,
      pesoPromedioCamada: pesoPromedioCamada ?? this.pesoPromedioCamada,
      notas: notas ?? this.notas,
    );
  }
}
