import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_notes_sync_api.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/notes_batch_push_models.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/notes_offline_repository_impl.dart'
    show kNotesBatchAggregateType;

/// Pousse un lot de notes (régime C) vers `POST /sync/academics/notes` et
/// **réconcilie ligne par ligne** l'outcome serveur.
///
/// **Garde de dépendance ÉVALUATION→NOTE** : une note ne peut exister serveur
/// que si son évaluation y existe. Si l'évaluation locale est encore
/// `PENDING_SYNC` (créée offline, pas encore poussée), on `blocked` (attente
/// propre, auto-cicatrisante dès que l'évaluation passe SYNCED — le FIFO de
/// l'outbox la pousse avant, l'évaluation ayant été créée avant). Si
/// l'évaluation est `SYNC_ERROR` (rejetée terminalement), on `failed` (les notes
/// ne pourront jamais s'y rattacher).
///
/// **Acceptation partielle** : le serveur renvoie toujours 200 + un outcome par
/// ligne. `APPLIED`/`SUPERSEDED` → note SYNCED ; `REJECTED` (période close /
/// invalide) → note SYNC_ERROR (surfacée à l'UI, **jamais perdue en silence**).
/// L'entrée n'est **acquittée que si TOUTES les notes poussées ont un outcome
/// terminal** : sinon `retry` (re-push idempotent — aucune note orpheline).
class NotesBatchOutboxHandler implements OutboxSyncHandler {
  final AcademicsNotesSyncApi syncApi;
  final AcademicsLocalDataSource localDataSource;
  final Map<String, dynamic> requiredAuth;
  final CurrentUserContext? currentUser;
  final Clock now;

  const NotesBatchOutboxHandler({
    required this.syncApi,
    required this.localDataSource,
    required this.requiredAuth,
    this.currentUser,
    this.now = systemClock,
  });

  @override
  String get aggregateType => kNotesBatchAggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    late final NotesBatchPushRequestModel request;
    try {
      request = NotesBatchPushRequestModel.fromJsonString(entry.payload);
    } catch (_) {
      return const OutboxDispatchResult.failed('Invalid notes payload');
    }

    // Garde d'ATTRIBUTION (tablette partagée) : une entrée saisie par un AUTRE
    // utilisateur (authorId ≠ uid courant) ne doit PAS partir sous ce JWT — le
    // serveur (SyncAttributionGuard) la rejetterait en 403 TERMINAL et la
    // saisie serait brûlée. `blocked` = attente propre, auto-cicatrisante à la
    // reconnexion de l'auteur.
    final uid = currentUser?.uid;
    if (request.authorId != null && request.authorId != uid) {
      return const OutboxDispatchResult.blocked(
        'Saisie d\'un autre utilisateur — repartira à sa reconnexion',
      );
    }

    // Toute erreur DB (gate, réconciliation) → retry : le contrat
    // `OutboxSyncHandler` interdit de lever ; le re-push est idempotent.
    try {
      // Garde de dépendance ÉVALUATION→NOTE (scopée à l'évaluation locale).
      final evaluation = await localDataSource.getEvaluation(
        request.evaluationId,
      );
      if (evaluation != null) {
        if (evaluation.syncState == SyncState.pendingSync) {
          return const OutboxDispatchResult.blocked(
            'Évaluation non synchronisée (dépendance) — les notes partiront '
            'après elle',
          );
        }
        if (evaluation.syncState == SyncState.syncError) {
          return const OutboxDispatchResult.failed(
            'Évaluation en échec de synchro — corrigez-la, les notes suivront',
          );
        }
      }

      final NotesBatchResponseModel response;
      try {
        response = await syncApi.submitNotes(requiredAuth, request);
      } on DioException catch (e) {
        final failure = e.error;
        // 403 (authorId ≠ JWT) / validation d'enveloppe → terminal ; 401/5xx/
        // réseau → transitoire.
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
      }

      // Réconciliation par ligne, résolue par la clé naturelle `(evaluationId,
      // studentId)`. On ne réconcilie QUE les studentIds effectivement poussés.
      final pushedUpdatedAt = <String, int>{
        for (final n in request.notes)
          if (n.updatedAtMs != null) n.studentId: n.updatedAtMs!,
      };
      final applied = <String, NoteSyncAck>{};
      final rejected = <String, int>{};
      final rejectedReasons = <String, String?>{};
      for (final o in response.outcomes) {
        final pushed = pushedUpdatedAt[o.studentId];
        if (pushed == null) continue; // outcome hors du lot poussé : ignoré.
        if (o.isApplied) {
          final canonicalNote = o.note;
          applied[o.studentId] = NoteSyncAck(
            pushedUpdatedAt: pushed,
            // Réaligne sur l'état SERVEUR (indispensable sur SUPERSEDED : le
            // push de ce client a perdu le LWW) ; `null` si l'outcome n'a pas
            // porté de `note` exploitable (parsing tolérant, DF-I) — le
            // datasource se contente alors de basculer sync_status.
            canonical: canonicalNote == null
                ? null
                : NoteCanonicalState(
                    pointsObtenus: canonicalNote.pointsObtenus,
                    statut: canonicalNote.statut,
                    updatedAt: EpochIsoHelper.tryToEpochMs(
                      canonicalNote.updatedAt,
                    ),
                    serverUpdatedAt: EpochIsoHelper.tryToEpochMs(
                      canonicalNote.serverUpdatedAt,
                    ),
                  ),
          );
        } else if (o.isRejected && !applied.containsKey(o.studentId)) {
          // Un studentId à la fois APPLIED et REJECTED (réponse serveur
          // contradictoire) : APPLIED gagne, on ne le compte pas deux fois.
          rejected[o.studentId] = pushed;
          rejectedReasons[o.studentId] = o.reason;
        }
      }
      // APPLIED gagne TOUJOURS, quel que soit l'ORDRE des outcomes dans la
      // réponse (le contrat ne le garantit pas) : un REJECTED vu avant
      // l'APPLIED du même studentId ne doit pas persister un rejet erroné.
      // Aujourd'hui `markNotesSynced` précède `markNotesSyncError` et la
      // garde SQL (`sync_status = PENDING_SYNC`) rend le second no-op une
      // fois le premier appliqué — mais c'est un effet de bord de l'ordre
      // des appels, pas une garantie explicite : on la rend order-independent
      // ici pour ne jamais en dépendre.
      rejected.removeWhere((id, _) => applied.containsKey(id));
      rejectedReasons.removeWhere((id, _) => applied.containsKey(id));

      final syncedAt = now();
      await localDataSource.markNotesSynced(
        evaluationId: request.evaluationId,
        studentIdToAck: applied,
        syncedAt: syncedAt,
      );
      await localDataSource.markNotesSyncError(
        evaluationId: request.evaluationId,
        studentIdToPushedUpdatedAt: rejected,
        studentIdToReason: rejectedReasons,
      );

      // Acquittement seulement si CHAQUE note poussée a un outcome terminal.
      // On compte les studentIds DISTINCTS résolus (un studentId renvoyé en
      // double par le serveur ne doit pas gonfler le compteur et masquer une
      // autre note sans outcome → sinon note orpheline). Sinon → retry (re-push
      // idempotent, aucune note laissée orpheline).
      final resolved = <String>{...applied.keys, ...rejected.keys}.length;
      if (resolved < pushedUpdatedAt.length) {
        return const OutboxDispatchResult.retry(
          'Réponse serveur incomplète (outcomes manquants) — re-push',
        );
      }
      return const OutboxDispatchResult.acked();
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }
}
