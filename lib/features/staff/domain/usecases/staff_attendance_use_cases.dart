import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_attendance_repository.dart';

/// Lit le Pointage d'une plage de jours sur la tablette.
class LoadStaffAttendanceUseCase {
  final StaffAttendanceRepository _repository;

  const LoadStaffAttendanceUseCase(this._repository);

  Future<Either<Failure, StaffAttendanceSnapshot>> call({
    required String from,
    required String to,
  }) => _repository.load(from: from, to: to);
}

/// Enregistre des pointages et les met en file d'envoi.
class SaveStaffAttendanceUseCase {
  final StaffAttendanceRepository _repository;

  const SaveStaffAttendanceUseCase(this._repository);

  Future<Either<Failure, Unit>> call(List<StaffAttendanceRecord> records) =>
      records.isEmpty
      ? Future.value(const Right(unit))
      : _repository.saveRecords(records);
}

/// Valide ou rouvre un jour, clôt un mois.
class RecordStaffAttendanceGestureUseCase {
  final StaffAttendanceRepository _repository;

  const RecordStaffAttendanceGestureUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    StaffAttendanceGesture gesture,
    String periodStart,
  ) => _repository.recordGesture(gesture, periodStart);
}

/// Enregistre le début des cours et la tolérance.
class SaveStaffAttendanceSettingsUseCase {
  final StaffAttendanceRepository _repository;

  const SaveStaffAttendanceSettingsUseCase(this._repository);

  Future<Either<Failure, Unit>> call(StaffAttendanceSettings settings) =>
      _repository.saveSettings(settings);
}
