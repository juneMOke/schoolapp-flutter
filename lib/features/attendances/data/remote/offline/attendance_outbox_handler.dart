import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_aggregate_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_aggregate_response_model.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_sync_api.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_offline_repository_impl.dart'
    show kAttendanceAggregateType;

/// Pousse un agrégat d'appel `{session, absences[]}` (AF-2) vers
/// `POST /sync/attendance`. Idempotence serveur = **clé naturelle** + LWW.
///
/// - succès → marque le jour SYNCED et rapatrie `serverUpdatedAt` +
///   `expectedCount` de la réponse (AG-3).
/// - `SUPERSEDED` → **adopte l'état canonique du gagnant** puis acquitte.
/// - rejet métier (validation / hors roster / date hors année) → failed.
/// - réseau / 5xx / timeout → retry (backoff).
class AttendanceOutboxHandler implements OutboxSyncHandler {
  final AttendanceSyncApi syncApi;
  final AttendanceLocalDataSource localDataSource;
  final Map<String, dynamic> requiredAuth;
  final CurrentUserContext? currentUser;
  final Clock now;

  const AttendanceOutboxHandler({
    required this.syncApi,
    required this.localDataSource,
    required this.requiredAuth,
    this.currentUser,
    this.now = systemClock,
  });

  /// Indexe l'état canonique du gagnant par élève. Sans identité : l'ACK ne
  /// transporte pas les libellés, et les fabriquer serait inventer de la donnée.
  Map<String, CanonicalAbsence> _canonicalAbsences(
    AttendanceAggregateResponseModel response,
  ) => {
    for (final ack in response.absences)
      ack.studentId: CanonicalAbsence(
        absenceReason: ack.absenceReason,
        absenceReasonNote: ack.absenceReasonNote,
        updatedAt: EpochIsoHelper.tryToEpochMs(ack.updatedAt) ?? now(),
      ),
  };

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

      // SUPERSEDED : le serveur est sorti AVANT toute écriture — notre version
      // a perdu l'arbitrage, rien de ce qu'on a envoyé n'a été retenu.
      //
      // Deux mauvaises réponses, écartées :
      //  - acquitter en marquant la journée SYNCED avec NOS valeurs affichait
      //    « succès » sur des données que le serveur n'a pas ; divergence muette ;
      //  - échouer en laissant la ligne `PENDING_SYNC` la rendait invisible au
      //    pull (`applyPulledSessions` saute le non-synchronisé) pendant que le
      //    curseur keyset dépasse le gagnant : journée gelée dans les deux sens.
      //
      // La bonne réponse est celle que le contrat prévoit : le serveur renvoie
      // l'état gagnant précisément pour qu'on s'y réaligne. On l'adopte — y
      // compris son jeton LWW, sans quoi on reperdrait tous les arbitrages
      // suivants — et on acquitte : l'entrée n'a plus rien à pousser, et l'écran
      // montre désormais la vérité du serveur au lieu d'une version fantôme.
      if (response.isSuperseded) {
        await localDataSource.adoptCanonicalDay(
          classroomId: session.classroomId,
          dateStr: session.attendanceDate,
          academicYearId: session.academicYearId,
          canonicalAbsences: _canonicalAbsences(response),
          updatedAt: EpochIsoHelper.tryToEpochMs(response.updatedAt) ?? now(),
          syncedAt: now(),
          serverUpdatedAt: response.serverUpdatedAt,
          expectedCount: response.expectedCount,
        );
        return const OutboxDispatchResult.acked();
      }

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
      // 403 = garde d'attribution serveur (`SyncAttributionGuard` : l'uid du
      // jeton diffère de l'`authorId` estampillé à la saisie). Le refus porte
      // sur le JETON PRÉSENTÉ, pas sur l'écriture : la même entrée passera
      // telle quelle dès que son auteur se reconnectera.
      //
      // D'où la distinction, et non un `failed` uniforme :
      //  - auteur ≠ utilisateur courant (tablette partagée, cas nominal) →
      //    `blocked` : attente PROPRE, sans consommer de tentative ni de poison,
      //    auto-cicatrisante à la reconnexion de l'auteur. Même traitement que
      //    les handlers notes et évaluation.
      //  - auteur == utilisateur courant → le refus ne vient pas de
      //    l'attribution (rôle, école) et ne se réparera pas tout seul :
      //    terminal, plutôt que 50 appels réseau pour le même refus.
      // NB : l'intercepteur mappe 401 ET 403 sur `UnauthorizedFailure`, on
      // discrimine donc sur le code HTTP.
      if (e.response?.statusCode == 403) {
        final uid = currentUser?.uid;
        final authorId = aggregate.authorId;
        if (authorId != null && uid != null && authorId != uid) {
          return const OutboxDispatchResult.blocked(
            'Saisie d\'un autre utilisateur — repartira à sa reconnexion',
          );
        }
        return OutboxDispatchResult.failed(
          failure is Failure ? failure.message : 'Forbidden',
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
