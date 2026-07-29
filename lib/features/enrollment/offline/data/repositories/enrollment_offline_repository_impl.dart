import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_dao_support.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_draft_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/enrollment_local_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_read_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_seed_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Implémentation offline-first : les écritures passent par la transaction
/// locale du DAO (retour immédiat) puis déclenchent un flush opportuniste ;
/// les lectures sont servies depuis sqflite.
class EnrollmentOfflineRepositoryImpl implements EnrollmentOfflineRepository {
  final EnrollmentReadDao _readDao;
  final EnrollmentDraftDao _draftDao;
  final EnrollmentSeedDao _seedDao;
  final IdGenerator _idGenerator;
  final SyncEngine _syncEngine;
  final CurrentUserContext? _currentUser;
  final int Function() _now;

  EnrollmentOfflineRepositoryImpl({
    required EnrollmentReadDao readDao,
    required EnrollmentDraftDao draftDao,
    required EnrollmentSeedDao seedDao,
    required IdGenerator idGenerator,
    required SyncEngine syncEngine,
    CurrentUserContext? currentUser,
    int Function()? now,
  }) : _readDao = readDao,
       _draftDao = draftDao,
       _seedDao = seedDao,
       _idGenerator = idGenerator,
       _syncEngine = syncEngine,
       _currentUser = currentUser,
       _now = now ?? systemClock;

  // ── Wizard offline-first : brouillon local persisté (M1) ────────────────────

  @override
  DraftIds startDraft({String? existingStudentId}) => DraftIds(
    enrollmentId: _idGenerator.newId(),
    studentId: existingStudentId ?? _idGenerator.newId(),
  );

