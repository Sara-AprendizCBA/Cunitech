/// Modelo del conejo, mapeado a la tabla `conejo` de Supabase
class Rabbit {
  final String id; // id_conejo
  final String name; // nombre
  final String breed; // raza
  final String gender; // genero: Macho / Hembra
  final DateTime birthDate; // fecha_nacimiento
  final double weightKg; // peso (0 = sin dato)
  final String healthStatus; // estado
  final int? motherId; // id_madre
  final int? fatherId; // id_padre
  final int farmId; // id_granja
  final DateTime registrationDate; // fecha_ingreso

  // Campos que NO están en la tabla (los usan otras pantallas, no se guardan)
  final DateTime? lastFeedingDate;
  final DateTime? lastTreatmentDate;
  final String? notes;
  final int litterCount;
  final DateTime? lastMatingDate;
  final DateTime? expectedBirthDate;

  Rabbit({
    required this.id,
    required this.name,
    required this.breed,
    required this.gender,
    required this.birthDate,
    required this.weightKg,
    required this.healthStatus,
    required this.farmId,
    required this.registrationDate,
    this.motherId,
    this.fatherId,
    this.lastFeedingDate,
    this.lastTreatmentDate,
    this.notes,
    this.litterCount = 0,
    this.lastMatingDate,
    this.expectedBirthDate,
  });

  /// Edad en meses calculada desde la fecha de nacimiento
  int get ageMonths {
    final now = DateTime.now();
    int months =
        (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
    if (now.day < birthDate.day) months--;
    return months < 0 ? 0 : months;
  }

  /// Las hembras se consideran reproductoras
  bool get isBreeder => gender == 'Hembra';

  static DateTime? _parseDate(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  /// Formato 'yyyy-MM-dd' para columnas tipo date
  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  factory Rabbit.fromJson(Map<String, dynamic> json) {
    final nombre = json['nombre'] as String?;
    return Rabbit(
      id: json['id_conejo']?.toString() ?? '',
      name: (nombre == null || nombre.isEmpty) ? 'Conejo' : nombre,
      breed: json['raza'] as String? ?? '',
      gender: json['genero'] as String? ?? 'Macho',
      birthDate: _parseDate(json['fecha_nacimiento']) ?? DateTime.now(),
      weightKg: (json['peso'] as num?)?.toDouble() ?? 0.0,
      healthStatus: json['estado'] as String? ?? 'Saludable',
      motherId: json['id_madre'] as int?,
      fatherId: json['id_padre'] as int?,
      farmId: json['id_granja'] as int? ?? 0,
      registrationDate: _parseDate(json['fecha_ingreso']) ?? DateTime.now(),
    );
  }

  /// Para Supabase (sin id: lo genera la base de datos)
  Map<String, dynamic> toJson() {
    return {
      'nombre': name,
      'raza': breed,
      'genero': gender,
      'fecha_nacimiento': _dateOnly(birthDate),
      'peso': weightKg > 0 ? weightKg : null,
      'estado': healthStatus,
      'id_madre': motherId,
      'id_padre': fatherId,
      'id_granja': farmId,
      'fecha_ingreso': _dateOnly(registrationDate),
    };
  }

  Rabbit copyWith({
    String? id,
    String? name,
    String? breed,
    String? gender,
    DateTime? birthDate,
    double? weightKg,
    String? healthStatus,
    int? motherId,
    int? fatherId,
    int? farmId,
    DateTime? registrationDate,
    DateTime? lastFeedingDate,
    DateTime? lastTreatmentDate,
    String? notes,
    int? litterCount,
    DateTime? lastMatingDate,
    DateTime? expectedBirthDate,
  }) {
    return Rabbit(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      weightKg: weightKg ?? this.weightKg,
      healthStatus: healthStatus ?? this.healthStatus,
      motherId: motherId ?? this.motherId,
      fatherId: fatherId ?? this.fatherId,
      farmId: farmId ?? this.farmId,
      registrationDate: registrationDate ?? this.registrationDate,
      lastFeedingDate: lastFeedingDate ?? this.lastFeedingDate,
      lastTreatmentDate: lastTreatmentDate ?? this.lastTreatmentDate,
      notes: notes ?? this.notes,
      litterCount: litterCount ?? this.litterCount,
      lastMatingDate: lastMatingDate ?? this.lastMatingDate,
      expectedBirthDate: expectedBirthDate ?? this.expectedBirthDate,
    );
  }

  String get statusColor {
    if (healthStatus.contains("Saludable")) return "green";
    if (healthStatus.contains("Tratamiento")) return "orange";
    return "red";
  }

  @override
  String toString() => 'Rabbit(id: $id, name: $name, breed: $breed)';
}