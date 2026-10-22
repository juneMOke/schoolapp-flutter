import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/attachments/attachment_fetcher.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/justification/justification_decision_payload.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/justification/attendance_justification_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/attendance_justification.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/justification_enums.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/justification/attendance_justification_repository.dart';

/// Les justifications d'absence : lecture locale, décision par l'outbox, pièce
/// à la demande.
class AttendanceJustificationRepositoryImpl
    implements AttendanceJustificationRepository {
  final AttendanceJustificationLocalDataSource local;
  final AttachmentFetcher fetcher;
  final Map<String, dynamic> requiredAuth;
  final IdGenerator ids;
  final CurrentUserContext currentUser;
  final SyncEngine? syncEngine;
  final Clock now;

  const AttendanceJustificationRepositoryImpl({
    required this.local,
    required this.fetcher,
    required this.requiredAuth,
    required this.ids,
    required this.currentUser,
    this.syncEngine,
    this.now = systemClock,
  });

  @override
  Future<Either<Failure, List<AttendanceJustification>>> list(
    String academicYearId,
  ) => _guard(
    'Local justifications read failed',
    () => local.list(academicYearId),
  );

  @override
  Future<Either<Failure, Unit>> decide(
    AttendanceJustification justification,
    JustificationDecision decision, {
    String? note,
  }) async {
    final trimmed = note?.trim();
    final payload = JustificationDecisionPayload(
      gestureId: ids.newId(),
      justificationId: justification.id,
      decision: decision.apiValue,
      note: trimmed == null || trimmed.isEmpty ? null : trimmed,
      authorId: currentUser.uid,
    );
    final written = await _guard(
      'Local justification decision failed',
      () => local.recordDecision(
        payload: payload,
        schoolId: currentUser.schoolId,
        nowMs: now(),
      ),
    );
    return written.fold(Left.new, (recorded) {
      // Tranchée entre-temps (pull, autre geste) : la demande n'attend plus.
      if (!recorded) return const Left(ConflictFailure());
      final engine = syncEngine;
      if (engine != null) unawaited(engine.flush());
      return const Right(unit);
    });
  }

  @override
  Future<Either<Failure, Uint8List>> attachment(
    AttendanceJustification justification,
  ) async {
    final ref = justification.attachment;
    if (ref == null) return const Left(NotFoundFailure());
    final fetched = await fetcher.fetch(
      path: AppConstants.attendanceJustificationFileEndpoint.replaceFirst(
        '{id}',
        Uri.encodeComponent(justification.id),
      ),
      ref: ref,
      extras: requiredAuth,
    );
    return switch (fetched) {
      AttachmentFetched(:final bytes) => Right(bytes),
      AttachmentFetchFailed(error: AttachmentFetchError.offline) => const Left(
        NetworkFailure(),
      ),
      AttachmentFetchFailed() => const Left(NotFoundFailure()),
    };
  }

  @override
  Future<Either<Failure, Unit>> acknowledgeDecidedElsewhere(String id) =>
      _guard('Local justification notice failed', () async {
        await local.acknowledgeDecidedElsewhere(id);
        return unit;
      });

  static Future<Either<Failure, T>> _guard<T>(
    String message,
    Future<T> Function() body,
  ) async {
    try {
      return Right(await body());
    } catch (_) {
      return Left(StorageFailure(message));
    }
  }
}
