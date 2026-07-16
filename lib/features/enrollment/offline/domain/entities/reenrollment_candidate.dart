import 'package:equatable/equatable.dart';

/// Candidat de **réinscription** lu localement dans `ref_previous_year_students`
/// (cohorte N-1 peuplée par le pull). Sert de **photo de départ** au brouillon
/// RE : identité + matricule (→ `source_ref`) + tuteur dénormalisé + antécédents
/// (ids). L'année cible (`academic_year_id`) n'est PAS ici — elle vient du
/// bootstrap courant au moment du seed.
class ReenrollmentCandidate extends Equatable {
  final String studentId;
  final String matriculationNumber;
  final String firstName;
  final String lastName;
  final String? surname;
  final String gender; // valeur API : MALE|FEMALE|OTHER
  final String dateOfBirth; // yyyy-MM-dd
  final String? birthPlace;
  final String? previousAcademicYearId;
  final String? previousSchoolLevelId;
  final String? previousClassroomId;
  final String? guardianName;
  final String? guardianPhone;
  final int previousBalanceInCents;
  final String? currency;

  const ReenrollmentCandidate({
    required this.studentId,
    required this.matriculationNumber,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.gender,
    required this.dateOfBirth,
    this.birthPlace,
    this.previousAcademicYearId,
    this.previousSchoolLevelId,
    this.previousClassroomId,
    this.guardianName,
    this.guardianPhone,
    this.previousBalanceInCents = 0,
    this.currency,
  });

  @override
  List<Object?> get props => [
    studentId,
    matriculationNumber,
    firstName,
    lastName,
    surname,
    gender,
    dateOfBirth,
    birthPlace,
    previousAcademicYearId,
    previousSchoolLevelId,
    previousClassroomId,
    guardianName,
    guardianPhone,
    previousBalanceInCents,
    currency,
  ];
}
