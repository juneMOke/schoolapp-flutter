import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_local_model.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_gesture_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_lock_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_settings_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_dao.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_local_writer.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_lock_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_settings_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_attendance_repository.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_repository.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';

/// Le Pointage sur la tablette : lecture locale, écriture en outbox, modèles
/// convertis en entités ici et nulle part ailleurs (règle n°3).
///
/// Les agents viennent du fichier du personnel ([StaffRepository]) : une
/// seule lecture des fiches, frise des contrats locale comprise.
class StaffAttendanceRepositoryImpl implements StaffAttendanceRepository {
  final StaffRepository _staff;
  final StaffAttendanceDao _records;
  final StaffAttendanceWriteDao _writer;
  final StaffAttendanceLockDao _locks;
  final StaffAttendanceGestureDao _gestures;
  final StaffAttendanceSettingsDao _settings;
  final StaffContractDao _contracts;
  final StaffLocalWriter _local;
  final IdGenerator _ids;
  final DateTime Function() _now;

  const StaffAttendanceRepositoryImpl({
    required StaffRepository staff,
    required StaffAttendanceDao records,
    required StaffAttendanceWriteDao writer,
    required StaffAttendanceLockDao locks,
    required StaffAttendanceGestureDao gestures,
    required StaffAttendanceSettingsDao settings,
    required StaffContractDao contracts,
    required StaffLocalWriter local,
    required IdGenerator ids,
    DateTime Function() now = DateTime.now,
  }) : _staff = staff,
       _records = records,
       _writer = writer,
       _locks = locks,
       _gestures = gestures,
       _settings = settings,
       _contracts = contracts,
       _local = local,
       _ids = ids,
       _now = now;

  @override
  Future<Either<Failure, StaffAttendanceSnapshot>> load({
    required String from,
    required String to,
  }) async {
    final session = _local.session();
    if (session == null) return Right(StaffAttendanceSnapshot.empty);
    return (await _staff.loadFile())
        .fold<Future<Either<Failure, StaffAttendanceSnapshot>>>(
          (failure) async => Left(failure),
          (file) async {
            try {
              return Right(await _compose(session.schoolId, file, from, to));
            } catch (e) {
              return Left(StorageFailure('Lecture du pointage : $e'));
            }
          },
        );
  }

  Future<StaffAttendanceSnapshot> _compose(
    String schoolId,
    StaffFileSnapshot file,
    String from,
    String to,
  ) async {
    final records = <String, Map<String, StaffAttendanceRecord>>{};
    for (final row in await _records.forRange(schoolId, from: from, to: to)) {
      final record = row.toEntity();
      (records[record.staffMemberId] ??= {})[record.workDate] = record;
    }
    final locks = await _locks.effective(
      schoolId,
      from: SchoolDayCalendar.firstOf(SchoolDayCalendar.monthOf(from)),
      to: to,
    );
    return StaffAttendanceSnapshot(
      members: file.members,
      records: records,
      locks: {
        for (final lock in locks)
          StaffAttendanceSnapshot.lockKey(lock.kind, lock.periodStart): lock,
      },
      settings: await _settings.read(schoolId),
      schoolYear: await _settings.currentSchoolYear(schoolId),
      contractRates: await _contractRates(schoolId),
      hasEverSynced: file.hasEverSynced,
    );
  }

  @override
  Future<Either<Failure, Unit>> saveRecords(
    List<StaffAttendanceRecord> records,
  ) async {
    final session = _local.session();
    if (session == null) return const Left(StaffLocalWriter.noSession);
    final refusal = await _frozenRefusal(session.schoolId, {
      for (final record in records) record.workDate,
    });
    if (refusal != null) return Left(refusal);
    final now = _now();
    final stamp = now.toUtc().toIso8601String();
    return _local.run(
      'Écriture du pointage',
      () => _writer.save(
        [
          for (final record in records)
            StaffAttendanceSyncRequestDto(
              staffAttendance: StaffAttendanceLocalModel.toWire(
                record,
                clientUpdatedAt: stamp,
              ),
              authorId: session.authorId,
            ),
        ],
        schoolId: session.schoolId,
        nowMs: now.millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> recordGesture(
    StaffAttendanceGesture gesture,
    String periodStart,
  ) async {
    final session = _local.session();
    if (session == null) return const Left(StaffLocalWriter.noSession);
    final now = _now();
    final recordedAt = now.toUtc().toIso8601String();
    return _local.run(
      'Écriture du rapport',
      () => _gestures.add(
        StaffAttendanceGestureRequestDto(
          gestureId: _ids.newId(),
          gesture: gesture.wire,
          date: periodStart,
          clientRecordedAt: recordedAt,
          authorId: session.authorId,
        ),
        kind: gesture.kind,
        authorName: null,
        recordedAt: recordedAt,
        schoolId: session.schoolId,
        nowMs: now.millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> saveSettings(
    StaffAttendanceSettings settings,
  ) async {
    final session = _local.session();
    if (session == null) return const Left(StaffLocalWriter.noSession);
    final now = _now();
    return _local.run(
      'Écriture des réglages',
      () => _settings.save(
        StaffAttendanceSettingsRequestDto(
          startTime: settings.start.wire,
          toleranceMinutes: settings.toleranceMinutes,
          clientUpdatedAt: now.toUtc().toIso8601String(),
          authorId: session.authorId,
        ),
        schoolId: session.schoolId,
        nowMs: now.millisecondsSinceEpoch,
      ),
    );
  }

  /// Un jour validé ou un mois clos refuse l'écriture, avant qu'elle ne parte
  /// pour revenir en refus définitif.
  Future<Failure?> _frozenRefusal(String schoolId, Set<String> days) async {
    if (days.isEmpty) return null;
    final sorted = days.toList()..sort();
    final locks = await _locks.effective(
      schoolId,
      from: SchoolDayCalendar.firstOf(SchoolDayCalendar.monthOf(sorted.first)),
      to: sorted.last,
    );
    for (final lock in locks) {
      if (!lock.locked) continue;
      final hit = lock.kind == StaffAttendanceLockKind.day
          ? days.contains(lock.periodStart)
          : days.any((day) => day.startsWith(lock.periodStart.substring(0, 7)));
      if (!hit) continue;
      return ValidationFailure(
        lock.kind == StaffAttendanceLockKind.day
            ? kStaffDayLockedCode
            : kStaffMonthClosedCode,
      );
    }
    return null;
  }

  /// Le taux des contrats « heures prestées », par contrat — vide quand le
  /// compte ne voit pas les montants. Chaque jour se valorise au taux du
  /// contrat qui le couvre.
  Future<Map<String, Money>> _contractRates(String schoolId) async => {
    for (final row in await _contracts.forSchool(schoolId))
      if (row.toEntity() case final contract
          when contract.amount != null && contract.asPeriod.isHourlyVacataire)
        contract.id: contract.amount!,
  };
}
