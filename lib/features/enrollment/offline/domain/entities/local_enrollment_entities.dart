import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';

/// Élève lu depuis sqflite (miroir local). `matriculationNumber`/`email` sont
/// null hors-ligne (« en cours d'attribution »).
class LocalStudent extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? surname;
  final OfflineGender gender;
  final String dateOfBirth;
  final String? birthPlace;
  final String? nationality;
  final String? city;
  final String? district;
  final String? municipality;
  final String? neighborhood;
  final String? address;
  final String? phoneNumber;
  final String? matriculationNumber;
  final String? email;
  final SyncState syncState;

  const LocalStudent({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.gender,
    required this.dateOfBirth,
    this.birthPlace,
    this.nationality,
    this.city,
    this.district,
    this.municipality,
    this.neighborhood,
    this.address,
    this.phoneNumber,
    this.matriculationNumber,
    this.email,
    this.syncState = SyncState.pendingSync,
  });

  bool get hasMatricule =>
      matriculationNumber != null && matriculationNumber!.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    surname,
    gender,
    dateOfBirth,
    birthPlace,
    nationality,
    city,
    district,
    municipality,
    neighborhood,
    address,
    phoneNumber,
    matriculationNumber,
    email,
    syncState,
  ];
}

/// Tuteur lu depuis sqflite. `id` provisoire avant l'ACK, canonique après remap.
class LocalParent extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? surname;
  final String phoneNumber;
  final String? email;
  final String? identificationNumber;
  final OfflineRelationshipType relationshipType;
  final SyncState syncState;

  const LocalParent({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.phoneNumber,
    this.email,
    this.identificationNumber,
    this.relationshipType = OfflineRelationshipType.other,
    this.syncState = SyncState.pendingSync,
  });

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    surname,
    phoneNumber,
    email,
    identificationNumber,
    relationshipType,
    syncState,
  ];
}

/// Dossier d'inscription lu depuis sqflite.
class LocalEnrollment extends Equatable {
  final String id;
  final String studentId;
  final EnrollmentType enrollmentType;
  final OfflineEnrollmentStatus status;
  final String academicYearId;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;
  final String enrollmentDate;
  final String? enrollmentCode;
  final String? previousSchoolName;
  final String? previousAcademicYear;
  final String? previousSchoolLevelGroup;
  final String? previousSchoolLevel;
  final double? previousRate;
  final int? previousRank;
  final bool? validatedPreviousYear;
  final String? transferReason;
  final String? cancellationReason;
  final bool emitDocument;
  final SyncState syncState;
  final String? syncError;

  const LocalEnrollment({
    required this.id,
    required this.studentId,
    required this.enrollmentType,
    required this.status,
    required this.academicYearId,
    this.schoolLevelId,
    this.schoolLevelGroupId,
    required this.enrollmentDate,
    this.enrollmentCode,
    this.previousSchoolName,
    this.previousAcademicYear,
    this.previousSchoolLevelGroup,
    this.previousSchoolLevel,
    this.previousRate,
    this.previousRank,
    this.validatedPreviousYear,
    this.transferReason,
    this.cancellationReason,
    this.emitDocument = true,
    this.syncState = SyncState.pendingSync,
    this.syncError,
  });

  @override
  List<Object?> get props => [
    id,
    studentId,
    enrollmentType,
    status,
    academicYearId,
    schoolLevelId,
    schoolLevelGroupId,
    enrollmentDate,
    enrollmentCode,
    previousSchoolName,
    previousAcademicYear,
    previousSchoolLevelGroup,
    previousSchoolLevel,
    previousRate,
    previousRank,
    validatedPreviousYear,
    transferReason,
    cancellationReason,
    emitDocument,
    syncState,
    syncError,
  ];
}

/// Document généré (attestation AI, reçu RC…), provisoire ou définitif.
class LocalGeneratedDocument extends Equatable {
  final String id;
  final String docDomain; // ENROLLMENT | PAYMENT
  final String? enrollmentId;
  final String? paymentId;
  final String? studentId;
  final String docType; // AI | RC | NP
  final String number; // PROV-… | ETL-…
  final String status; // PROVISIONAL | DEFINITIVE
  final String? verificationToken;

  const LocalGeneratedDocument({
    required this.id,
    required this.docDomain,
    this.enrollmentId,
    this.paymentId,
    this.studentId,
    required this.docType,
    required this.number,
    required this.status,
    this.verificationToken,
  });

  bool get isProvisional => status == 'PROVISIONAL';

  @override
  List<Object?> get props => [
    id,
    docDomain,
    enrollmentId,
    paymentId,
    studentId,
    docType,
    number,
    status,
    verificationToken,
  ];
}

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

/// Détail complet d'un dossier (inscription + élève + tuteurs + documents).
class LocalEnrollmentDetail extends Equatable {
  final LocalEnrollment enrollment;
  final LocalStudent student;
  final List<LocalParent> parents;
  final List<LocalGeneratedDocument> documents;

  const LocalEnrollmentDetail({
    required this.enrollment,
    required this.student,
    this.parents = const [],
    this.documents = const [],
  });

  @override
  List<Object?> get props => [enrollment, student, parents, documents];
}
