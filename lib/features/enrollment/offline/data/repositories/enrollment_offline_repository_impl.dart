import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/enrollment_local_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/enrollment_local_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Implémentation offline-first : les écritures passent par la transaction
/// locale du DAO (retour immédiat) puis déclenchent un flush opportuniste ;
/// les lectures sont servies depuis sqflite.
class EnrollmentOfflineRepositoryImpl implements EnrollmentOfflineRepository {
  final EnrollmentLocalDao _dao;
  final IdGenerator _idGenerator;
  final SyncEngine _syncEngine;
  final int Function() _now;

  EnrollmentOfflineRepositoryImpl({
    required EnrollmentLocalDao dao,
    required IdGenerator idGenerator,
    required SyncEngine syncEngine,
    int Function()? now,
  }) : _dao = dao,
       _idGenerator = idGenerator,
       _syncEngine = syncEngine,
       _now = now ?? systemClock;

  @override
  Future<Either<Failure, String>> confirmEnrollment(
    ConfirmEnrollmentDraft draft,
  ) async {
    try {
      final now = _now();
      final studentId = draft.studentId ?? _idGenerator.newId();
      final enrollmentId = _idGenerator.newId();

      final student = StudentLocalModel(
        id: studentId,
        firstName: draft.firstName,
        lastName: draft.lastName,
        surname: draft.surname,
        gender: draft.gender,
        dateOfBirth: draft.dateOfBirth,
        birthPlace: draft.birthPlace,
        nationality: draft.nationality,
        city: draft.city,
        district: draft.district,
        municipality: draft.municipality,
        neighborhood: draft.neighborhood,
        address: draft.address,
        phoneNumber: draft.phoneNumber,
        matriculationNumber: draft.matriculationNumber,
        updatedAt: now,
      );

      final enrollment = EnrollmentLocalModel(
        id: enrollmentId,
        studentId: studentId,
        enrollmentType: draft.enrollmentType,
        status: draft.status,
        academicYearId: draft.academicYearId,
        schoolLevelId: draft.schoolLevelId,
        schoolLevelGroupId: draft.schoolLevelGroupId,
        enrollmentDate: draft.enrollmentDate,
        previousSchoolName: draft.previousSchoolName,
        previousAcademicYear: draft.previousAcademicYear,
        previousSchoolLevelGroup: draft.previousSchoolLevelGroup,
        previousSchoolLevel: draft.previousSchoolLevel,
        previousRate: draft.previousRate,
        previousRank: draft.previousRank,
        validatedPreviousYear: draft.validatedPreviousYear,
        transferReason: draft.transferReason,
        emitDocument: draft.emitDocument,
        updatedAt: now,
      );

      final parents = draft.parents
          .map(
            (p) => ParentDraft(
              parent: ParentLocalModel(
                id: _idGenerator.newId(),
                firstName: p.firstName,
                lastName: p.lastName,
                surname: p.surname,
                phoneNumber: p.phoneNumber,
                email: p.email,
                updatedAt: now,
              ),
              relationshipType: p.relationshipType,
            ),
          )
          .toList();

      final document = draft.emitDocument
          ? GeneratedDocumentLocalModel(
              id: _idGenerator.newId(),
              docDomain: 'ENROLLMENT',
              enrollmentId: enrollmentId,
              studentId: studentId,
              docType: 'AI',
              number: 'PROV-${enrollmentId.substring(0, 8).toUpperCase()}',
              createdAt: now,
            )
          : null;

      await _dao.confirmEnrollment(
        student: student,
        enrollment: enrollment,
        parents: parents,
        document: document,
        outboxEntryId: _idGenerator.newId(),
        nowMs: now,
      );

      // Flush opportuniste (n'attend pas l'ACK : retour UI immédiat).
      unawaited(_syncEngine.flush());
      return Right(enrollmentId);
    } catch (e) {
      return Left(StorageFailure('Échec de la confirmation locale : $e'));
    }
  }

  // ── Wizard offline-first : brouillon local persisté (M1) ────────────────────

  @override
  DraftIds startDraft({String? existingStudentId}) => DraftIds(
    enrollmentId: _idGenerator.newId(),
    studentId: existingStudentId ?? _idGenerator.newId(),
  );

  @override
  Future<Either<Failure, Unit>> saveDraftIdentity({
    required String enrollmentId,
    required String studentId,
    required String firstName,
    required String lastName,
    String? surname,
    required String gender,
    required String dateOfBirth,
    String? birthPlace,
    String? nationality,
    String? matriculationNumber,
    required String enrollmentType,
    required String status,
    required String academicYearId,
    String? schoolLevelId,
    String? schoolLevelGroupId,
    required String enrollmentDate,
  }) => _guardUnit(() async {
    final now = _now();
    await _dao.insertDraftStudent(
      StudentLocalModel(
        id: studentId,
        firstName: firstName,
        lastName: lastName,
        surname: surname,
        gender: gender,
        dateOfBirth: dateOfBirth,
        birthPlace: birthPlace,
        nationality: nationality,
        matriculationNumber: matriculationNumber,
        updatedAt: now,
      ),
    );
    await _dao.insertDraftEnrollment(
      EnrollmentLocalModel(
        id: enrollmentId,
        studentId: studentId,
        enrollmentType: enrollmentType,
        status: status,
        academicYearId: academicYearId,
        schoolLevelId: schoolLevelId,
        schoolLevelGroupId: schoolLevelGroupId,
        enrollmentDate: enrollmentDate,
        updatedAt: now,
      ),
    );
  });

