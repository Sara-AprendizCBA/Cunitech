class Rabbit {
  final String id;
  final String name; // Opcional: nombre o apodo
  final String breed;
  final int ageMonths;
  final double weightKg;
  final String gender; // Macho / Hembra
  final String healthStatus;
  final DateTime registrationDate;
  final DateTime? lastFeedingDate;
  final DateTime? lastTreatmentDate;
  final String? notes;
  final bool isBreeder;           // ¿Es reproductora?
  final int litterCount;          // Cantidad de partos
  final DateTime? lastMatingDate;
  final DateTime? expectedBirthDate;

  Rabbit({
    required this.id,
    this.name = '',
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

  String get statusColor {
    if (healthStatus.contains("Saludable")) return "green";
    if (healthStatus.contains("Tratamiento")) return "orange";
    return "red";
  }
}