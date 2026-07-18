import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';

/// Vue d'un appel local pour un `(classe, jour)` — porte explicitement les
/// **3 états** du contrat 1.2.0 (invariant #1) :
///
/// - `taken == false` ⇒ **appel non fait** : aucune session pour ce jour. Le
///   roster est fourni « présent par défaut » pour permettre la saisie, mais
///   l'UI ne doit PAS le présenter comme un appel validé (piège B4/PRE-4 :
///   « 0 ligne » ne vaut jamais « tous présents »).
/// - `taken == true` sans exception ⇒ **tous présents** (appel fait).
/// - `taken == true` + ligne d'absence ⇒ **absent**.
///
/// `takenAt`/`takenBy` ne sont renseignés que si `taken` (métadonnées de session).
class DailyAttendance extends Equatable {
  /// Une session existe pour ce `(classe, date, année)` : l'appel a été fait.
  final bool taken;

  /// Roster ACTIVE résolu (présent par défaut, écrasé par les exceptions).
  final List<AttendanceRecord> records;

  /// Heure métier de l'appel (si `taken`).
  final DateTime? takenAt;

  /// Auteur de l'appel (si `taken` et connu).
  final String? takenBy;

  const DailyAttendance({
    required this.taken,
    required this.records,
    this.takenAt,
    this.takenBy,
  });

  @override
  List<Object?> get props => [taken, records, takenAt, takenBy];
}
