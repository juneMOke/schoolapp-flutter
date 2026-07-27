import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, SyncEngine, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_transfer_row.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_pull_repository_impl.dart'
    show kClassroomsResource;
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_sync_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/record_classroom_transfer_draft.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_member_pull_repository.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_pull_repository.dart';

/// Type d'agrégat outbox du transfert d'élève (routage du handler de push).
const String kClassroomTransferAggregateType = 'CLASSROOM_TRANSFER';

/// Implémentation offline-first (CF2/CF3/CF4). `syncClassrooms` **orchestre**
/// deux repositories de pull keyset dédiés (`ClassroomPullRepository` +
/// `ClassroomMemberPullRepository`, chacun sur sa propre ressource/curseur —
/// aucune logique HTTP ici) ; lectures locales composées ; transfert =
/// événement local + outbox (flush opportuniste).
class ClassroomOfflineRepositoryImpl implements ClassroomOfflineRepository {
  final ClassroomPullRepository classroomPullRepository;
  final ClassroomMemberPullRepository classroomMemberPullRepository;
  final ClassroomLocalDataSource localDataSource;
  final SyncMetaDao syncMetaDao;
  final IdGenerator idGenerator;
  final SyncEngine syncEngine;
  final CurrentUserContext? _currentUser;
  final Clock now;

  /// Fraîcheur exposée par ce repository = celle du flux `classrooms` (les
  /// deux flux keyset partagent le même `now()` à chaque orchestration
  /// manuelle, cf. [syncClassrooms]).
  static const String syncResource = kClassroomsResource;

  const ClassroomOfflineRepositoryImpl({
    required this.classroomPullRepository,
    required this.classroomMemberPullRepository,
    required this.localDataSource,
    required this.syncMetaDao,
    required this.idGenerator,
    required this.syncEngine,
    CurrentUserContext? currentUser,
    this.now = systemClock,
  }) : _currentUser = currentUser;

  @override
  Future<Either<Failure, ClassroomSyncOutcome>> syncClassrooms({
    required String academicYearId,
  }) async {
    final syncedAt = now();
    // Chaque flux tourne indépendamment (pas de court-circuit) : un flux peut
    // avoir plusieurs pages pendant que l'autre est déjà à jour, et l'échec de
    // l'un ne doit pas empêcher l'autre de progresser.
    final classroomsResult = await classroomPullRepository.syncClassrooms(
      academicYearId: academicYearId,
    );
    final membersResult = await classroomMemberPullRepository.syncMembers(
      academicYearId: academicYearId,
    );
    return classroomsResult.fold(
      Left.new,
      (c) => membersResult.fold(
        Left.new,
        (m) => Right(
          ClassroomSyncOutcome(
            classroomsUpserted: c.upserted,
            membersUpserted: m.upserted,
            notModified: c.notModified && m.notModified,
            syncedAt: syncedAt,
          ),
        ),
      ),
    );
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
