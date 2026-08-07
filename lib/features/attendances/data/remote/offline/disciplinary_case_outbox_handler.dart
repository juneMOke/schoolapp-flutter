import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/outbox_dependency_gate.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_case_aggregate_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/disciplinary_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/disciplinary_sync_api.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/disciplinary_case_offline_repository_impl.dart'
    show kDisciplinaryAggregateType;

/// Pousse l'agrégat disciplinaire `{case, comments[]}` (DF-2) vers
/// `POST /sync/disciplinary-cases`. **Chemin unique upsert** : le serveur pose le
/// FAIT (insert-only), garde le TRAITEMENT par LWW `clientUpdatedAt`, dédup les
/// commentaires par id.
///
/// **Garde de dépendance ENROLLMENT→DISCIPLINARY_CASE**, scopée à l'année du cas
/// (cf. [OutboxDependencyState]) : un cas ouvert sur un élève inscrit offline le
/// même jour attend l'ACK de l'inscription (`waiting`/`parentFailed` →
/// `blocked`) au lieu de partir prématurément et de récolter un faux
/// `SYNC_ERROR` « élève inconnu ». L'attente est auto-cicatrisante (repart dès
/// que l'inscription passe `SYNCED`).
///
/// - succès → marque l'agrégat SYNCED (cas + commentaires poussés) et rapatrie
///   `serverUpdatedAt`. `SUPERSEDED` est un **succès** (mono-préfet : le local est
///   déjà l'état gagnant ; filet du régime C).
/// - rejet métier 422 (élève inconnu, date hors année, enum/transition invalide)
///   → failed (terminal).
/// - réseau / 5xx / timeout → retry (backoff).
class DisciplinaryCaseOutboxHandler implements OutboxSyncHandler {
  final DisciplinarySyncApi syncApi;
  final DisciplinaryLocalDataSource localDataSource;
  final OutboxDependencyGate dependency;
  final Map<String, dynamic> requiredAuth;
  final Clock now;

  const DisciplinaryCaseOutboxHandler({
    required this.syncApi,
    required this.localDataSource,
    required this.dependency,
    required this.requiredAuth,
    this.now = systemClock,
  });

  @override
  String get aggregateType => kDisciplinaryAggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    late final DisciplinaryCaseAggregateRequestModel aggregate;
    try {
      aggregate = DisciplinaryCaseAggregateRequestModel.fromJsonString(
        entry.payload,
      );
    } catch (_) {
      // Payload corrompu / ancien format : rejet définitif (poison évité).
      return const OutboxDispatchResult.failed('Invalid disciplinary payload');
    }

    // Garde de dépendance, scopée à l'année du cas. `waiting` ET `parentFailed`
    // → `blocked` : attente PROPRE (ni attempts++ ni backoff), auto-cicatrisante
    // dès que l'inscription passe SYNCED. On NE bascule PAS en SYNC_ERROR sur
    // `parentFailed` (cul-de-sac : aucun re-push d'une entrée SYNC_ERROR) —
    // l'erreur d'inscription est déjà surfacée de son côté.
    switch (await dependency(
      aggregate.caseInput.studentId,
      aggregate.caseInput.academicYearId,
    )) {
      case OutboxDependencyState.waiting:
        return const OutboxDispatchResult.blocked(
          'Inscription de l\'élève non synchronisée (dépendance)',
        );
      case OutboxDependencyState.parentFailed:
        return const OutboxDispatchResult.blocked(
          'Inscription de l\'élève en échec de synchro — corrigez '
          'l\'inscription, le cas repartira ensuite',
        );
      case OutboxDependencyState.ready:
        break;
    }

    try {
      final response = await syncApi.submitDisciplinaryCase(
        requiredAuth,
        aggregate,
      );
      // SUPERSEDED : adopter le traitement gagnant renvoyé (mono-préfet : ne se
      // produit pas, mais le local ne doit pas rester sur l'état perdant).
      final superseded = response.isSuperseded && response.status != null;
      await localDataSource.markAggregateSynced(
        caseId: aggregate.caseInput.id,
        commentIds: aggregate.comments.map((c) => c.id).toList(growable: false),
        updatedAtGuard: aggregate.caseInput.clientUpdatedAtMs,
        serverUpdatedAt: EpochIsoHelper.tryToEpochMs(response.serverUpdatedAt),
        applyWinningTreatment: superseded,
        winningStatus: superseded ? response.status : null,
        winningSanction: superseded ? response.sanction : null,
        syncedAt: now(),
      );
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      final failure = e.error;
      // Rejets terminaux : validation (400/422), ressource absente (404),
      // accès interdit (403 → UnauthorizedFailure, permanent pour ce rôle/jeton).
      // 401 (InvalidCredentialsFailure) reste transitoire : réussira après
      // ré-auth. Ne pas gaspiller 50 tentatives sur un 403 permanent.
      if (failure is ValidationFailure ||
          failure is NotFoundFailure ||
          failure is UnauthorizedFailure) {
        return OutboxDispatchResult.failed(
          failure is Failure ? failure.message : 'Rejected',
        );
      }
      // Réseau / 5xx / timeout / 401 → transitoire.
      return OutboxDispatchResult.retry(
        failure is Failure ? failure.message : e.message,
      );
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }
}
