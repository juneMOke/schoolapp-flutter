import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_evaluation_sync_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_push_models.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/evaluation_offline_repository_impl.dart'
    show kEvaluationAggregateType;

/// Pousse une évaluation (régime A) vers `POST /sync/academics/evaluations`.
/// Idempotent côté serveur (uuid client honoré) : 201 créée ≡ 200 rejeu, les
/// deux succès → l'évaluation passe SYNCED (+ `server_updated_at`). L'évaluation
/// est **immuable** après création : aucune garde LWW nécessaire, aucun gate de
/// dépendance (elle référence un `cours` serveur, jamais un agrégat créé offline).
///
/// - succès → SYNCED.
/// - rejet métier (400/422 validation, 404 introuvable, 403 interdit) → failed
///   (terminal). 401 reste transitoire (réussira après ré-auth).
/// - réseau / 5xx / timeout / 401 → retry (backoff).
class EvaluationOutboxHandler implements OutboxSyncHandler {
  final AcademicsEvaluationSyncApi syncApi;
  final AcademicsLocalDataSource localDataSource;
  final Map<String, dynamic> requiredAuth;
  final Clock now;

  const EvaluationOutboxHandler({
    required this.syncApi,
    required this.localDataSource,
    required this.requiredAuth,
    this.now = systemClock,
  });

  @override
  String get aggregateType => kEvaluationAggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    late final EvaluationPushRequestModel request;
    try {
      request = EvaluationPushRequestModel.fromJsonString(entry.payload);
    } catch (_) {
      return const OutboxDispatchResult.failed('Invalid evaluation payload');
    }

    try {
      final response = await syncApi.submitEvaluation(requiredAuth, request);
      await localDataSource.markEvaluationSynced(
        id: request.evaluation.id,
        serverUpdatedAt: EpochIsoHelper.tryToEpochMs(response.serverUpdatedAt),
        syncedAt: now(),
      );
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      final failure = e.error;
      if (failure is ValidationFailure ||
          failure is NotFoundFailure ||
          failure is UnauthorizedFailure) {
        return OutboxDispatchResult.failed(
          failure is Failure ? failure.message : 'Rejected',
        );
      }
      return OutboxDispatchResult.retry(
        failure is Failure ? failure.message : e.message,
      );
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }
}
