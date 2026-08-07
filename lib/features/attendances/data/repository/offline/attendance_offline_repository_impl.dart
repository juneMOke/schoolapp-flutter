import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, SyncEngine, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_absence_input_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_aggregate_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_record_row.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_session_input_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_session_row.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_update.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_pull_repository_impl.dart'
    show kAttendanceBootstrapResource, kAttendanceResource;
import 'package:school_app_flutter/features/attendances/domain/entities/offline/daily_attendance.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/local_attendance_rate.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/student_attendance_stats.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_absence_entry.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/attendance_offline_repository.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_transfer_row.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_member_pull_repository_impl.dart'
    show kClassroomMembersResource;
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_transfer_pull_repository_impl.dart'
    show kClassroomTransfersBootstrapResource;

/// Type d'agrégat d'outbox de l'appel (routage vers [AttendanceOutboxHandler]).
const String kAttendanceAggregateType = 'ATTENDANCE';

/// Implémentation offline-first de l'appel (AF-1/2/3). Roster lu depuis
/// `ref_classroom_members` (module Classe), écriture locale par exception +
/// outbox full-write, taux dérivé en SQL.
class AttendanceOfflineRepositoryImpl implements AttendanceOfflineRepository {
  final AttendanceLocalDataSource localDataSource;
  final ClassroomLocalDataSource rosterDataSource;
  final SyncMetaDao syncMetaDao;
  final IdGenerator idGenerator;
  final CurrentUserContext? _currentUser;
  final SyncEngine? _syncEngine;
  final Clock now;

  const AttendanceOfflineRepositoryImpl({
    required this.localDataSource,
    required this.rosterDataSource,
    required this.syncMetaDao,
    required this.idGenerator,
    CurrentUserContext? currentUser,
    SyncEngine? syncEngine,
    this.now = systemClock,
  }) : _currentUser = currentUser,
       _syncEngine = syncEngine;

  /// Clé d'idempotence / id déterministe d'outbox pour un appel.
  static String outboxKey(
    String classroomId,
    String dateStr,
    String academicYearId,
  ) => '$classroomId|$dateStr|$academicYearId';

  /// Horloge **monotone** par session : `clientUpdatedAt` doit toujours être
  /// strictement supérieur à l'`updated_at` déjà en base.
  ///
  /// Le serveur arbitre le régime C en STRICT (`isNewer` est faux à égalité
  /// comme en retard) et il n'écrit RIEN quand il perd. Or l'`updated_at` local
  /// vient souvent d'un pull au **temps serveur**, structurellement en avance
  /// sur l'horloge d'une tablette qui retarde : sans cette garde, la correction
  /// est sautée en local ET refusée au serveur, avec un « succès » à l'écran.
  /// Même garde et même raison que la discipline (`_monotonic`).
  int _monotonic(int nowMs, int localUpdatedAt) =>
      nowMs > localUpdatedAt ? nowMs : localUpdatedAt + 1;

  @override
  Future<Either<Failure, DailyAttendance>> loadDailyAttendance({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
  }) async {
    try {
      final dateStr = DateOnlyJsonHelper.toJson(date);
      final session = await localDataSource.getSession(
        classroomId: classroomId,
        dateStr: dateStr,
        academicYearId: academicYearId,
      );
      final roster = await rosterDataSource.getRoster(classroomId);
      final dayRows = await localDataSource.getDayRecords(
        classroomId: classroomId,
        dateStr: dateStr,
        academicYearId: academicYearId,
      );
      final byStudent = {for (final r in dayRows) r.studentId: r};

      final records = roster
          .map((m) {
            final row = byStudent[m.studentId];
            if (row != null) return row.toEntity();
            // Aucune ligne locale → présent par défaut (stockage par exception).
            return AttendanceRecord(
              studentId: m.studentId,
              studentFirstName: m.studentFirstName,
              studentLastName: m.studentLastName,
              studentMiddleName: m.studentMiddleName,
              studentGender: StudentGenderX.fromApiValue(m.studentGender),
              classroomId: classroomId,
              academicYearId: academicYearId,
              attendanceDate: date,
              present: true,
            );
          })
          .toList(growable: false);

      // `taken` = existence de la session (invariant #1) : pas de session ⇒
      // appel non fait, jamais « tous présents ».
      return Right(
        DailyAttendance(
          taken: session != null,
          records: records,
          takenAt: session?.takenAt == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(session!.takenAt!),
          takenBy: session?.takenBy,
        ),
      );
    } catch (_) {
      return const Left(StorageFailure('Local attendance read failed'));
    }
  }

