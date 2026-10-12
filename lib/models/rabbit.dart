/// Modelo del conejo, mapeado a la tabla `conejo` de Supabase
class Rabbit {
  final String id; // id_conejo
  final String? name; // nombre opcional, no es el identificador visible
  final String breed; // raza
  final String gender; // genero: Macho / Hembra
  final DateTime birthDate; // fecha_nacimiento
  final double weightKg; // peso (0 = sin dato)
  final String healthStatus; // estado
  final int? motherId; // id_madre
  final int? fatherId; // id_padre
  final int farmId; // id_granja
  final DateTime registrationDate; // fecha_ingreso
  final DateTime? entryDate;
  final String? origin;
  final String? registryNumber;
  final String? cageNumber;
  final String? photoUrl;
  final String chapeta;
  final String? placaInventario;
  final String? color;
  final String reproductiveStatus;
  final DateTime? expectedBirthDate;
  final bool isActiveBreeder;
  final double? lastWeightKg;
  final DateTime? matingDate;
  final DateTime? actualBirthDate;
  final int? actualLitterSize;
  final String? discardReason;
  final DateTime? discardDate;
  final DateTime? palpationDate;
  final DateTime? maxBirthDate;
  final DateTime? nextMatingDate;

  // Campos que NO están en la tabla (los usan otras pantallas, no se guardan)
  final DateTime? lastFeedingDate;
  final DateTime? lastTreatmentDate;
  final String? notes;
  final int litterCount;
  final DateTime? lastMatingDate;