  @override
  Future<Either<Failure, Unit>> saveDraftAddress({
    required String studentId,
    String? city,
    String? district,
    String? municipality,
    String? neighborhood,
    String? address,
    String? phoneNumber,
  }) => _guardUnit(
    () => _dao.updateDraftStudentColumns(studentId, <String, Object?>{
      'city': ?city,
      'district': ?district,
      'municipality': ?municipality,
      'neighborhood': ?neighborhood,
      'address': ?address,
      'phone_number': ?phoneNumber,
    }, nowMs: _now()),
  );

  @override
  Future<Either<Failure, Unit>> saveDraftPreviousAcademic({
    required String enrollmentId,
    String? previousSchoolName,
    String? previousAcademicYear,
    String? previousSchoolLevelGroup,
    String? previousSchoolLevel,
    double? previousRate,
    int? previousRank,
    bool? validatedPreviousYear,
    String? transferReason,
  }) => _guardUnit(() {
    final validated = validatedPreviousYear == null
        ? null
        : (validatedPreviousYear ? 1 : 0);
    return _dao.updateDraftEnrollmentColumns(enrollmentId, <String, Object?>{
      'previous_school_name': ?previousSchoolName,
      'previous_academic_year': ?previousAcademicYear,
      'previous_school_level_group': ?previousSchoolLevelGroup,
      'previous_school_level': ?previousSchoolLevel,
      'previous_rate': ?previousRate,
      'previous_rank': ?previousRank,
      'validated_previous_year': ?validated,
      'transfer_reason': ?transferReason,
    }, nowMs: _now());
  });

  @override
  Future<Either<Failure, Unit>> saveDraftTargetAcademic({
    required String enrollmentId,
    String? schoolLevelId,
    String? schoolLevelGroupId,
  }) => _guardUnit(
    () => _dao.updateDraftEnrollmentColumns(enrollmentId, <String, Object?>{
      'school_level_id': ?schoolLevelId,
      'school_level_group_id': ?schoolLevelGroupId,
    }, nowMs: _now()),
  );

  @override
  Future<Either<Failure, Unit>> saveDraftGuardians({
    required String studentId,
    required List<ConfirmParentDraft> parents,
  }) => _guardUnit(() {
    final now = _now();
    final drafts = parents
        .map(
          (p) => ParentDraft(
            parent: ParentLocalModel(
              id: _idGenerator.newId(),
              firstName: p.firstName,
              lastName: p.lastName,
              surname: p.surname,
              phoneNumber: p.phoneNumber,
              email: p.email,
              updatedAt: now,
            ),
            relationshipType: p.relationshipType,
          ),
        )
        .toList();
    return _dao.replaceDraftParents(studentId, drafts, nowMs: now);
  });

  @override
  Future<Either<Failure, LocalEnrollmentDetail>> getDraftDetail(
    String enrollmentId,
  ) => getDetail(enrollmentId);

  @override
  Future<Either<Failure, Unit>> finalizeDraft({
    required String enrollmentId,
    bool emitDocument = true,
  }) async {
    try {
      final now = _now();
      final document = emitDocument
          ? GeneratedDocumentLocalModel(
              id: _idGenerator.newId(),
              docDomain: 'ENROLLMENT',
              enrollmentId: enrollmentId,
              docType: 'AI',
              number: 'PROV-${enrollmentId.substring(0, 8).toUpperCase()}',
              createdAt: now,
            )
          : null;
      final ok = await _dao.finalizeDraft(
        enrollmentId,
        document: document,
        emitDocument: emitDocument,
        nowMs: now,
      );
      if (!ok) {
        return const Left(
          NotFoundFailure('Brouillon introuvable ou déjà confirmé'),
        );
      }
      // Flush opportuniste (n'attend pas l'ACK : retour UI immédiat).
      unawaited(_syncEngine.flush());
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure('Échec de la confirmation locale : $e'));
    }
  }

  /// Encapsule une écriture locale sans valeur de retour en `Either` (parité
  /// avec `_guardList` : StorageFailure sur exception).
  Future<Either<Failure, Unit>> _guardUnit(Future<void> Function() run) async {
    try {
      await run();
      return const Right(unit);
    } catch (e) {
      return Left(
        StorageFailure('Échec de l\'enregistrement du brouillon : $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<LocalEnrollmentListItem>>> getEnrollments({
    String? status,
  }) => _guardList(() => _dao.getEnrollments(status: status));

  @override
  Future<Either<Failure, List<LocalEnrollmentListItem>>> searchByName(
    String query,
  ) => _guardList(() => _dao.searchByName(query));

  @override
  Future<Either<Failure, List<LocalEnrollmentListItem>>> searchByDateOfBirth(
    String dateOfBirth,
  ) => _guardList(() => _dao.searchByDateOfBirth(dateOfBirth));

  @override
  Future<Either<Failure, List<LocalEnrollmentListItem>>> searchByAcademicInfo({
    String? academicYearId,
    String? schoolLevelId,
    String? schoolLevelGroupId,
  }) => _guardList(
    () => _dao.searchByAcademicInfo(
      academicYearId: academicYearId,
      schoolLevelId: schoolLevelId,
      schoolLevelGroupId: schoolLevelGroupId,
    ),
  );

  @override
  Future<Either<Failure, LocalEnrollmentDetail>> getDetail(
    String enrollmentId,
  ) async {
    try {
      final detail = await _dao.getDetail(enrollmentId);
      if (detail == null) {
        return const Left(NotFoundFailure('Dossier introuvable en local'));
      }
      return Right(detail);
    } catch (e) {
      return Left(StorageFailure('Lecture locale impossible : $e'));
    }
  }

  Future<Either<Failure, List<LocalEnrollmentListItem>>> _guardList(
    Future<List<LocalEnrollmentListItem>> Function() run,
  ) async {
    try {
      return Right(await run());
    } catch (e) {
      return Left(StorageFailure('Lecture locale impossible : $e'));
    }
  }
}
