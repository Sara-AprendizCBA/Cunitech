class Birth {
  final String id;
  final String? matingId;
  final String motherId;
  final String? fatherId;
  final DateTime birthDate;
  final int litterSize;
  final double averageWeight;
  final int liveKits;
  final int deadKits;
  final String notes;

  Birth({
    required this.id,
    this.matingId,
    required this.motherId,
    this.fatherId,
    required this.birthDate,
    required this.litterSize,
    required this.averageWeight,
    this.liveKits = 0,
    this.deadKits = 0,
    this.notes = '',
  });

  /// Convertir desde JSON (Supabase)
  factory Birth.fromJson(Map<String, dynamic> json) {
    return Birth(
      id: json['id'] as String? ?? '',
      matingId: json['mating_id'] as String?,
      motherId: json['mother_id'] as String? ?? '',
      fatherId: json['father_id'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : DateTime.now(),
      litterSize: json['litter_size'] as int? ?? 0,
      averageWeight: (json['average_weight'] as num?)?.toDouble() ?? 0.0,
      liveKits: json['live_kits'] as int? ?? 0,
      deadKits: json['dead_kits'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }

  /// Convertir a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mating_id': matingId,
      'mother_id': motherId,
      'father_id': fatherId,
      'birth_date': birthDate.toIso8601String(),
      'litter_size': litterSize,
      'average_weight': averageWeight,
      'live_kits': liveKits,
      'dead_kits': deadKits,
      'notes': notes,
    };
  }

  /// Copiar con cambios
  Birth copyWith({
    String? id,
    String? matingId,
    String? motherId,
    String? fatherId,
    DateTime? birthDate,
    int? litterSize,
    double? averageWeight,
    int? liveKits,
    int? deadKits,
    String? notes,
  }) {
    return Birth(
      id: id ?? this.id,
      matingId: matingId ?? this.matingId,
      motherId: motherId ?? this.motherId,
      fatherId: fatherId ?? this.fatherId,
      birthDate: birthDate ?? this.birthDate,
      litterSize: litterSize ?? this.litterSize,
      averageWeight: averageWeight ?? this.averageWeight,
      liveKits: liveKits ?? this.liveKits,
      deadKits: deadKits ?? this.deadKits,
      notes: notes ?? this.notes,
    );
  }

  int get survivalRate =>
      litterSize > 0 ? ((liveKits / litterSize) * 100).round() : 0;

  @override
  String toString() =>
      'Birth(id: $id, motherId: $motherId, litterSize: $litterSize)';
}