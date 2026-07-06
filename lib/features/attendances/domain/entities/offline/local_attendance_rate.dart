import 'package:equatable/equatable.dart';

/// Taux de présence dérivé localement (AF-3) :
/// `(effectif − absences) / effectif`, effectif = roster ACTIVE.
/// `syncedAt` = fraîcheur (ADR-002) du roster sous-jacent.
class LocalAttendanceRate extends Equatable {
  final int effectif;
  final int absences;
  final int? syncedAt;

  const LocalAttendanceRate({
    required this.effectif,
    required this.absences,
    this.syncedAt,
  });

  int get present => (effectif - absences).clamp(0, effectif);

  /// Ratio [0..1] ; 1.0 si l'effectif est nul (aucune donnée = pas d'alerte).
  double get rate => effectif == 0 ? 1.0 : present / effectif;

  @override
  List<Object?> get props => [effectif, absences, syncedAt];
}
