class Mating {
  final String id;
  final String doeId;        // Coneja madre
  final String buckId;       // Conejo padre
  final DateTime matingDate;
  final DateTime? expectedBirthDate;
  final String status;       // En gestación, Parida, Fallida
  final int litterSize;      // Cantidad de crías nacidas
  final String? notes;

  Mating({
    required this.id,
    required this.doeId,
    required this.buckId,
    required this.matingDate,
    this.expectedBirthDate,
    this.status = "En gestación",
    this.litterSize = 0,
    this.notes,
  });

  bool get isNearBirth {
    if (expectedBirthDate == null) return false;
    final daysLeft = expectedBirthDate!.difference(DateTime.now()).inDays;
    return daysLeft <= 3 && daysLeft >= 0;
  }
}