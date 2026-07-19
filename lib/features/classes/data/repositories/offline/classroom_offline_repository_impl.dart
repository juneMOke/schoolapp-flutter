import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, SyncEngine, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_sync_api.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_transfer_row.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_sync_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/record_classroom_transfer_draft.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';

/// Type d'agrégat outbox du transfert d'élève (routage du handler de push).
const String kClassroomTransferAggregateType = 'CLASSROOM_TRANSFER';

/// Implémentation offline-first (CF2/CF3/CF4). Pull delta → upsert local →
/// curseur ; lectures locales composées ; transfert = événement local + outbox
/// (flush opportuniste). 304 honoré.
class ClassroomOfflineRepositoryImpl implements ClassroomOfflineRepository {
  final ClassroomSyncApi syncApi;
  final ClassroomLocalDataSource localDataSource;
  final SyncMetaDao syncMetaDao;
  final IdGenerator idGenerator;
  final SyncEngine syncEngine;
  final Map<String, dynamic> requiredAuth;
  final CurrentUserContext? _currentUser;
  final Clock now;

  /// Clé de curseur/fraîcheur dans `sync_meta`.
  static const String syncResource = 'classrooms';

  const ClassroomOfflineRepositoryImpl({
    required this.syncApi,
    required this.localDataSource,
    required this.syncMetaDao,
    required this.idGenerator,
    required this.syncEngine,
    required this.requiredAuth,
    CurrentUserContext? currentUser,
    this.now = systemClock,
  }) : _currentUser = currentUser;

  @override
  Future<Either<Failure, ClassroomSyncOutcome>> syncClassrooms({
    required String academicYearId,
  }) async {
    final syncedAt = now();
    try {
      final cursor = await syncMetaDao.getCursor(syncResource);
      final delta = await syncApi.pullClassrooms(
        requiredAuth,
        academicYearId,
        cursor,
      );

      // 304 « logique » : delta vide → aucune écriture, curseur conservé.
      if (delta.isEmpty) {
        await syncMetaDao.setCursor(
          syncResource,
          cursor: cursor,
          syncedAt: syncedAt,
        );
        return Right(ClassroomSyncOutcome.notModifiedAt(syncedAt, cursor));
      }

      await localDataSource.upsertDelta(
        classrooms: delta.classrooms,
        members: delta.members,
        syncedAt: syncedAt,
      );
      final nextCursor = delta.serverCursor ?? cursor;
      await syncMetaDao.setCursor(
        syncResource,
        cursor: nextCursor,
        syncedAt: syncedAt,
      );
      return Right(
        ClassroomSyncOutcome(
          classroomsUpserted: delta.classrooms.length,
          membersUpserted: delta.members.length,
          notModified: false,
          syncedAt: syncedAt,
          cursor: nextCursor,
        ),
      );
    } on DioException catch (e) {
      // 304 Not Modified transporté en exception (corps vide non parsable).
      if (e.response?.statusCode == 304) {
        final cursor = await syncMetaDao.getCursor(syncResource);
        await syncMetaDao.setCursor(
          syncResource,
          cursor: cursor,
          syncedAt: syncedAt,
        );
        return Right(ClassroomSyncOutcome.notModifiedAt(syncedAt, cursor));
      }
      if (e.error is Failure) return Left(e.error as Failure);
      return const Left(NetworkFailure('Network error occurred'));
    } on FormatException catch (_) {
      return const Left(ServerFailure('Invalid classroom sync payload'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<OfflineClassroom>>> getClassrooms({
    required String academicYearId,
    String? schoolLevelId,
  }) async {
    try {
      final syncedAt = await syncMetaDao.getSyncedAt(syncResource);
      final rows = await localDataSource.getClassrooms(
        academicYearId: academicYearId,
        schoolLevelId: schoolLevelId,
      );
      return Right(
        rows.map((r) => r.toEntity(syncedAt: syncedAt)).toList(growable: false),
      );
    } catch (_) {
      return const Left(StorageFailure('Local classroom read failed'));
    }
  }

  @override
  Future<Either<Failure, OfflineClassroom>> getClassroom({
    required String classroomId,
  }) async {
    try {
      final row = await localDataSource.getClassroomById(classroomId);
      if (row == null) {
        return const Left(NotFoundFailure('Classroom not found locally'));
      }
      final syncedAt = await syncMetaDao.getSyncedAt(syncResource);
      return Right(row.toEntity(syncedAt: syncedAt));
    } catch (_) {
      return const Left(StorageFailure('Local classroom read failed'));
    }
  }

  @override
  Future<Either<Failure, List<ClassroomMember>>> getRoster({
    required String classroomId,
  }) async {
    try {
      final rows = await localDataSource.getRoster(classroomId);
      return Right(rows.map((r) => r.toEntity()).toList(growable: false));
    } catch (_) {
      return const Left(StorageFailure('Local roster read failed'));
    }
  }

  @override
  Future<Either<Failure, List<ClassroomMember>>> searchRoster({
    required String classroomId,
    required String query,
  }) async {
    try {
      final rows = await localDataSource.searchRoster(
        classroomId: classroomId,
        query: query,
      );
      return Right(rows.map((r) => r.toEntity()).toList(growable: false));
    } catch (_) {
      return const Left(StorageFailure('Local roster search failed'));
    }
  }

  @override
  Future<Either<Failure, Map<String, List<ClassroomMember>>>>
  getComposedRosters({
    required String academicYearId,
    required String schoolLevelId,
  }) async {
    try {
      final classes = await localDataSource.getClassrooms(
        academicYearId: academicYearId,
        schoolLevelId: schoolLevelId,
      );
      final rosters = <String, List<ClassroomMember>>{};
      for (final c in classes) {
        final rows = await localDataSource.getRoster(c.id);
        rosters[c.id] = rows.map((r) => r.toEntity()).toList(growable: false);
      }
      return Right(rosters);
    } catch (_) {
      return const Left(StorageFailure('Local rosters read failed'));
    }
  }

  @override
  Future<Either<Failure, String>> recordTransfer(
    RecordClassroomTransferDraft draft,
  ) async {
    try {
      final nowMs = now();
      final transferId = idGenerator.newId();
      final row = ClassroomTransferRow(
        id: transferId,
        studentId: draft.studentId,
        fromClassroomId: draft.fromClassroomId,
        toClassroomId: draft.toClassroomId,
        schoolLevelId: draft.schoolLevelId,
        academicYearId: draft.academicYearId,
        transferredAt: nowMs,
        transferredBy: draft.transferredBy,
        reason: draft.reason,
        syncStatus: SyncState.pendingSync.dbValue,
      );
      final entry = OutboxEntry(
        id: idGenerator.newId(),
        aggregateType: kClassroomTransferAggregateType,
        aggregateId: transferId,
        operation: OutboxOperation.create,
        payload: jsonEncode(row.toRequestJson(authorId: _currentUser?.uid)),
        createdAt: nowMs,
      );
      await localDataSource.recordTransferWithOutbox(
        row: row,
        outboxEntry: entry,
      );
      // Flush opportuniste : si connecté, le transfert part tout de suite ;
      // sinon l'outbox le rejouera au retour online.
      unawaited(syncEngine.flush());
      return Right(transferId);
    } catch (_) {
      return const Left(StorageFailure('Local transfer write failed'));
    }
  }

  @override
  Future<int?> getFreshness() => syncMetaDao.getSyncedAt(syncResource);
}
