class Rabbit {
  final String id;
  final String name;
  final String breed;
  final int ageMonths;
  final double weightKg;
  final String gender; // Macho / Hembra
  final String healthStatus;
  final DateTime registrationDate;
  final DateTime? lastFeedingDate;
  final DateTime? lastTreatmentDate;
  final String? notes;
  final bool isBreeder;
  final int litterCount;
  final DateTime? lastMatingDate;
  final DateTime? expectedBirthDate;

  Rabbit({
    required this.id,
    required this.name,
    required this.breed,
    required this.ageMonths,
    required this.weightKg,
    required this.gender,
    required this.healthStatus,
    required this.registrationDate,
    this.lastFeedingDate,
    this.lastTreatmentDate,
    this.notes,
    this.isBreeder = false,
    this.litterCount = 0,
    this.lastMatingDate,
    this.expectedBirthDate,
  });

  /// Convertir desde JSON (Supabase)
  factory Rabbit.fromJson(Map<String, dynamic> json) {
    return Rabbit(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      breed: json['breed'] as String? ?? '',
      ageMonths: json['age_months'] as int? ?? 0,
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      gender: json['gender'] as String? ?? 'Macho',
      healthStatus: json['health_status'] as String? ?? 'Saludable',
      registrationDate: json['registration_date'] != null
          ? DateTime.parse(json['registration_date'] as String)
          : DateTime.now(),
      lastFeedingDate: json['last_feeding_date'] != null
          ? DateTime.parse(json['last_feeding_date'] as String)
          : null,
      lastTreatmentDate: json['last_treatment_date'] != null
          ? DateTime.parse(json['last_treatment_date'] as String)
          : null,
      notes: json['notes'] as String?,
      isBreeder: json['is_breeder'] as bool? ?? false,
      litterCount: json['litter_count'] as int? ?? 0,
      lastMatingDate: json['last_mating_date'] != null
          ? DateTime.parse(json['last_mating_date'] as String)
          : null,
      expectedBirthDate: json['expected_birth_date'] != null
          ? DateTime.parse(json['expected_birth_date'] as String)
          : null,
    );
  }

  /// Convertir a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'age_months': ageMonths,
      'weight_kg': weightKg,
      'gender': gender,
      'health_status': healthStatus,
      'registration_date': registrationDate.toIso8601String(),
      'last_feeding_date': lastFeedingDate?.toIso8601String(),
      'last_treatment_date': lastTreatmentDate?.toIso8601String(),
      'notes': notes,
      'is_breeder': isBreeder,
      'litter_count': litterCount,
      'last_mating_date': lastMatingDate?.toIso8601String(),
      'expected_birth_date': expectedBirthDate?.toIso8601String(),
    };
  }

  /// Copiar con cambios
  Rabbit copyWith({
    String? id,
    String? name,
    String? breed,
    int? ageMonths,
    double? weightKg,
    String? gender,
    String? healthStatus,
    DateTime? registrationDate,
    DateTime? lastFeedingDate,
    DateTime? lastTreatmentDate,
    String? notes,
    bool? isBreeder,
    int? litterCount,
    DateTime? lastMatingDate,
    DateTime? expectedBirthDate,
  }) {
    return Rabbit(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      ageMonths: ageMonths ?? this.ageMonths,
      weightKg: weightKg ?? this.weightKg,
      gender: gender ?? this.gender,
      healthStatus: healthStatus ?? this.healthStatus,
      registrationDate: registrationDate ?? this.registrationDate,
      lastFeedingDate: lastFeedingDate ?? this.lastFeedingDate,
      lastTreatmentDate: lastTreatmentDate ?? this.lastTreatmentDate,
      notes: notes ?? this.notes,
      isBreeder: isBreeder ?? this.isBreeder,
      litterCount: litterCount ?? this.litterCount,
      lastMatingDate: lastMatingDate ?? this.lastMatingDate,
      expectedBirthDate: expectedBirthDate ?? this.expectedBirthDate,
    );
  }

  String get statusColor {
    if (healthStatus.contains("Saludable")) return "#9E7C5E";
    if (healthStatus.contains("Tratamiento")) return "orange";
    return "red";
  }

  @override
  String toString() => 'Rabbit(id: $id, name: $name, breed: $breed)';
}