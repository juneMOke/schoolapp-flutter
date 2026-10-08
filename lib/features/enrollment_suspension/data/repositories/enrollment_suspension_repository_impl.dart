import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/enrollment_suspension_change_bus.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_read_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_write_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/suspension_gesture.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/student_suspension.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_reason.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_target.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/repositories/enrollment_suspension_repository.dart';

class EnrollmentSuspensionRepositoryImpl
    implements EnrollmentSuspensionRepository {
  final EnrollmentSuspensionReadDao _reader;
  final EnrollmentSuspensionWriteDao _writer;
  final EnrollmentSuspensionChangeBus _bus;
  final CurrentUserContext _currentUser;
  final IdGenerator _ids;
  final SyncEngine? _syncEngine;
  final Clock _now;

  const EnrollmentSuspensionRepositoryImpl({
    required EnrollmentSuspensionReadDao reader,
    required EnrollmentSuspensionWriteDao writer,
    required EnrollmentSuspensionChangeBus bus,
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
  Future<Either<Failure, int>> suspend(
    List<SuspensionTarget> targets, {
    SuspensionReason? reason,
    String? precision,
  }) => _record(
    targets,
    SuspensionGestureOp.suspend,
    reason: reason,
    precision: cleanPrecision(precision),
  );

  @override
  Future<Either<Failure, int>> reactivate(List<SuspensionTarget> targets) =>
      _record(targets, SuspensionGestureOp.reactivate);

  @override
  Future<Either<Failure, Map<String, StudentSuspension>>> openByEnrollment(
    String academicYearId,
  ) async {
    try {
      return Right(
        await _reader.openByEnrollment(
          schoolId: _currentUser.schoolId ?? '',
          academicYearId: academicYearId,
        ),
      );
    } catch (e) {
      return Left(StorageFailure('Lecture des désactivations : $e'));
    }
  }

  @override
  Future<Either<Failure, StudentSuspension?>> latestFor(
    String enrollmentId,
  ) async {
    try {
      return Right(await _reader.latestFor(enrollmentId));
    } catch (e) {
      return Left(StorageFailure('Lecture de la désactivation : $e'));
    }
  }

  Future<Either<Failure, int>> _record(
    List<SuspensionTarget> targets,
    SuspensionGestureOp op, {
    SuspensionReason? reason,
    String? precision,
  }) async {
    final schoolId = _currentUser.schoolId ?? '';
    final authorId = _currentUser.uid;
    if (schoolId.isEmpty || authorId == null) {
      return const Left(AuthFailure('Aucune session pour la désactivation'));
    }
    final nowMs = _now();
    final at = wireInstant(nowMs);
    final gestures = [
      for (final t in targets)
        SuspensionGesture(
          op: op,
          id: _ids.newId(),
          enrollmentId: t.enrollmentId,
          studentId: t.studentId,
          academicYearId: t.academicYearId,
          at: at,
          authorId: authorId,
          reason: reason,
          precision: precision,
        ),
    ];
    final Set<String> applied;
    try {
      applied = switch (op) {
        SuspensionGestureOp.suspend => await _writer.suspend(
          gestures,
          schoolId: schoolId,
          nowMs: nowMs,
        ),
        SuspensionGestureOp.reactivate => await _writer.reactivate(
          gestures,
          schoolId: schoolId,
          nowMs: nowMs,
        ),
      };
    } catch (e) {
      return Left(StorageFailure('Écriture de la désactivation : $e'));
    }
    if (applied.isNotEmpty) {
      _bus.emit(applied);
      final engine = _syncEngine;
      if (engine != null) unawaited(engine.flush());
    }
    return Right(applied.length);
  }

  /// La précision telle qu'elle part : rognée, bornée, `null` si vide.
  static String? cleanPrecision(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed.length > StudentSuspension.precisionMaxLength
        ? trimmed.substring(0, StudentSuspension.precisionMaxLength)
        : trimmed;
  }

  /// Un instant tel qu'il part sur le fil : UTC, à la milliseconde.
  static String wireInstant(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();
}
