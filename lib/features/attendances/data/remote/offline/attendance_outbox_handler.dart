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

/// Sonde « ces élèves ont-ils un transfert de classe pas encore synchronisé ? »
///
/// Rend le sous-ensemble de [studentIds] concerné, pour l'année donnée. Câblée
/// en DI sur `ClassroomLocalDataSource.studentsWithPendingTransfer` ; le
/// handler reste ainsi découplé du DAO Classe, comme
/// `OutboxDependencyGate` le fait pour l'arête inscription→discipline.
///
/// **Requise, jamais optionnelle.** Une garde à paramètre facultatif se câble
/// mal une fois et échoue ouverte pour toujours, sans qu'aucun test rougisse.
typedef ClassroomTransferGate =
    Future<Set<String>> Function(
      List<String> studentIds,
      String academicYearId,
    );

/// Pousse un agrégat d'appel `{session, absences[]}` (AF-2) vers
/// `POST /sync/attendance`. Idempotence serveur = **clé naturelle** + LWW.
///
/// **Garde de dépendance CLASSE → PRÉSENCE.** Le roster que lit l'appel est
/// composé (miroir ± transferts locaux en attente), celui que valide le serveur
/// ne l'est pas : l'absence d'un élève déplacé en local mais pas encore au
/// serveur fait rejeter l'agrégat ENTIER en 422, donc perd la journée complète
/// de la classe pour un seul élève. On attend (`blocked`) que le transfert soit
/// parti — attente propre, sans tentative consommée, auto-cicatrisante.
///
/// - succès → marque le jour SYNCED et rapatrie `serverUpdatedAt` +
///   `expectedCount` de la réponse (AG-3).
/// - `SUPERSEDED` → **adopte l'état canonique du gagnant** puis acquitte.
/// - rejet métier (validation / hors roster / date hors année) → failed, avec
///   la raison **du serveur** et non le libellé plat de l'intercepteur.
/// - réseau / 5xx / timeout → retry (backoff).
class AttendanceOutboxHandler implements OutboxSyncHandler {
  final AttendanceSyncApi syncApi;
  final AttendanceLocalDataSource localDataSource;
  final Map<String, dynamic> requiredAuth;
  final ClassroomTransferGate pendingTransfers;
  final CurrentUserContext? currentUser;
  final Clock now;

