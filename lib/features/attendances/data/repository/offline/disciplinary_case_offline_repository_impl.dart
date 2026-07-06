import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/create_disciplinary_case_offline_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/offline_disciplinary_case_row.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/update_disciplinary_case_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/disciplinary_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/offline_disciplinary_case.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/disciplinary_case_offline_repository.dart';

/// Type d'agrégat d'outbox (routage vers [DisciplinaryCaseOutboxHandler]).
const String kDisciplinaryAggregateType = 'DISCIPLINARY_CASE';

/// Implémentation offline-first des cas disciplinaires (DF-1/2).
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

  static String createOutboxId(String caseId) =>
      '$kDisciplinaryAggregateType:CREATE:$caseId';

  static String updateOutboxId(String caseId) =>
      '$kDisciplinaryAggregateType:UPDATE:$caseId';

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

      final entry = OutboxEntry(
        id: createOutboxId(id),
        aggregateType: kDisciplinaryAggregateType,
        aggregateId: id,
        operation: OutboxOperation.create,
        payload: CreateDisciplinaryCaseOfflineRequestModel.fromRow(
          row,
        ).toJsonString(),
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
      final nowMs = now();
      final request = UpdateDisciplinaryCaseRequestModel.fromDomain(
        status: status,
        sanction: sanction,
        expectedVersion: expectedVersion,
      );
      final entry = OutboxEntry(
        id: updateOutboxId(caseId),
        aggregateType: kDisciplinaryAggregateType,
        aggregateId: caseId,
        operation: OutboxOperation.update,
        payload: request.toJsonString(),
        createdAt: nowMs,
      );

      await localDataSource.updateCaseWithOutbox(
        caseId: caseId,
        status: status.toApiValue(),
        sanction: sanction?.toApiValue(),
        updatedAt: nowMs,
        outboxEntry: entry,
      );
      return const Right(null);
    } catch (_) {
      return const Left(StorageFailure('Local disciplinary update failed'));
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
}
