import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';

/// Projection de liste (jointure élève + inscription) servie hors-ligne.
class LocalEnrollmentListItem extends Equatable {
  final String enrollmentId;
  final String studentId;
  final String firstName;
  final String lastName;
  final String? surname;
  final String dateOfBirth;
  final OfflineGender gender;
  final EnrollmentType enrollmentType;
  final OfflineEnrollmentStatus status;
  final String? matriculationNumber;
  final String enrollmentDate;
  final SyncState syncState;

  /// Niveau **de la ligne** (et non des critères de recherche) : ids bruts de
  /// l'inscription et libellés résolus sur le référentiel local.
  ///
  /// Tout est nullable, et pour deux raisons distinctes : l'inscription peut ne
  /// pas encore porter de niveau (brouillon), et le référentiel peut ne pas être
  /// descendu (libellé introuvable alors que l'id est là). Un appelant qui a
  /// besoin d'afficher quelque chose doit donc prévoir le vide.
  final String? schoolLevelId;
  final String? schoolLevelGroupId;
  final String? schoolLevelName;
  final String? schoolLevelGroupName;

  const LocalEnrollmentListItem({
    required this.enrollmentId,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.dateOfBirth,
    required this.gender,
    required this.enrollmentType,
    required this.status,
    this.matriculationNumber,
    required this.enrollmentDate,
    required this.syncState,
    this.schoolLevelId,
    this.schoolLevelGroupId,
    this.schoolLevelName,
    this.schoolLevelGroupName,
  });

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [
    enrollmentId,
    studentId,
    firstName,
    lastName,
    surname,
    dateOfBirth,
    gender,
    enrollmentType,
    status,
    matriculationNumber,
    enrollmentDate,
    syncState,
    schoolLevelId,
    schoolLevelGroupId,
    schoolLevelName,
    schoolLevelGroupName,
  ];
}