  Rabbit({
    required this.id,
    this.name,
    required this.breed,
    required this.gender,
    required this.birthDate,
    required this.weightKg,
    required this.healthStatus,
    required this.farmId,
    required this.registrationDate,
    required this.chapeta,
    this.motherId,
    this.fatherId,
    this.entryDate,
    this.origin,
    this.registryNumber,
    this.cageNumber,
    this.photoUrl,
    this.placaInventario,
    this.color,
    this.reproductiveStatus = 'Vacía',
    this.expectedBirthDate,
    this.isActiveBreeder = true,
    this.lastWeightKg,
    this.matingDate,
    this.actualBirthDate,
    this.actualLitterSize,
    this.discardReason,
    this.discardDate,
    this.palpationDate,
    this.maxBirthDate,
    this.nextMatingDate,
    this.lastFeedingDate,
    this.lastTreatmentDate,
    this.notes,
    this.litterCount = 0,
    this.lastMatingDate,
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

  /// Identificador que se muestra al usuario en toda la UI.
  /// En cunicultura se usa la chapeta, no el nombre.
  String get displayId => chapeta.isEmpty ? 'Sin ID' : chapeta;

  static DateTime? _parseDate(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  /// Formato 'yyyy-MM-dd' para columnas tipo date
  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  factory Rabbit.fromJson(Map<String, dynamic> json) {
    return Rabbit(
      id: json['id_conejo']?.toString() ?? '',
      name: json['nombre'] as String?,
      breed: json['raza'] as String? ?? '',
      gender: json['genero'] as String? ?? 'Macho',
      birthDate: _parseDate(json['fecha_nacimiento']) ?? DateTime.now(),
      weightKg: (json['peso'] as num?)?.toDouble() ?? 0.0,
      healthStatus: json['estado'] as String? ?? 'Saludable',
      motherId: json['mother_id'] as int?,
      fatherId: json['father_id'] as int?,
      farmId: json['id_granja'] as int? ?? 0,
      registrationDate: _parseDate(json['fecha_ingreso']) ?? DateTime.now(),
      entryDate: _parseDate(json['entry_date']),
      origin: json['origin'] as String?,
      registryNumber: json['registry_number'] as String?,
      cageNumber: json['cage_number'] as String?,
      photoUrl: json['photo_url'] as String?,
      chapeta: json['chapeta'] as String? ?? 'Sin ID',
      placaInventario: json['placa_inventario'] as String?,
      color: json['color'] as String?,
      reproductiveStatus: json['reproductive_status'] as String? ?? 'Vacía',
      expectedBirthDate: _parseDate(json['expected_birth_date']),
      isActiveBreeder: json['is_active_breeder'] as bool? ?? true,
      lastWeightKg: (json['last_weight_kg'] as num?)?.toDouble(),
      matingDate: _parseDate(json['mating_date']),
      actualBirthDate: _parseDate(json['actual_birth_date']),
      actualLitterSize: (json['actual_litter_size'] as num?)?.toInt(),
      discardReason: json['discard_reason'] as String?,
      discardDate: _parseDate(json['discard_date']),
      palpationDate: _parseDate(json['palpation_date']),
      maxBirthDate: _parseDate(json['max_birth_date']),
      nextMatingDate: _parseDate(json['next_mating_date']),
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
      'mother_id': motherId,
      'father_id': fatherId,
      'id_granja': farmId,
      'fecha_ingreso': _dateOnly(registrationDate),
      'entry_date': entryDate == null ? null : _dateOnly(entryDate!),
      'origin': origin,
      'registry_number': registryNumber,
      'cage_number': cageNumber,
      'photo_url': photoUrl,
      'chapeta': chapeta,
      'placa_inventario': placaInventario,
      'color': color,
      'reproductive_status': reproductiveStatus,
      'expected_birth_date': expectedBirthDate == null
          ? null
          : _dateOnly(expectedBirthDate!),
      'is_active_breeder': isActiveBreeder,
      'last_weight_kg': lastWeightKg,
      'mating_date': matingDate == null ? null : _dateOnly(matingDate!),
      'actual_birth_date': actualBirthDate == null
          ? null
          : _dateOnly(actualBirthDate!),
      'actual_litter_size': actualLitterSize,
      'discard_reason': discardReason,
      'discard_date': discardDate == null ? null : _dateOnly(discardDate!),
      'palpation_date': palpationDate == null
          ? null
          : _dateOnly(palpationDate!),
      'max_birth_date': maxBirthDate == null ? null : _dateOnly(maxBirthDate!),
      'next_mating_date': nextMatingDate == null
          ? null
          : _dateOnly(nextMatingDate!),
    };
  }

  Map<String, dynamic> toInsertJson() {
    final json = toJson();
    for (final field in [
      'reproductive_status',
      'mating_date',
      'expected_birth_date',
      'actual_birth_date',
      'actual_litter_size',
      'discard_reason',
      'discard_date',
      'palpation_date',
      'max_birth_date',
      'next_mating_date',
    ]) {
      json.remove(field);
    }
    return json;
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
    DateTime? entryDate,
    String? origin,
    String? registryNumber,
    String? cageNumber,
    String? photoUrl,
    String? chapeta,
    String? placaInventario,
    String? color,
    String? reproductiveStatus,
    DateTime? expectedBirthDate,
    bool? isActiveBreeder,
    double? lastWeightKg,
    DateTime? matingDate,
    DateTime? actualBirthDate,
    int? actualLitterSize,
    String? discardReason,
    DateTime? discardDate,
    DateTime? palpationDate,
    DateTime? maxBirthDate,
    DateTime? nextMatingDate,
    DateTime? lastFeedingDate,
    DateTime? lastTreatmentDate,
    String? notes,
    int? litterCount,
    DateTime? lastMatingDate,
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
      entryDate: entryDate ?? this.entryDate,
      origin: origin ?? this.origin,
      registryNumber: registryNumber ?? this.registryNumber,
      cageNumber: cageNumber ?? this.cageNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      chapeta: chapeta ?? this.chapeta,
      placaInventario: placaInventario ?? this.placaInventario,
      color: color ?? this.color,
      reproductiveStatus: reproductiveStatus ?? this.reproductiveStatus,
      expectedBirthDate: expectedBirthDate ?? this.expectedBirthDate,
      isActiveBreeder: isActiveBreeder ?? this.isActiveBreeder,
      lastWeightKg: lastWeightKg ?? this.lastWeightKg,
      matingDate: matingDate ?? this.matingDate,
      actualBirthDate: actualBirthDate ?? this.actualBirthDate,
      actualLitterSize: actualLitterSize ?? this.actualLitterSize,
      discardReason: discardReason ?? this.discardReason,
      discardDate: discardDate ?? this.discardDate,
      palpationDate: palpationDate ?? this.palpationDate,
      maxBirthDate: maxBirthDate ?? this.maxBirthDate,
      nextMatingDate: nextMatingDate ?? this.nextMatingDate,
      lastFeedingDate: lastFeedingDate ?? this.lastFeedingDate,
      lastTreatmentDate: lastTreatmentDate ?? this.lastTreatmentDate,
      notes: notes ?? this.notes,
      litterCount: litterCount ?? this.litterCount,
      lastMatingDate: lastMatingDate ?? this.lastMatingDate,
    );
  }

  String get statusColor {
    if (healthStatus.contains("Saludable")) return "green";
    if (healthStatus.contains("Tratamiento")) return "orange";
    return "red";
  }

  @override
  String toString() => 'Rabbit(id: $id, chapeta: $displayId, breed: $breed)';
}
