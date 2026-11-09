import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/level_correction_change_bus.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_read_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_write_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/sync/level_correction_gesture.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_refusal.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_refused_locally.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_request.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/repositories/level_correction_repository.dart';

class LevelCorrectionRepositoryImpl implements LevelCorrectionRepository {
  final LevelCorrectionReadDao _reader;
  final LevelCorrectionWriteDao _writer;
  final LevelCorrectionChangeBus _bus;
  final CurrentUserContext _currentUser;
  final IdGenerator _ids;
  final SyncEngine? _syncEngine;
  final Clock _now;

  const LevelCorrectionRepositoryImpl({
    required LevelCorrectionReadDao reader,
    required LevelCorrectionWriteDao writer,
    required LevelCorrectionChangeBus bus,
    required CurrentUserContext currentUser,
    required IdGenerator ids,
    SyncEngine? syncEngine,
    Clock now = systemClock,
  }) : _reader = reader,
       _writer = writer,
       _bus = bus,
       _currentUser = currentUser,
       _ids = ids,
       _syncEngine = syncEngine,
       _now = now;

  @override
  Stream<Set<String>> get changes => _bus.stream;

  @override
  Future<Either<Failure, bool>> correct(LevelCorrectionRequest request) async {
    final schoolId = _currentUser.schoolId ?? '';
    final authorId = _currentUser.uid;
    if (schoolId.isEmpty || authorId == null) {
      return const Left(AuthFailure('Aucune session pour la correction'));
    }
    final reason = request.reason.trim();
    if (reason.isEmpty) {
      return const Left(ValidationFailure('Motif de correction manquant'));
    }
    if (request.toSchoolLevelId == request.fromSchoolLevelId) {
      return const Left(ValidationFailure('Niveau cible identique'));
    }
    final nowMs = _now();
    final gesture = LevelCorrectionGesture(
      id: _ids.newId(),
      enrollmentId: request.enrollmentId,
      studentId: request.studentId,
      academicYearId: request.academicYearId,
      fromSchoolLevelId: request.fromSchoolLevelId,
      toSchoolLevelId: request.toSchoolLevelId,
      toSchoolLevelGroupId: request.toSchoolLevelGroupId,
      toClassroomId: request.toClassroomId,
      reason: reason,
      correctedAt: wireInstant(nowMs),
      authorId: authorId,
    );
    final LevelCorrectionRecordOutcome outcome;
    try {
      outcome = await _writer.record(gesture, schoolId: schoolId, nowMs: nowMs);
    } catch (e) {
      return Left(StorageFailure('Écriture de la correction : $e'));
    }
    switch (outcome) {
      case LevelCorrectionRecordOutcome.alreadyPending:
        return const Right(false);
      case LevelCorrectionRecordOutcome.hasPayments:
        return const Left(
          LevelCorrectionRefusedLocally(LevelCorrectionRefusal.hasPayments),
        );
      case LevelCorrectionRecordOutcome.recorded:
        _bus.emit({request.enrollmentId});
        final engine = _syncEngine;
        if (engine != null) unawaited(engine.flush());
        return const Right(true);
    }
  }

  @override
  Future<Either<Failure, LevelCorrection?>> latestFor(
    String enrollmentId,
  ) async {
    try {
      return Right(await _reader.latestFor(enrollmentId));
    } catch (e) {
      return Left(StorageFailure('Lecture de la correction : $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> holdsCollection({
    required String studentId,
    required String academicYearId,
  }) async {
    try {
      return Right(
        await _reader.holdsCollection(
          studentId: studentId,
          academicYearId: academicYearId,
        ),
      );
    } catch (e) {
      return Left(StorageFailure('Lecture de la correction : $e'));
    }
  }

  /// Un instant tel qu'il part sur le fil : UTC, à la milliseconde.
  static String wireInstant(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();
}