  @override
  Future<Either<Failure, void>> recordDailyAttendance({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
    required List<AttendanceUpdate> updates,
  }) async {
    try {
      final dateStr = DateOnlyJsonHelper.toJson(date);

      // Id de session STABLE (id = transport, clé naturelle = vérité) : on
      // réutilise l'id local existant s'il y en a un, sinon on en forge un.
      final existingSession = await localDataSource.getSession(
        classroomId: classroomId,
        dateStr: dateStr,
        academicYearId: academicYearId,
      );
      final sessionId = existingSession?.id ?? idGenerator.newId();

      final nowMs = _monotonic(now(), existingSession?.updatedAt ?? 0);
      final nowIso = DateTime.fromMillisecondsSinceEpoch(
        nowMs,
        isUtc: true,
      ).toIso8601String();

      // `taken_at` = heure du PREMIER appel, pas de la dernière correction. Le
      // serveur l'écrase inconditionnellement avec ce que porte le payload : y
      // remettre `now` faisait glisser l'heure d'origine de l'appel à chaque
      // correction, en local comme au serveur.
      final takenAtMs = existingSession?.takenAt ?? nowMs;

      // Racine d'agrégat : la session porte l'`updated_at` arbitre, rebumpé à
      // chaque confirmation (invariant #4).
      final session = AttendanceSessionRow(
        id: sessionId,
        classroomId: classroomId,
        attendanceDate: dateStr,
        academicYearId: academicYearId,
        takenAt: takenAtMs,
        // `taken_by` : on repousse la valeur déjà connue. Le serveur écrase ce
        // champ sans condition — envoyer null l'effaçait à chaque push.
        takenBy: existingSession?.takenBy,
        updatedAt: nowMs,
        syncStatus: SyncState.pendingSync.dbValue,
      );

      // ── Exhaustivité du payload (contrat régime C) ───────────────────────
      // Le serveur réconcilie PAR DIFFÉRENCE : toute absence en base et absente
      // du payload est SUPPRIMÉE. Or `updates` est une projection de ce que
      // l'UI avait sous les yeux, qui peut être un SOUS-ENSEMBLE du roster
      // (filtre, pagination). Une absence dont l'élève n'a jamais été affiché
      // serait alors détruite côté serveur sans que personne ne l'ait voulu.
      //
      // On réinjecte donc les lignes d'absence locales du jour que `updates`
      // ne couvre pas — mais UNIQUEMENT pour les élèves encore membres ACTIFS
      // de la classe.
      //
      // Cette restriction est essentielle et n'est pas une précaution de
      // confort : le serveur valide `requireAllInRoster` contre son roster
      // ACTIF courant AVANT tout arbitrage, et rejette l'agrégat ENTIER en 422.
      // Réinjecter l'absence d'un élève sorti de la classe depuis (transfert,
      // passage INACTIVE) condamnerait donc la journée à un 422 déterministe et
      // AUTO-REPRODUCTIBLE — la ligne fautive étant conservée localement, chaque
      // revalidation recomposerait le même payload rejeté, et la session restant
      // `PENDING_SYNC` serait de surcroît sautée par le pull : divergence
      // scellée dans les deux sens, sans aucune sortie depuis l'application.
      //
      // Reste donc non couvert le cas « élève sorti de la classe depuis le jour
      // de l'appel » : son absence historique est bien supprimée au serveur par
      // réconciliation. C'est un défaut PRÉEXISTANT dont le correctif propre est
      // serveur (valider le roster à la DATE de l'appel, ce que le back sait
      // déjà faire pour ses stats par intervalles d'appartenance).
      final knownStudentIds = updates.map((u) => u.studentId).toSet();
      final activeMemberIds = {
        for (final m in await rosterDataSource.getRoster(classroomId))
          m.studentId,
      };
      final localDayRecords = await localDataSource.getDayRecords(
        classroomId: classroomId,
        dateStr: dateStr,
        academicYearId: academicYearId,
      );
      final preservedRows = localDayRecords
          .where(
            (r) =>
                !r.present &&
                !knownStudentIds.contains(r.studentId) &&
                activeMemberIds.contains(r.studentId),
          )
          .toList(growable: false);

      // Écriture par exception : SEULS les absents portent une ligne. Les
      // présents redeviennent une non-ligne via la réconciliation par différence.
      final editedRows = updates
          .where((u) => !u.present)
          .map(
            (u) => AttendanceRecordRow(
              id: idGenerator.newId(),
              sessionId: sessionId,
              studentId: u.studentId,
              studentFirstName: u.studentFirstName,
              studentLastName: u.studentLastName,
              studentMiddleName: u.studentMiddleName,
              studentGender: u.studentGender.toApiValue(),
              classroomId: classroomId,
              attendanceDate: dateStr,
              academicYearId: academicYearId,
              present: false,
              absenceReason: u.absenceReason?.toApiValue(),
              absenceReasonNote: u.absenceReasonNote,
              updatedAt: nowMs,
              syncStatus: SyncState.pendingSync.dbValue,
            ),
          )
          .toList(growable: false);

      // Les lignes préservées gardent leur `updated_at` d'origine : elles ne
      // sont pas rééditées, seulement re-transmises pour ne pas être détruites.
      final absentRows = [...editedRows, ...preservedRows];

      // Payload d'outbox = agrégat exhaustif `{session, absences[]}` (contrat 1.2.0).
      final aggregate = AttendanceAggregateRequestModel(
        authorId: _currentUser?.uid, // estampillage authorId (ADR-010 D-05)
        session: AttendanceSessionInputModel(
          id: sessionId,
          classroomId: classroomId,
          attendanceDate: dateStr,
          academicYearId: academicYearId,
          takenAt: DateTime.fromMillisecondsSinceEpoch(
            takenAtMs,
            isUtc: true,
          ).toIso8601String(),
          takenBy: existingSession?.takenBy,
          updatedAt: nowIso,
        ),
        absences: absentRows
            .map(
              (r) => AttendanceAbsenceInputModel(
                id: r.id,
                studentId: r.studentId,
                absenceReason: r.absenceReason,
                absenceReasonNote: r.absenceReasonNote,
                // Horodatage PAR LIGNE : les lignes rééditées portent `nowMs`,
                // les lignes seulement préservées gardent le leur. Estamper
                // tout le lot à `now` ferait gagner à des lignes non touchées
                // un arbitrage LWW qu'elles ne doivent pas gagner.
                updatedAt: DateTime.fromMillisecondsSinceEpoch(
                  r.updatedAt,
                  isUtc: true,
                ).toIso8601String(),
              ),
            )
            .toList(growable: false),
      );

      final key = outboxKey(classroomId, dateStr, academicYearId);
      final entry = OutboxEntry(
        // Id déterministe → coalescing d'un ré-appel du même jour (replace).
        id: '$kAttendanceAggregateType:$key',
        aggregateType: kAttendanceAggregateType,
        aggregateId: key,
        operation: OutboxOperation.upsert,
        payload: aggregate.toJsonString(),
        createdAt: nowMs,
      );

      final persisted = await localDataSource.confirmDailyAttendance(
        session: session,
        absentRows: absentRows,
        outboxEntry: entry,
      );
      if (!persisted) {
        // Course réelle : une écriture concurrente a pris la main entre la
        // lecture de `existingSession` et la transaction. Rien n'a été écrit ni
        // enfilé — surtout ne pas annoncer un succès.
        return const Left(
          StorageFailure(
            'Cet appel vient d\'être modifié ailleurs — rouvrez la journée '
            'pour repartir de l\'état à jour.',
          ),
        );
      }
      // Flush opportuniste au niveau repository : l'`AttendanceSaveOverlay`
      // déclenche déjà `notifyLocalWrite()`, mais ce filet rend le push
      // indépendant du widget appelant (même idiome qu'academics/classes).
      // Un flush déjà en vol rend `skipped` — le verrou `_flushing` l'absorbe.
      final engine = _syncEngine;
      if (engine != null) unawaited(engine.flush());
      return const Right(null);
    } catch (_) {
      return const Left(StorageFailure('Local attendance write failed'));
    }
  }

