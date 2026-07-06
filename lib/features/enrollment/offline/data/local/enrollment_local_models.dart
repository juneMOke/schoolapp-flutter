import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';

/// Helpers de (dé)sérialisation sqflite (INTEGER 0/1 ↔ bool).
bool? _boolFromDb(Object? v) => v == null ? null : (v as int) != 0;
int? _boolToDb(bool? v) => v == null ? null : (v ? 1 : 0);

/// Modèle de la table `students` (toMap/fromMap/toEntity).
class StudentLocalModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? surname;
  final String gender;
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
  final String syncStatus;
  final String? syncError;
  final int? syncedAt;
  final int updatedAt;

  const StudentLocalModel({
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
    this.syncStatus = 'PENDING_SYNC',
    this.syncError,
    this.syncedAt,
    this.updatedAt = 0,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'surname': surname,
    'gender': gender,
    'date_of_birth': dateOfBirth,
    'birth_place': birthPlace,
    'nationality': nationality,
    'city': city,
    'district': district,
    'municipality': municipality,
    'neighborhood': neighborhood,
    'address': address,
    'phone_number': phoneNumber,
    'matriculation_number': matriculationNumber,
    'email': email,
    'sync_status': syncStatus,
    'sync_error': syncError,
    'synced_at': syncedAt,
    'updated_at': updatedAt,
  };

  factory StudentLocalModel.fromMap(Map<String, Object?> m) =>
      StudentLocalModel(
        id: m['id'] as String,
        firstName: m['first_name'] as String,
        lastName: m['last_name'] as String,
        surname: m['surname'] as String?,
        gender: m['gender'] as String,
        dateOfBirth: m['date_of_birth'] as String,
        birthPlace: m['birth_place'] as String?,
        nationality: m['nationality'] as String?,
        city: m['city'] as String?,
        district: m['district'] as String?,
        municipality: m['municipality'] as String?,
        neighborhood: m['neighborhood'] as String?,
        address: m['address'] as String?,
        phoneNumber: m['phone_number'] as String?,
        matriculationNumber: m['matriculation_number'] as String?,
        email: m['email'] as String?,
        syncStatus: (m['sync_status'] as String?) ?? 'PENDING_SYNC',
        syncError: m['sync_error'] as String?,
        syncedAt: m['synced_at'] as int?,
        updatedAt: (m['updated_at'] as int?) ?? 0,
      );

  LocalStudent toEntity() => LocalStudent(
    id: id,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    gender: OfflineGender.fromApiValue(gender),
    dateOfBirth: dateOfBirth,
    birthPlace: birthPlace,
    nationality: nationality,
    city: city,
    district: district,
    municipality: municipality,
    neighborhood: neighborhood,
    address: address,
    phoneNumber: phoneNumber,
    matriculationNumber: matriculationNumber,
    email: email,
    syncState: SyncState.fromDbValue(syncStatus),
  );
}

/// Modèle de la table `parents`.
class ParentLocalModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? surname;
  final String phoneNumber;
  final String? email;
  final String? identificationNumber;
  final String syncStatus;
  final int? syncedAt;
  final int updatedAt;

  const ParentLocalModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.phoneNumber,
    this.email,
    this.identificationNumber,
    this.syncStatus = 'PENDING_SYNC',
    this.syncedAt,
    this.updatedAt = 0,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'surname': surname,
    'phone_number': phoneNumber,
    'email': email,
    'identification_number': identificationNumber,
    'sync_status': syncStatus,
    'synced_at': syncedAt,
    'updated_at': updatedAt,
  };

  factory ParentLocalModel.fromMap(Map<String, Object?> m) => ParentLocalModel(
    id: m['id'] as String,
    firstName: m['first_name'] as String,
    lastName: m['last_name'] as String,
    surname: m['surname'] as String?,
    phoneNumber: m['phone_number'] as String,
    email: m['email'] as String?,
    identificationNumber: m['identification_number'] as String?,
    syncStatus: (m['sync_status'] as String?) ?? 'PENDING_SYNC',
    syncedAt: m['synced_at'] as int?,
    updatedAt: (m['updated_at'] as int?) ?? 0,
  );

  LocalParent toEntity(OfflineRelationshipType relationshipType) => LocalParent(
    id: id,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    phoneNumber: phoneNumber,
    email: email,
    identificationNumber: identificationNumber,
    relationshipType: relationshipType,
    syncState: SyncState.fromDbValue(syncStatus),
  );
}

/// Modèle de la table `enrollments`.
class EnrollmentLocalModel {
  final String id;
  final String studentId;
  final String enrollmentType;
  final String status;
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
  final String syncStatus;
  final String? syncError;
  final int? syncedAt;
  final int updatedAt;

