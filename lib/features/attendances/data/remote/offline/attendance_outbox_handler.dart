import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_aggregate_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_sync_api.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_offline_repository_impl.dart'
    show kAttendanceAggregateType;

/// Pousse un agrégat d'appel `{session, absences[]}` (AF-2) vers
/// `POST /sync/attendance`. Idempotence serveur = **clé naturelle** + LWW.
///
/// - succès → marque le jour SYNCED et rapatrie `serverUpdatedAt` +
///   `expectedCount` de la réponse (AG-3). `SUPERSEDED` est traité comme un
///   succès (mono-tablette : le local est déjà l'état gagnant ; filet du régime C).
/// - rejet métier (validation / hors roster / date hors année) → failed.
/// - réseau / 5xx / timeout → retry (backoff).
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
    late final AttendanceAggregateRequestModel aggregate;
    try {
      aggregate = AttendanceAggregateRequestModel.fromJsonString(entry.payload);
    } catch (_) {
      // Payload corrompu : rejet définitif (ne se rejouera jamais avec succès).
      return const OutboxDispatchResult.failed('Invalid attendance payload');
    }

    try {
      final response = await syncApi.submitAttendance(requiredAuth, aggregate);
      final session = aggregate.session;
      await localDataSource.markDaySynced(
        classroomId: session.classroomId,
        dateStr: session.attendanceDate,
        academicYearId: session.academicYearId,
        syncedAt: now(),
        serverUpdatedAt: response.serverUpdatedAt,
        expectedCount: response.expectedCount,
      );
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      final failure = e.error;
      if (failure is ValidationFailure || failure is NotFoundFailure) {
        return OutboxDispatchResult.failed(
          failure is Failure ? failure.message : 'Rejected',
        );
      }
      // Réseau / 5xx / timeout → transitoire.
      return OutboxDispatchResult.retry(
        failure is Failure ? failure.message : e.message,
      );
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }
}
