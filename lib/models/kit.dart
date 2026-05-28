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
}