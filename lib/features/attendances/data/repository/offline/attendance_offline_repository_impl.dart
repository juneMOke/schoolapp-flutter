import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_record_row.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/offline_attendance_update_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/offline_daily_attendance_command_model.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_update.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/local_attendance_rate.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/attendance_offline_repository.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';

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
  Future<Either<Failure, List<AttendanceRecord>>> loadDailyAttendance({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
  }) async {
    try {
      final dateStr = DateOnlyJsonHelper.toJson(date);
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

      return Right(records);
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

      final rows = updates
          .map(
            (u) => AttendanceRecordRow(
              id: idGenerator.newId(),
              studentId: u.studentId,
              studentFirstName: u.studentFirstName,
              studentLastName: u.studentLastName,
              studentMiddleName: u.studentMiddleName,
              studentGender: u.studentGender.toApiValue(),
              classroomId: classroomId,
              attendanceDate: dateStr,
              academicYearId: academicYearId,
              present: u.present,
              absenceReason: u.present ? null : u.absenceReason?.toApiValue(),
              absenceReasonNote: u.present ? null : u.absenceReasonNote,
              updatedAt: nowMs,
              syncStatus: SyncState.pendingSync.dbValue,
            ),
          )
          .toList(growable: false);

      final command = OfflineDailyAttendanceCommandModel(
        classroomId: classroomId,
        date: dateStr,
        academicYearId: academicYearId,
        updates: updates
            .map(
              (u) => OfflineAttendanceUpdateModel.fromEntity(
                u,
                updatedAtMs: nowMs,
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
        payload: command.toJsonString(),
        createdAt: nowMs,
      );

      await localDataSource.confirmDailyAttendance(
        rows: rows,
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
}
