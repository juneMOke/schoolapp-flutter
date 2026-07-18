import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
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
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/attendance_offline_repository.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_transfer_row.dart';
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
  final Clock now;

  const AttendanceOfflineRepositoryImpl({
    required this.localDataSource,
    required this.rosterDataSource,
    required this.syncMetaDao,
    required this.idGenerator,
    this.now = systemClock,
  });

  /// Clé d'idempotence / id déterministe d'outbox pour un appel.
  static String outboxKey(
    String classroomId,
    String dateStr,
    String academicYearId,
  ) => '$classroomId|$dateStr|$academicYearId';

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
      final nowMs = now();
      final nowIso = DateTime.fromMillisecondsSinceEpoch(
        nowMs,
        isUtc: true,
      ).toIso8601String();

      // Id de session STABLE (id = transport, clé naturelle = vérité) : on
      // réutilise l'id local existant s'il y en a un, sinon on en forge un.
      final existingSession = await localDataSource.getSession(
        classroomId: classroomId,
        dateStr: dateStr,
        academicYearId: academicYearId,
      );
      final sessionId = existingSession?.id ?? idGenerator.newId();

      // Racine d'agrégat : la session porte l'`updated_at` arbitre, rebumpé à
      // chaque confirmation (invariant #4).
      final session = AttendanceSessionRow(
        id: sessionId,
        classroomId: classroomId,
        attendanceDate: dateStr,
        academicYearId: academicYearId,
        takenAt: nowMs,
        updatedAt: nowMs,
        syncStatus: SyncState.pendingSync.dbValue,
      );

      // Écriture par exception : SEULS les absents portent une ligne. Les
      // présents redeviennent une non-ligne via la réconciliation par différence.
      final absentRows = updates
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

      // Payload d'outbox = agrégat exhaustif `{session, absences[]}` (contrat 1.2.0).
      final aggregate = AttendanceAggregateRequestModel(
        session: AttendanceSessionInputModel(
          id: sessionId,
          classroomId: classroomId,
          attendanceDate: dateStr,
          academicYearId: academicYearId,
          takenAt: nowIso,
          updatedAt: nowIso,
        ),
        absences: absentRows
            .map(
              (r) => AttendanceAbsenceInputModel(
                id: r.id,
                studentId: r.studentId,
                absenceReason: r.absenceReason,
                absenceReasonNote: r.absenceReasonNote,
                updatedAt: nowIso,
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

      await localDataSource.confirmDailyAttendance(
        session: session,
        absentRows: absentRows,
        outboxEntry: entry,
      );
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
      // Fraîcheur du roster sous-jacent (curseur des classes, cf. Classe CF2).
      final syncedAt = await syncMetaDao.getSyncedAt('classrooms');
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
    required String classroomId,
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
      // aucun transfert (quasi-totalité) → une seule classe = comportement d'avant.
      final transfers = await rosterDataSource.getStudentSyncedTransfers(
        studentId: studentId,
        academicYearId: academicYearId,
      );
      final daysCalled = transfers.isEmpty
          ? await localDataSource.countSessions(
              classroomId: classroomId,
              academicYearId: academicYearId,
              fromStr: fromStr,
              toStr: toStr,
            )
          : await _daysCalledByIntervals(
              transfers: transfers,
              academicYearId: academicYearId,
              periodFrom: from,
              periodTo: to,
            );
      final absences = await localDataSource.countStudentAbsences(
        studentId: studentId,
        academicYearId: academicYearId,
        fromStr: fromStr,
        toStr: toStr,
      );
      // Invariant #7 : un chiffre n'est fiable qu'une fois l'année entière tirée
      // — côté appels ET côté transferts (un historique de transfert partiel
      // donnerait un dénominateur faux mais plausible, donc indétectable).
      final bootstrapComplete =
          await syncMetaDao.getCursor(kAttendanceBootstrapResource) != null &&
          await syncMetaDao.getCursor(kClassroomTransfersBootstrapResource) !=
              null;
      final syncedAt = await syncMetaDao.getSyncedAt(kAttendanceResource);

      return Right(
        StudentAttendanceStats(
          period: period,
          from: from,
          to: to,
          daysCalled: daysCalled,
          absences: absences,
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