  @override
  Future<Either<Failure, LocalAttendanceRate>> getAttendanceRate({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
  }) async {
    try {
      final dateStr = DateOnlyJsonHelper.toJson(date);
      final effectif = await rosterDataSource.countActiveRoster(classroomId);
      final absences = await localDataSource.countAbsences(
        classroomId: classroomId,
        dateStr: dateStr,
        academicYearId: academicYearId,
      );
      // Fraîcheur du roster sous-jacent (curseur du flux membres, cf. Classe CF2
      // — indépendant du flux classes depuis le passage keyset double-flux).
      final syncedAt = await syncMetaDao.getSyncedAt(kClassroomMembersResource);
      return Right(
        LocalAttendanceRate(
          effectif: effectif,
          absences: absences,
          syncedAt: syncedAt,
        ),
      );
    } catch (_) {
      return const Left(StorageFailure('Local attendance rate failed'));
    }
  }

  @override
  Future<Either<Failure, StudentAttendanceStats>> getStudentAttendanceStats({
    required String studentId,
    required String academicYearId,
    required StatsPeriod period,
    required DateTime reference,
  }) async {
    try {
      final (from, to) = _periodBounds(period, reference);
      final fromStr = from == null ? null : DateOnlyJsonHelper.toJson(from);
      final toStr = to == null ? null : DateOnlyJsonHelper.toJson(to);

      // Dénominateur : jours appelés. Un élève transféré n'a PAS été appelé dans
      // sa classe courante depuis la rentrée → on somme sur ses intervalles
      // d'appartenance bornés par `transferred_at` (F6, ADR-004). Chemin rapide :
      // aucun transfert (quasi-totalité) → sa classe courante composée
      // (`ref_classroom_members`, CF3/CF4) = comportement d'avant.
      final transfers = await rosterDataSource.getStudentSyncedTransfers(
        studentId: studentId,
        academicYearId: academicYearId,
      );
      int daysCalled;
      // Le chemin rapide (pas de transfert synchronisé) est le SEUL à dépendre
      // de `ref_classroom_members` (résolution de la classe courante) : le
      // chemin intervalles (F6) ne lit que `classroom_transfers` +
      // `attendance_sessions`. Sert à ne gater le bootstrap roster ci-dessous
      // que quand il est réellement dans la chaîne de calcul.
      final requiresClassroomMembers = transfers.isEmpty;
      if (requiresClassroomMembers) {
        final classroomId = await rosterDataSource.getCurrentClassroomId(
          studentId: studentId,
          academicYearId: academicYearId,
        );
        // Pas (encore) de ligne membre locale pour cet élève cette année
        // (roster pas encore pullé) : dénominateur inconnu, pas d'appel classe.
        daysCalled = classroomId == null
            ? 0
            : await localDataSource.countSessions(
                classroomId: classroomId,
                academicYearId: academicYearId,
                fromStr: fromStr,
                toStr: toStr,
              );
      } else {
        daysCalled = await _daysCalledByIntervals(
          transfers: transfers,
          academicYearId: academicYearId,
          periodFrom: from,
          periodTo: to,
        );
      }
      final absenceRows = await localDataSource.getStudentAbsenceRecords(
        studentId: studentId,
        academicYearId: academicYearId,
        fromStr: fromStr,
        toStr: toStr,
      );
      // Invariant #7 : un chiffre n'est fiable qu'une fois l'année entière tirée
      // — côté appels ET côté transferts (un historique de transfert partiel
      // donnerait un dénominateur faux mais plausible, donc indétectable).
      // Depuis la résolution interne de la classe courante (chemin rapide),
      // `ref_classroom_members` entre aussi dans la chaîne : sans lui, un demi
      // roster donnerait `classroomId == null` ⇒ daysCalled=0 alors que des
      // absences réelles existent déjà → « aucun jour scolaire » trompeur au
      // lieu d'un état « en attente de synchro ». Approximation assumée :
      // `getSyncedAt` (≠ un vrai drapeau bootstrap dédié comme les 2 autres,
      // qui n'existe pas encore côté roster) devient non-nul dès la 1ʳᵉ page
      // reçue, pas seulement au roster complet — couvre le cas réaliste
      // « jamais synchronisé du tout », pas un bootstrap partiel en cours.
      final bootstrapComplete =
          await syncMetaDao.getCursor(kAttendanceBootstrapResource) != null &&
          await syncMetaDao.getCursor(kClassroomTransfersBootstrapResource) !=
              null &&
          (!requiresClassroomMembers ||
              await syncMetaDao.getSyncedAt(kClassroomMembersResource) != null);
      final syncedAt = await syncMetaDao.getSyncedAt(kAttendanceResource);

      return Right(
        StudentAttendanceStats(
          period: period,
          from: from,
          to: to,
          daysCalled: daysCalled,
          entries: absenceRows
              .map(
                (r) => StudentAbsenceEntry(
                  date: DateOnlyJsonHelper.fromJson(r.attendanceDate),
                  reason: AbsenceReasonX.fromApiValue(r.absenceReason),
                  reasonNote: r.absenceReasonNote,
                ),
              )
              .toList(growable: false),
          bootstrapComplete: bootstrapComplete,
          syncedAt: syncedAt,
        ),
      );
    } catch (_) {
      return const Left(StorageFailure('Local attendance stats failed'));
    }
  }

