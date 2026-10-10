class Birth {
  final String id;
  final String? matingId;
  final int? motherId;
  final int? fatherId;
  final DateTime birthDate;
  final int litterSize;
  final double averageWeight;
  final int liveKits;
  final int deadKits;
  final int adoptedKits;
  final String notes;

  Birth({
    required this.id,
    this.matingId,
    this.motherId,
    this.fatherId,
    required this.birthDate,
    required this.litterSize,
    required this.averageWeight,
    this.liveKits = 0,
    this.deadKits = 0,
    this.adoptedKits = 0,
    this.notes = '',
  });

  /// Convertir desde JSON (Supabase)
  factory Birth.fromJson(Map<String, dynamic> json) {
    return Birth(
      id: json['id'] as String? ?? '',
      matingId: json['mating_id'] as String?,
      motherId: json['mother_id'] as int?,
      fatherId: json['father_id'] as int?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : DateTime.now(),
      litterSize: json['litter_size'] as int? ?? 0,
      averageWeight: (json['average_weight'] as num?)?.toDouble() ?? 0.0,
      liveKits: json['live_kits'] as int? ?? 0,
      deadKits: json['dead_kits'] as int? ?? 0,
      adoptedKits: json['adopted_kits'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }

  /// Convertir a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'mating_id': matingId,
      'mother_id': motherId,
      'father_id': fatherId,
      'birth_date': birthDate.toIso8601String(),
      'litter_size': litterSize,
      'average_weight': averageWeight,
      'live_kits': liveKits,
      'dead_kits': deadKits,
      'adopted_kits': adoptedKits,
      'notes': notes,
    };
  }

  /// Copiar con cambios
  Birth copyWith({
    String? id,
    String? matingId,
    int? motherId,
    int? fatherId,
    DateTime? birthDate,
    int? litterSize,
    double? averageWeight,
    int? liveKits,
    int? deadKits,
    int? adoptedKits,
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
      adoptedKits: adoptedKits ?? this.adoptedKits,
      notes: notes ?? this.notes,
    );
  }

  int get survivalRate =>
      litterSize > 0 ? ((liveKits / litterSize) * 100).round() : 0;

  @override
  String toString() =>
      'Birth(id: $id, motherId: $motherId, litterSize: $litterSize)';
}