class Kit {
  final String id;
  final String motherId;
  final String? fatherId;
  final DateTime birthDate;
  final double birthWeight;
  final double currentWeight;
  final int ageDays;
  final String healthStatus;
  final DateTime? weaningDate;

  Kit({
    required this.id,
    required this.motherId,
    this.fatherId,
    required this.birthDate,
    required this.birthWeight,
    required this.currentWeight,
    required this.ageDays,
    this.healthStatus = "Saludable",
    this.weaningDate,
  });

  /// Convertir desde JSON (Supabase)
  factory Kit.fromJson(Map<String, dynamic> json) {
    return Kit(
      id: json['id'] as String? ?? '',
      motherId: json['mother_id'] as String? ?? '',
      fatherId: json['father_id'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : DateTime.now(),
      birthWeight: (json['birth_weight'] as num?)?.toDouble() ?? 0.0,
      currentWeight: (json['current_weight'] as num?)?.toDouble() ?? 0.0,
      ageDays: json['age_days'] as int? ?? 0,
      healthStatus: json['health_status'] as String? ?? 'Saludable',
      weaningDate: json['weaning_date'] != null
          ? DateTime.parse(json['weaning_date'] as String)
          : null,
    );
  }

  /// Convertir a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mother_id': motherId,
      'father_id': fatherId,
      'birth_date': birthDate.toIso8601String(),
      'birth_weight': birthWeight,
      'current_weight': currentWeight,
      'age_days': ageDays,
      'health_status': healthStatus,
      'weaning_date': weaningDate?.toIso8601String(),
    };
  }

  /// Copiar con cambios
  Kit copyWith({
    String? id,
    String? motherId,
    String? fatherId,
    DateTime? birthDate,
    double? birthWeight,
    double? currentWeight,
    int? ageDays,
    String? healthStatus,
    DateTime? weaningDate,
  }) {
    return Kit(
      id: id ?? this.id,
      motherId: motherId ?? this.motherId,
      fatherId: fatherId ?? this.fatherId,
      birthDate: birthDate ?? this.birthDate,
      birthWeight: birthWeight ?? this.birthWeight,
      currentWeight: currentWeight ?? this.currentWeight,
      ageDays: ageDays ?? this.ageDays,
      healthStatus: healthStatus ?? this.healthStatus,
      weaningDate: weaningDate ?? this.weaningDate,
    );
  }

  double get weightGain => currentWeight - birthWeight;

  @override
  String toString() => 'Kit(id: $id, motherId: $motherId, ageDays: $ageDays)';
}