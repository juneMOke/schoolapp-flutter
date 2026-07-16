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
  ];
}
