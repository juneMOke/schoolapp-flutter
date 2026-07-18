import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_case_aggregate_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_case_input_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_comment_input_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_comment_row.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/offline_disciplinary_case_row.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/disciplinary_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_comment.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/offline_disciplinary_case.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/disciplinary_case_offline_repository.dart';

/// Type d'agrégat d'outbox (routage vers `DisciplinaryCaseOutboxHandler`).
const String kDisciplinaryAggregateType = 'DISCIPLINARY_CASE';

/// Implémentation offline-first des cas disciplinaires (DF-1/2/B).
///
/// **Un seul chemin de push** : l'agrégat `{case, comments[]}` (upsert `/sync`).
/// Création, évolution (status/sanction) et ajout de commentaire ré-enfilent le
/// **même** id d'outbox (`DISCIPLINARY_CASE:{caseId}`, opération UPSERT), qui se
/// coalesce (`ConflictAlgorithm.replace`) sur l'état courant. Chaque évolution —
/// commentaire compris — bumpe `case.updated_at` (DF-F).
class DisciplinaryCaseOfflineRepositoryImpl
    implements DisciplinaryCaseOfflineRepository {
  final DisciplinaryLocalDataSource localDataSource;
  final IdGenerator idGenerator;
  final Clock now;

  const DisciplinaryCaseOfflineRepositoryImpl({
    required this.localDataSource,
    required this.idGenerator,
    this.now = systemClock,
  });

  /// Id d'outbox déterministe **unique par cas** (coalescing des re-pushes).
  static String aggregateOutboxId(String caseId) =>
      '$kDisciplinaryAggregateType:$caseId';

  /// Horloge **monotone** par cas : `clientUpdatedAt` doit toujours être ≥ à
  /// l'`updated_at` déjà en base, sinon la garde LWW (écriture locale ET
  /// `markAggregateSynced`) sauterait et l'édition serait perdue en silence — ce
  /// qui arrive dès qu'une ligne a été seedée par un pull au temps serveur
  /// (souvent > horloge device). On avance donc à `local + 1` si l'horloge
  /// recule/est en retard.
  int _monotonic(int nowMs, int localUpdatedAt) =>
      nowMs > localUpdatedAt ? nowMs : localUpdatedAt + 1;

  DisciplinaryCaseInputModel _caseInput(
    OfflineDisciplinaryCaseRow row, {
    required String status,
    required String? sanction,
    required int clientUpdatedAtMs,
  }) => DisciplinaryCaseInputModel(
    id: row.id,
    studentId: row.studentId,
    academicYearId: row.academicYearId,
    category: row.category,
    severity: row.severity,
    title: row.title,
    content: row.content,
    disciplinaryCaseDate: row.disciplinaryCaseDate,
    status: status,
    sanction: sanction,
    clientUpdatedAt: EpochIsoHelper.toIso(clientUpdatedAtMs),
  );

  OutboxEntry _entry({
    required String caseId,
    required DisciplinaryCaseInputModel caseInput,
    required List<DisciplinaryCommentRow> comments,
    required int createdAt,
  }) => OutboxEntry(
    id: aggregateOutboxId(caseId),
    aggregateType: kDisciplinaryAggregateType,
    aggregateId: caseId,
    operation: OutboxOperation.upsert,
    payload: DisciplinaryCaseAggregateRequestModel(
      caseInput: caseInput,
      comments: comments
          .map(DisciplinaryCommentInputModel.fromRow)
          .toList(growable: false),
    ).toJsonString(),
    createdAt: createdAt,
  );

  @override
  Future<Either<Failure, OfflineDisciplinaryCase>> createCase({
    required String studentId,
    required String studentFirstName,
    required String studentLastName,
    String? studentMiddleName,
    required StudentGender studentGender,
    required DateTime disciplinaryCaseDate,
    required String academicYearId,
    required String title,
    required String content,
    required DisciplinaryCategory category,
    required DisciplinarySeverity severity,
    DisciplinarySanction? sanction,
  }) async {
    try {
      final nowMs = now();
      final id = idGenerator.newId();
      final row = OfflineDisciplinaryCaseRow(
        id: id,
        studentId: studentId,
        studentFirstName: studentFirstName,
        studentLastName: studentLastName,
        studentMiddleName: studentMiddleName,
        studentGender: studentGender.toApiValue(),
        academicYearId: academicYearId,
        disciplinaryCaseDate: DateOnlyJsonHelper.toJson(disciplinaryCaseDate),
        title: title,
        content: content,
        category: category.toApiValue(),
        severity: severity.toApiValue(),
        status: DisciplinaryStatus.open.toApiValue(),
        sanction: sanction?.toApiValue(),
        updatedAt: nowMs,
        syncStatus: SyncState.pendingSync.dbValue,
      );

      final entry = _entry(
        caseId: id,
        caseInput: DisciplinaryCaseInputModel.fromRow(row),
        comments: const [],
        createdAt: nowMs,
      );

      await localDataSource.createCaseWithOutbox(row: row, outboxEntry: entry);
      return Right(row.toEntity());
    } catch (_) {
      return const Left(StorageFailure('Local disciplinary create failed'));
    }
  }

  @override
  Future<Either<Failure, void>> updateCase({
    required String caseId,
    required DisciplinaryStatus status,
    DisciplinarySanction? sanction,
    int? expectedVersion,
  }) async {
    try {
      final existing = await localDataSource.getCase(caseId);
      if (existing == null) {
        return const Left(NotFoundFailure('Disciplinary case not found'));
      }
      final effectiveMs = _monotonic(now(), existing.updatedAt);
      final comments = await localDataSource.getCommentsForCase(caseId);
      final entry = _entry(
        caseId: caseId,
        caseInput: _caseInput(
          existing,
          status: status.toApiValue(),
          sanction: sanction?.toApiValue(),
          clientUpdatedAtMs: effectiveMs,
        ),
        comments: comments,
        createdAt: effectiveMs,
      );

      await localDataSource.updateCaseWithOutbox(
        caseId: caseId,
        status: status.toApiValue(),
        sanction: sanction?.toApiValue(),
        updatedAt: effectiveMs,
        outboxEntry: entry,
      );
      return const Right(null);
    } catch (_) {
      return const Left(StorageFailure('Local disciplinary update failed'));
    }
  }

  @override
  Future<Either<Failure, DisciplinaryComment>> addComment({
    required String caseId,
    required String content,
    String? authorName,
  }) async {
    try {
      final existing = await localDataSource.getCase(caseId);
      if (existing == null) {
        return const Left(NotFoundFailure('Disciplinary case not found'));
      }
      final nowMs = now();
      final effectiveMs = _monotonic(nowMs, existing.updatedAt);
      final comment = DisciplinaryCommentRow(
        id: idGenerator.newId(),
        disciplinaryCaseId: caseId,
        content: content,
        authorName: authorName,
        createdAt: nowMs,
        syncStatus: SyncState.pendingSync.dbValue,
      );
      final existingComments = await localDataSource.getCommentsForCase(caseId);
      final entry = _entry(
        caseId: caseId,
        // Le cas ne change pas de FAIT ni de traitement : seul `clientUpdatedAt`
        // est bumpé (DF-F) pour rendre la racine re-pullable. Horloge monotone.
        caseInput: _caseInput(
          existing,
          status: existing.status,
          sanction: existing.sanction,
          clientUpdatedAtMs: effectiveMs,
        ),
        comments: [...existingComments, comment],
        createdAt: effectiveMs,
      );

      await localDataSource.addCommentWithCaseBump(
        comment: comment,
        caseUpdatedAt: effectiveMs,
        outboxEntry: entry,
      );
      return Right(comment.toEntity());
    } catch (_) {
      return const Left(StorageFailure('Local disciplinary comment failed'));
    }
  }

  @override
  Future<Either<Failure, List<OfflineDisciplinaryCase>>> getCasesForStudent({
    required String studentId,
    required String academicYearId,
  }) async {
    try {
      final rows = await localDataSource.getCasesForStudent(
        studentId: studentId,
        academicYearId: academicYearId,
      );
      return Right(rows.map((r) => r.toEntity()).toList(growable: false));
    } catch (_) {
      return const Left(StorageFailure('Local disciplinary read failed'));
    }
  }

  @override
  Future<Either<Failure, OfflineDisciplinaryCase>> getCase({
    required String caseId,
  }) async {
    try {
      final row = await localDataSource.getCase(caseId);
      if (row == null) {
        return const Left(NotFoundFailure('Disciplinary case not found'));
      }
      return Right(row.toEntity());
    } catch (_) {
      return const Left(StorageFailure('Local disciplinary read failed'));
    }
  }

  @override
  Future<Either<Failure, List<DisciplinaryComment>>> getCommentsForCase({
    required String caseId,
  }) async {
    try {
      final rows = await localDataSource.getCommentsForCase(caseId);
      return Right(rows.map((r) => r.toEntity()).toList(growable: false));
    } catch (_) {
      return const Left(StorageFailure('Local disciplinary read failed'));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> commentCounts({
    required List<String> caseIds,
  }) async {
    try {
      return Right(await localDataSource.commentCounts(caseIds));
    } catch (_) {
      return const Left(StorageFailure('Local disciplinary read failed'));
    }
  }
}
