import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
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
/// - **`422` backstop (DF-N)** : `PERIOD_CLOSED`/`EXAM_NOT_ALLOWED`/`MAX_REACHED`,
///   code porté en tête de `ApiErrorResponse.message` → échec **terminal**,
///   évaluation `SYNC_ERROR` + code persisté (`rejection_code`, surfacé à
///   l'UI), **jamais de re-push** (à la création seulement, un rejeu idempotent
///   ressort en 200).
/// - rejet métier (400 validation, 404 introuvable, 403 interdit) → failed
///   (terminal). 401 reste transitoire (réussira après ré-auth).
/// - réseau / 5xx / timeout / 401 → retry (backoff).
class EvaluationOutboxHandler implements OutboxSyncHandler {
  /// Codes applicatifs des backstops `422` (préfixe du message, DF-N).
  static const List<String> backstopCodes = [
    'PERIOD_CLOSED',
    'EXAM_NOT_ALLOWED',
    'MAX_REACHED',
  ];
  final AcademicsEvaluationSyncApi syncApi;
  final AcademicsLocalDataSource localDataSource;
  final Map<String, dynamic> requiredAuth;
  final CurrentUserContext? currentUser;
  final Clock now;

  const EvaluationOutboxHandler({
    required this.syncApi,
    required this.localDataSource,
    required this.requiredAuth,
    this.currentUser,
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

    // Garde d'ATTRIBUTION (tablette partagée) : une évaluation créée par un
    // AUTRE utilisateur ne part pas sous ce JWT (403 terminal sinon) —
    // `blocked`, repartira à la reconnexion de l'auteur.
    if (request.authorId != null && request.authorId != currentUser?.uid) {
      return const OutboxDispatchResult.blocked(
        'Saisie d\'un autre utilisateur — repartira à sa reconnexion',
      );
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
      if (e.response?.statusCode == 422) {
        final code = _backstopCode(e) ?? 'REJECTED';
        try {
          await localDataSource.markEvaluationSyncError(
            id: request.evaluation.id,
            rejectionCode: code,
          );
        } catch (_) {
          // Le rejet serveur est TERMINAL même si l'écriture locale échoue
          // (DB busy, disque…) : un throw ici ne doit JAMAIS s'échapper vers
          // le catch générique ci-dessous — sinon un 422 déterministe (le
          // serveur ne changera pas d'avis) serait reclassé `retry` et
          // repoussé indéfiniment. Le bookkeeping local pourra rester
          // incomplet, mais l'outbox, lui, ne boucle jamais sur un rejet
          // qu'on sait définitif.
        }
        return OutboxDispatchResult.failed(code);
      }
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

  /// Extrait le code applicatif en tête de `ApiErrorResponse.message` (le
  /// projet ne porte pas de champ `code` dédié) — `null` si le message ne
  /// commence par aucun des 3 codes connus (défensif, contrat inattendu).
  String? _backstopCode(DioException e) {
    final data = e.response?.data;
    final message = (data is Map && data['message'] is String)
        ? data['message'] as String
        : null;
    if (message == null) return null;
    for (final code in backstopCodes) {
      if (message.startsWith(code)) return code;
    }
    return null;
  }
}