  const EnrollmentLocalModel({
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
    this.syncStatus = 'PENDING_SYNC',
    this.syncError,
    this.syncedAt,
    this.updatedAt = 0,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'student_id': studentId,
    'enrollment_type': enrollmentType,
    'status': status,
    'academic_year_id': academicYearId,
    'school_level_id': schoolLevelId,
    'school_level_group_id': schoolLevelGroupId,
    'enrollment_date': enrollmentDate,
    'enrollment_code': enrollmentCode,
    'previous_school_name': previousSchoolName,
    'previous_academic_year': previousAcademicYear,
    'previous_school_level_group': previousSchoolLevelGroup,
    'previous_school_level': previousSchoolLevel,
    'previous_rate': previousRate,
    'previous_rank': previousRank,
    'validated_previous_year': _boolToDb(validatedPreviousYear),
    'transfer_reason': transferReason,
    'cancellation_reason': cancellationReason,
    'emit_document': _boolToDb(emitDocument),
    'sync_status': syncStatus,
    'sync_error': syncError,
    'synced_at': syncedAt,
    'updated_at': updatedAt,
  };

  factory EnrollmentLocalModel.fromMap(Map<String, Object?> m) =>
      EnrollmentLocalModel(
        id: m['id'] as String,
        studentId: m['student_id'] as String,
        enrollmentType: m['enrollment_type'] as String,
        status: m['status'] as String,
        academicYearId: m['academic_year_id'] as String,
        schoolLevelId: m['school_level_id'] as String?,
        schoolLevelGroupId: m['school_level_group_id'] as String?,
        enrollmentDate: m['enrollment_date'] as String,
        enrollmentCode: m['enrollment_code'] as String?,
        previousSchoolName: m['previous_school_name'] as String?,
        previousAcademicYear: m['previous_academic_year'] as String?,
        previousSchoolLevelGroup: m['previous_school_level_group'] as String?,
        previousSchoolLevel: m['previous_school_level'] as String?,
        previousRate: (m['previous_rate'] as num?)?.toDouble(),
        previousRank: m['previous_rank'] as int?,
        validatedPreviousYear: _boolFromDb(m['validated_previous_year']),
        transferReason: m['transfer_reason'] as String?,
        cancellationReason: m['cancellation_reason'] as String?,
        emitDocument: _boolFromDb(m['emit_document']) ?? true,
        syncStatus: (m['sync_status'] as String?) ?? 'PENDING_SYNC',
        syncError: m['sync_error'] as String?,
        syncedAt: m['synced_at'] as int?,
        updatedAt: (m['updated_at'] as int?) ?? 0,
      );

  LocalEnrollment toEntity() => LocalEnrollment(
    id: id,
    studentId: studentId,
    enrollmentType: EnrollmentType.fromApiValue(enrollmentType),
    status: OfflineEnrollmentStatus.fromApiValue(status),
    academicYearId: academicYearId,
    schoolLevelId: schoolLevelId,
    schoolLevelGroupId: schoolLevelGroupId,
    enrollmentDate: enrollmentDate,
    enrollmentCode: enrollmentCode,
    previousSchoolName: previousSchoolName,
    previousAcademicYear: previousAcademicYear,
    previousSchoolLevelGroup: previousSchoolLevelGroup,
    previousSchoolLevel: previousSchoolLevel,
    previousRate: previousRate,
    previousRank: previousRank,
    validatedPreviousYear: validatedPreviousYear,
    transferReason: transferReason,
    cancellationReason: cancellationReason,
    emitDocument: emitDocument,
    syncState: SyncState.fromDbValue(syncStatus),
    syncError: syncError,
  );
}

/// Modèle de la table `generated_documents` (partagé Inscription/Facturation).
class GeneratedDocumentLocalModel {
  final String id;
  final String docDomain;
  final String? enrollmentId;
  final String? paymentId;
  final String? studentId;
  final String docType;
  final String number;
  final String status;
  final String? verificationToken;
  final int createdAt;

  const GeneratedDocumentLocalModel({
    required this.id,
    required this.docDomain,
    this.enrollmentId,
    this.paymentId,
    this.studentId,
    required this.docType,
    required this.number,
    this.status = 'PROVISIONAL',
    this.verificationToken,
    this.createdAt = 0,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'doc_domain': docDomain,
    'enrollment_id': enrollmentId,
    'payment_id': paymentId,
    'student_id': studentId,
    'doc_type': docType,
    'number': number,
    'status': status,
    'verification_token': verificationToken,
    'created_at': createdAt,
  };

  factory GeneratedDocumentLocalModel.fromMap(Map<String, Object?> m) =>
      GeneratedDocumentLocalModel(
        id: m['id'] as String,
        docDomain: m['doc_domain'] as String,
        enrollmentId: m['enrollment_id'] as String?,
        paymentId: m['payment_id'] as String?,
        studentId: m['student_id'] as String?,
        docType: m['doc_type'] as String,
        number: m['number'] as String,
        status: (m['status'] as String?) ?? 'PROVISIONAL',
        verificationToken: m['verification_token'] as String?,
        createdAt: (m['created_at'] as int?) ?? 0,
      );

  LocalGeneratedDocument toEntity() => LocalGeneratedDocument(
    id: id,
    docDomain: docDomain,
    enrollmentId: enrollmentId,
    paymentId: paymentId,
    studentId: studentId,
    docType: docType,
    number: number,
    status: status,
    verificationToken: verificationToken,
  );
}
