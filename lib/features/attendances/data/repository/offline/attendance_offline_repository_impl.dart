import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, SyncEngine, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_history_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_day_writer.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
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

/// Implémentation offline-first de l'appel (AF-1/2/3). Roster lu depuis
/// `ref_classroom_members` (module Classe), écriture locale par exception +
/// outbox full-write, taux dérivé en SQL.
class AttendanceOfflineRepositoryImpl implements AttendanceOfflineRepository {
  final AttendanceLocalDataSource localDataSource;
  final AttendanceHistoryLocalDataSource historyDataSource;
  final ClassroomLocalDataSource rosterDataSource;
  final SyncMetaDao syncMetaDao;
  final IdGenerator idGenerator;
  final CurrentUserContext? _currentUser;
  final SyncEngine? _syncEngine;
  final Clock now;

  const AttendanceOfflineRepositoryImpl({
    required this.localDataSource,
    required this.historyDataSource,
    required this.rosterDataSource,
    required this.syncMetaDao,
    required this.idGenerator,
    CurrentUserContext? currentUser,
    SyncEngine? syncEngine,
    this.now = systemClock,
  }) : _currentUser = currentUser,
       _syncEngine = syncEngine;

  AttendanceDayWriter get _writer => AttendanceDayWriter(
    localDataSource: localDataSource,
    rosterDataSource: rosterDataSource,
    idGenerator: idGenerator,
    currentUser: _currentUser,
    syncEngine: _syncEngine,
    now: now,
  );

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
      final written = await _writer.write(
        classroomId: classroomId,
        dateStr: DateOnlyJsonHelper.toJson(date),
        academicYearId: academicYearId,
        covered: {for (final update in updates) update.studentId},
        lines: [
          for (final update in updates)
            if (!update.present)
              AttendanceDayLine(
                studentId: update.studentId,
                studentFirstName: update.studentFirstName,
                studentLastName: update.studentLastName,
                studentMiddleName: update.studentMiddleName,
                studentGender: update.studentGender.toApiValue(),
                status: PresenceStatus.absent,
                absenceReason: update.absenceReason?.toApiValue(),
                absenceReasonNote: update.absenceReasonNote,
              ),
        ],
      );
      if (written == AttendanceDayWrite.raced) {
        // Une écriture concurrente a pris la main : rien n'a été écrit ni
        // enfilé — surtout ne pas annoncer un succès.
        return const Left(
          StorageFailure(
            'Cet appel vient d\'être modifié ailleurs — rouvrez la journée '
            'pour repartir de l\'état à jour.',
          ),
        );
      }
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
      final absences = await historyDataSource.countAbsences(
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
            : await historyDataSource.countSessions(
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
      final absenceRows = await historyDataSource.getStudentAbsenceRecords(
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
      total += await historyDataSource.countSessionsBetween(
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