  const AttendanceOutboxHandler({
    required this.syncApi,
    required this.localDataSource,
    required this.requiredAuth,
    required this.pendingTransfers,
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

    // ── Attribution (ADR-010 D-05) ───────────────────────────────────────────
    // Sans auteur, le serveur ne peut rien répondre d'autre qu'un 400 :
    // `authorId` y est `@NotNull`, et la garde d'attribution ne s'exerce même
    // pas — le rejet vient de la validation du corps, en amont. Le pousser
    // brûle un aller-retour pour un refus certain, et l'issue était un `failed`
    // portant le libellé plat de l'intercepteur (« Invalid request data »), qui
    // ne disait ni la cause ni le geste.
    //
    // Le refus reste terminal — CETTE entrée-là ne passera jamais — mais il est
    // désormais réparable et le dit : réenregistrer l'appel une fois la session
    // rétablie réenfile le même jour (id d'outbox déterministe, `replace`) avec
    // un auteur, et la journée repart.
    if (aggregate.authorId == null) {
      return const OutboxDispatchResult.failed(
        'Appel enregistré sans auteur connu : le serveur le refusera toujours. '
        'Reconnectez-vous, puis réenregistrez cet appel.',
      );
    }

    // ── Dépendance CLASSE → PRÉSENCE ─────────────────────────────────────────
    // Le roster que lit l'appel est COMPOSÉ : un élève transféré en local mais
    // dont le transfert n'est pas encore parti figure déjà dans sa nouvelle
    // classe. Son absence part alors dans un agrégat que le serveur valide
    // contre SON roster (`requireAllInRoster`) et rejette ENTIER en 422 — un
    // 422 terminal, donc la journée complète de la classe perdue pour un seul
    // élève, sans qu'aucun geste depuis l'application puisse la rattraper.
    //
    // `blocked` plutôt que `retry` : attente propre (ni `attempts++`, ni
    // backoff, ni poison), qui se lève d'elle-même dès que le transfert ACKe —
    // le même traitement que l'arête inscription→discipline. L'ordre FIFO de la
    // file fait que le transfert, saisi avant, part d'ordinaire au même flush ;
    // cette garde ne mord que s'il a pris du retard ou échoué.
    if (aggregate.absences.isNotEmpty) {
      final blockedBy = await pendingTransfers(
        aggregate.absences.map((a) => a.studentId).toList(growable: false),
        aggregate.session.academicYearId,
      );
      if (blockedBy.isNotEmpty) {
        return OutboxDispatchResult.blocked(
          'Transfert de classe non synchronisé pour '
          '${blockedBy.length} élève(s) absent(s) — l\'appel repartira '
          'dès que le transfert sera passé.',
        );
      }
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
      // suivants (cf. [_adoptedLwwToken] : le contrat ne porte pas ce jeton,
      // on le reconstitue) — et on acquitte : l'entrée n'a plus rien à pousser,
      // et l'écran montre désormais la vérité du serveur au lieu d'une version
      // fantôme.
      if (response.isSuperseded) {
        await localDataSource.adoptCanonicalDay(
          classroomId: session.classroomId,
          dateStr: session.attendanceDate,
          academicYearId: session.academicYearId,
          canonicalAbsences: _canonicalAbsences(response),
          updatedAt: _adoptedLwwToken(response),
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
      // Le corps d'erreur porte la RAISON (`ApiErrorResponse.message`) :
      // « Student not in the active roster of this class: … », « Unknown or
      // empty classroom: … », « Attendance date … is outside academic year … ».
      // L'intercepteur, lui, aplatit TOUT 400/422 sur la constante « Invalid
      // request data » — c'est ce qui rendait ces refus illisibles dans la
      // feuille de reprise, où l'utilisateur n'avait plus qu'un rejet muet. On
      // ne s'en sert que sur les issues TERMINALES, les seules qu'il doive
      // lire ; un transitoire garde le message réseau, plus utile. Même lecture
      // que les handlers inscription et évaluation.
      final serverMessage = _serverMessage(e);
      if (failure is ValidationFailure || failure is NotFoundFailure) {
        return OutboxDispatchResult.failed(
          serverMessage ?? (failure is Failure ? failure.message : 'Rejected'),
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
          serverMessage ?? (failure is Failure ? failure.message : 'Forbidden'),
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

  /// La raison du refus telle que le SERVEUR l'a écrite
  /// (`ApiErrorResponse {timestamp, status, error, message, code}`), ou `null`
  /// si le corps n'en porte pas.
  String? _serverMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      final message = (data['message'] as String).trim();
      if (message.isNotEmpty) return message;
    }
    return null;
  }

  /// Le jeton LWW sur lequel se réancrer après avoir PERDU l'arbitrage.
  ///
  /// `response.updatedAt` est la bonne réponse et passe donc en premier : le
  /// serveur porte désormais le jeton de l'état retenu sur le fil
  /// (`AttendanceAggregateResponse.session.updatedAt`).
  ///
  /// ⚠️ **Le repli reste, et il n'est pas décoratif.** Ce champ n'a pas toujours
  /// existé : `SessionRef` n'exposait que `id`, `serverUpdatedAt` et
  /// `expectedCount`, et un serveur pas encore monté de version répond toujours
  /// sans. Le parc ne bascule pas d'un bloc, la tablette parle à celui qu'elle
  /// trouve.
  ///
  /// Le repli d'origine était `now()` — l'horloge de la tablette, précisément
  /// celle qui retarde quand un `SUPERSEDED` survient. On se réancrait sur un
  /// jeton encore perdant, la correction suivante reperdait, et la journée ne
  /// pouvait plus jamais atterrir : la boucle que ce chemin existe pour fermer.
  ///
  /// À défaut du bon jeton, on prend donc le plus tardif de ce que la réponse
  /// porte encore : le commit Postgres du gagnant (`serverUpdatedAt`) et les
  /// `updatedAt` de ses absences, qui sont, eux, de vrais jetons client. Ce
  /// n'est pas exact — un gagnant dont l'horloge avançait a pu poser un jeton
  /// jusqu'à `ClientClockGuard.DEFAULT_TOLERANCE` (5 min) au-dessus de son
  /// commit — mais l'écart résiduel devient BORNÉ par cette tolérance, au lieu
  /// d'être celui, non borné, d'une tablette qui retarde.
  int _adoptedLwwToken(AttendanceAggregateResponseModel response) {
    var latest = EpochIsoHelper.tryToEpochMs(response.updatedAt);

    void keepLater(String? iso) {
      final candidate = EpochIsoHelper.tryToEpochMs(iso);
      if (candidate != null && (latest == null || candidate > latest!)) {
        latest = candidate;
      }
    }

    keepLater(response.serverUpdatedAt);
    for (final ack in response.absences) {
      keepLater(ack.updatedAt);
    }

    return latest ?? now();
  }
}