  /// Jours appelés d'un élève **transféré** : somme des sessions sur chacun de
  /// ses intervalles d'appartenance (F6). Un intervalle `[début, fin]` (bornes
  /// de date **inclusives**, `null` = ouvert) dans une classe donnée est croisé
  /// avec la période demandée, puis on compte les sessions de cette classe.
  ///
  /// Découpage (transferts triés par `transferred_at` croissant, dates `d_i`) :
  ///  - avant `d_0`          → `transfers[0].from`      `[null, d_0 - 1j]`
  ///  - entre `d_i` et `d_i+1` → `transfers[i].to`        `[d_i, d_i+1 - 1j]`
  ///  - après `d_n-1`        → `transfers[n-1].to`       `[d_n-1, null]`
  Future<int> _daysCalledByIntervals({
    required List<ClassroomTransferRow> transfers,
    required String academicYearId,
    required DateTime? periodFrom,
    required DateTime? periodTo,
  }) async {
    DateTime dateOf(int ms) {
      final d = DateTime.fromMillisecondsSinceEpoch(ms);
      return DateTime(d.year, d.month, d.day);
    }

    final dates = [for (final t in transfers) dateOf(t.transferredAt)];

    // (classe, début inclusif ?, fin inclusive ?)
    final segments = <(String, DateTime?, DateTime?)>[
      (
        transfers.first.fromClassroomId,
        null,
        dates.first.subtract(const Duration(days: 1)),
      ),
      for (var i = 0; i < transfers.length - 1; i++)
        (
          transfers[i].toClassroomId,
          dates[i],
          dates[i + 1].subtract(const Duration(days: 1)),
        ),
      (transfers.last.toClassroomId, dates.last, null),
    ];

    var total = 0;
    for (final (classroomId, segStart, segEnd) in segments) {
      final effFrom = _latestOf(segStart, periodFrom);
      final effTo = _earliestOf(segEnd, periodTo);
      if (effFrom != null && effTo != null && effFrom.isAfter(effTo)) {
        continue; // intervalle hors période
      }
      total += await localDataSource.countSessionsBetween(
        classroomId: classroomId,
        academicYearId: academicYearId,
        fromInclusive: effFrom == null
            ? null
            : DateOnlyJsonHelper.toJson(effFrom),
        toInclusive: effTo == null ? null : DateOnlyJsonHelper.toJson(effTo),
      );
    }
    return total;
  }

  /// Borne inférieure inclusive la plus tardive (`null` = ouverte des deux côtés).
  DateTime? _latestOf(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  /// Borne supérieure inclusive la plus précoce (`null` = ouverte des deux côtés).
  DateTime? _earliestOf(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }

  /// Bornes calendaires d'une période (contrat §5.3) : hebdo **lundi→samedi**
  /// (semaine scolaire, pas ISO), mensuel 1er→dernier jour, annuel = null/null
  /// (les sessions sont déjà cadrées par `academic_year_id`).
  (DateTime?, DateTime?) _periodBounds(StatsPeriod period, DateTime reference) {
    final day = DateTime(reference.year, reference.month, reference.day);
    return switch (period) {
      StatsPeriod.year => (null, null),
      StatsPeriod.month => (
        DateTime(day.year, day.month, 1),
        DateTime(day.year, day.month + 1, 0),
      ),
      StatsPeriod.week => () {
        final monday = day.subtract(
          Duration(days: day.weekday - DateTime.monday),
        );
        return (monday, monday.add(const Duration(days: 5))); // samedi
      }(),
    };
  }
}
