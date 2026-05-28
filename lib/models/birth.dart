class Birth {
  final String id;
  final String matingId;
  final String motherId;
  final String? fatherId;
  final DateTime birthDate;
  final int litterSize;           // Cantidad total de crías
  final double averageWeight;     // Peso promedio al nacer
  final int liveKits;             // Crías vivas
  final int deadKits;             // Crías muertas
  final String notes;

  Birth({
    required this.id,
    required this.matingId,
    required this.motherId,
    this.fatherId,
    required this.birthDate,
    required this.litterSize,
    required this.averageWeight,
    this.liveKits = 0,
    this.deadKits = 0,
    this.notes = '',
  });

  int get survivalRate => litterSize > 0 ? ((liveKits / litterSize) * 100).round() : 0;
}