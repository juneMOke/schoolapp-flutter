import 'package:equatable/equatable.dart';

/// Préinscription lue localement dans `ref_pre_enrollments` (snapshot en ligne
/// peuplé par le pull). Sert de **photo de départ** au brouillon PRE : identité
/// + niveau souhaité + tuteur dénormalisé. L'`id` de préinscription est conservé
/// comme id d'inscription (idempotence G2) et comme `source_ref`. L'année cible
/// vient du bootstrap courant au moment du seed.
class PreEnrollmentCandidate extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? surname;
  final String? gender; // valeur API : MALE|FEMALE|OTHER
  final String? dateOfBirth; // yyyy-MM-dd
  final String? birthPlace;
  final String? desiredSchoolLevelId;
  final String? guardianName;
  final String? guardianPhone;

  const PreEnrollmentCandidate({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.surname,
    this.gender,
    this.dateOfBirth,
    this.birthPlace,
    this.desiredSchoolLevelId,
    this.guardianName,
    this.guardianPhone,
  });

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    surname,
    gender,
    dateOfBirth,
    birthPlace,
    desiredSchoolLevelId,
    guardianName,
    guardianPhone,
  ];
}
