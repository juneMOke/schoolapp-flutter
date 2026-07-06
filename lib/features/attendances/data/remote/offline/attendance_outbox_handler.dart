import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/attendances/data/models/offline/offline_daily_attendance_command_model.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_sync_api.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_offline_repository_impl.dart'
    show kAttendanceAggregateType;

/// Pousse un appel (full-write) au serveur (AF-2). Clé d'idempotence =
/// `(classroom, date, année)` + upsert clé naturelle + LWW `updatedAt`.
///
/// - succès → marque le jour SYNCED (réconciliation minimale : le contrat back
///   ne renvoie pas encore les lignes enrichies — AG-3 différé).
/// - 409 (verrou périmé, improbable en LWW) / réseau / 5xx → retry (backoff).
/// - rejet métier (validation) → failed (à corriger côté présentation).
class AttendanceOutboxHandler implements OutboxSyncHandler {
  final AttendanceSyncApi syncApi;
  final AttendanceLocalDataSource localDataSource;
  final Map<String, dynamic> requiredAuth;
  final Clock now;

  const AttendanceOutboxHandler({
    required this.syncApi,
    required this.localDataSource,
    required this.requiredAuth,
    this.now = systemClock,
  });

  @override
  String get aggregateType => kAttendanceAggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    late final OfflineDailyAttendanceCommandModel command;
    try {
      command = OfflineDailyAttendanceCommandModel.fromJsonString(
        entry.payload,
      );
    } catch (_) {
      // Payload corrompu : rejet définitif (ne se rejouera jamais avec succès).
      return const OutboxDispatchResult.failed('Invalid attendance payload');
    }

    try {
      await syncApi.pushDailyAttendance(requiredAuth, command);
      await localDataSource.markDaySynced(
        classroomId: command.classroomId,
        dateStr: command.date,
        academicYearId: command.academicYearId,
        syncedAt: now(),
      );
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      final failure = e.error;
      if (failure is ValidationFailure || failure is NotFoundFailure) {
        return OutboxDispatchResult.failed(
          failure is Failure ? failure.message : 'Rejected',
        );
      }
      // Conflit (409) / réseau / 5xx / timeout → transitoire.
      return OutboxDispatchResult.retry(
        failure is Failure ? failure.message : e.message,
      );
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }
}