  @override
  Future<Either<Failure, DraftIds>> seedDraft(
    ConfirmEnrollmentDraft seed, {
    String? enrollmentId,
  }) async {
    try {
      final now = _now();
      // Garde anti double-réinscription (backstop DUR) : un seed FRAIS
      // (`enrollmentId` non fourni → nouvel uuid) pour un élève CANONIQUE
      // (`studentId` connu = RE) est refusé si un dossier local existe déjà pour
      // cet élève sur l'année cible. Indépendant de la superposition de la liste
      // (qui peut être périmée ou scoper une autre année) — l'année d'écriture
      // (`seed.academicYearId` = bootstrap) est la même que celle interrogée.
      final studentId = seed.studentId;
      if (enrollmentId == null && studentId != null) {
        final existing = await _readDao.findLocalDossierRefForStudentYear(
          studentId: studentId,
          academicYearId: seed.academicYearId,
        );
        if (existing != null) {
          return const Left(
            ValidationFailure(
              'Cet élève a déjà un dossier pour l\'année en cours',
            ),
          );
        }
      }
      final ids = DraftIds(
        enrollmentId: enrollmentId ?? _idGenerator.newId(),
        studentId: seed.studentId ?? _idGenerator.newId(),
      );

      final seeded = await _draftDao.seedDraft(
        student: StudentLocalModel(
          id: ids.studentId,
          firstName: seed.firstName,
          lastName: seed.lastName,
          surname: seed.surname,
          gender: seed.gender,
          dateOfBirth: seed.dateOfBirth,
          birthPlace: seed.birthPlace,
          nationality: seed.nationality,
          city: seed.city,
          district: seed.district,
          municipality: seed.municipality,
          neighborhood: seed.neighborhood,
          address: seed.address,
          phoneNumber: seed.phoneNumber,
          matriculationNumber: seed.matriculationNumber,
          updatedAt: now,
        ),
        enrollment: EnrollmentLocalModel(
          id: ids.enrollmentId,
          studentId: ids.studentId,
          enrollmentType: seed.enrollmentType,
          status: seed.status,
          academicYearId: seed.academicYearId,
          schoolLevelId: seed.schoolLevelId,
          schoolLevelGroupId: seed.schoolLevelGroupId,
          enrollmentDate: seed.enrollmentDate,
          sourceRef: seed.sourceRef,
          previousSchoolName: seed.previousSchoolName,
          previousAcademicYear: seed.previousAcademicYear,
          previousSchoolLevelGroup: seed.previousSchoolLevelGroup,
          previousSchoolLevel: seed.previousSchoolLevel,
          previousSchoolLevelId: seed.previousSchoolLevelId,
          previousRate: seed.previousRate,
          previousRank: seed.previousRank,
          validatedPreviousYear: seed.validatedPreviousYear,
          transferReason: seed.transferReason,
          emitDocument: seed.emitDocument,
          updatedAt: now,
        ),
        parents: seed.parents
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
            .toList(),
        nowMs: now,
      );
      if (!seeded) {
        return const Left(
          ValidationFailure('Dossier local déjà confirmé (non ré-ouvrable)'),
        );
      }
      return Right(ids);
    } catch (e) {
      return Left(StorageFailure('Échec de l\'amorçage du brouillon : $e'));
    }
  }

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
    await _draftDao.insertDraftStudent(
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
    await _draftDao.insertDraftEnrollment(
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
    () => _draftDao.updateDraftStudentColumns(studentId, <String, Object?>{
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
    return _draftDao
        .updateDraftEnrollmentColumns(enrollmentId, <String, Object?>{
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
    () =>
        _draftDao.updateDraftEnrollmentColumns(enrollmentId, <String, Object?>{
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
    return _draftDao.replaceDraftParents(studentId, drafts, nowMs: now);
  });

  @override
  Future<Either<Failure, LocalEnrollmentDetail>> getDraftDetail(
    String enrollmentId,
  ) => getDetail(enrollmentId);

  @override
  Future<Either<Failure, Unit>> finalizeDraft({
    required String enrollmentId,
    bool emitDocument = true,
    String? finalStatus,
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
      final ok = await _draftDao.finalizeDraft(
        enrollmentId,
        document: document,
        emitDocument: emitDocument,
        authorId: _currentUser?.uid, // estampillage authorId (ADR-010 D-05)
        nowMs: now,
        finalStatus: finalStatus,
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
    String? academicYearId,
    String? enrollmentType,
  }) => _guardList(
    () => _readDao.getEnrollments(
      status: status,
      academicYearId: academicYearId,
      enrollmentType: enrollmentType,
    ),
  );

  @override
  Future<Either<Failure, List<LocalEnrollmentListItem>>> searchByAcademicInfo({
    String? status,
    String? academicYearId,
    String? schoolLevelId,
    String? schoolLevelGroupId,
    String? enrollmentType,
  }) => _guardList(
    () => _readDao.searchByAcademicInfo(
      status: status,
      academicYearId: academicYearId,
      schoolLevelId: schoolLevelId,
      schoolLevelGroupId: schoolLevelGroupId,
      enrollmentType: enrollmentType,
    ),
  );

  @override
  Future<Either<Failure, List<LocalEnrollmentListItem>>>
  searchCurrentYearEnrolledByAcademicInfo({
    String? academicYearId,
    String? schoolLevelId,
    String? schoolLevelGroupId,
  }) => _guardList(() async {
    // Année passée par l'appelant (bootstrap Facturation) sinon année courante
    // locale. Non résolue (référentiel non pullé) → aucun résultat : la
    // recherche est intrinsèquement scopée à une année.
    final yearId = academicYearId ?? await _seedDao.findCurrentAcademicYearId();
    if (yearId == null) return const <LocalEnrollmentListItem>[];
    return _readDao.searchEnrolledByAcademicInfo(
      academicYearId: yearId,
      schoolLevelId: schoolLevelId,
      schoolLevelGroupId: schoolLevelGroupId,
    );
  });

  @override
  Future<Either<Failure, LocalDossierRef?>> probeLocalReenrollmentDossier({
    required String studentId,
    required String academicYearId,
  }) => _guardRead(
    () => _readDao.findLocalDossierRefForStudentYear(
      studentId: studentId,
      academicYearId: academicYearId,
    ),
  );

  @override
  Future<Either<Failure, ReenrollmentSearchResult>> searchReenrollmentCohort({
    String? schoolLevelId,
    String? schoolLevelGroupId,
  }) => _guardRead(() async {
    final candidates = await _seedDao.searchReenrollmentCandidates(
      schoolLevelId: schoolLevelId,
      schoolLevelGroupId: schoolLevelGroupId,
    );
    // Superposition scopée à l'année COURANTE : sinon le dossier N-1 (terminé)
    // d'un élève masquerait à tort son candidat de réinscription pour l'année
    // N. Année non résolue (référentiel non pullé) → aucun overlay (le vivier
    // s'affiche seul, tap → seed).
    final currentYearId = await _seedDao.findCurrentAcademicYearId();
    final localDossiers = currentYearId == null
        ? const <LocalEnrollmentListItem>[]
        : await _readDao.getEnrollments(academicYearId: currentYearId);
    return ReenrollmentSearchResult(
      candidates: candidates,
      localDossiers: localDossiers,
    );
  });

  @override
  Future<Either<Failure, PreEnrollmentSearchResult>> searchPreEnrollmentCohort({
    String? schoolLevelId,
    String? schoolLevelGroupId,
  }) => _guardRead(() async {
    final candidates = await _seedDao.searchPreEnrollmentCandidates(
      schoolLevelId: schoolLevelId,
      schoolLevelGroupId: schoolLevelGroupId,
    );
    // Même principe que searchReenrollmentCohort : superposition scopée à
    // l'année COURANTE, sinon un dossier PRE d'une autre année masquerait à
    // tort le candidat pour l'année N.
    final currentYearId = await _seedDao.findCurrentAcademicYearId();
    final localDossiers = currentYearId == null
        ? const <LocalEnrollmentListItem>[]
        : await _readDao.getEnrollments(academicYearId: currentYearId);
    return PreEnrollmentSearchResult(
      candidates: candidates,
      localDossiers: localDossiers,
    );
  });

  @override
  Future<Either<Failure, LocalEnrollmentDetail>> getDetail(
    String enrollmentId,
  ) => _guardReadRequired(
    () => _readDao.getDetail(enrollmentId),
    notFoundMessage: 'Dossier introuvable en local',
  );

  @override
  Future<Either<Failure, ReenrollmentCandidate>> getReenrollmentCandidate(
    String studentId,
  ) => _guardReadRequired(
    () => _seedDao.findReenrollmentCandidateByStudentId(studentId),
    notFoundMessage: 'Candidat de réinscription introuvable en local',
  );

  @override
  Future<Either<Failure, PreEnrollmentCandidate>> getPreEnrollment(
    String preEnrollmentId,
  ) => _guardReadRequired(
    () => _seedDao.findPreEnrollmentById(preEnrollmentId),
    notFoundMessage: 'Préinscription introuvable en local',
  );

  Future<Either<Failure, List<LocalEnrollmentListItem>>> _guardList(
    Future<List<LocalEnrollmentListItem>> Function() run,
  ) => _guardRead(run);

  /// Encapsule une lecture locale en `Either` : StorageFailure sur exception
  /// (parité avec les écritures). Un `null` est propagé tel quel (résultat
  /// licite — ex. sonde « aucun dossier »).
  Future<Either<Failure, T>> _guardRead<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } catch (e) {
      return Left(StorageFailure('Lecture locale impossible : $e'));
    }
  }

  /// Variante « présence requise » : un résultat `null` devient un
  /// NotFoundFailure porteur de [notFoundMessage].
  Future<Either<Failure, T>> _guardReadRequired<T>(
    Future<T?> Function() run, {
    required String notFoundMessage,
  }) async {
    try {
      final value = await run();
      if (value == null) return Left(NotFoundFailure(notFoundMessage));
      return Right(value);
    } catch (e) {
      return Left(StorageFailure('Lecture locale impossible : $e'));
    }
  }
}
