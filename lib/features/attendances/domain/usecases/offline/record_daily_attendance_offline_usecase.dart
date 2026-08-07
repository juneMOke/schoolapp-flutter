import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_update.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/attendance_offline_repository.dart';

/// Confirme l'appel offline (AF-2) : écriture locale par exception + outbox
/// full-write, atomiquement. Rejouer avec l'état complet corrige via LWW.
class RecordDailyAttendanceOfflineUseCase {
  final AttendanceOfflineRepository _repository;

  const RecordDailyAttendanceOfflineUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
    required List<AttendanceUpdate> updates,
  }) => _repository.recordDailyAttendance(
    classroomId: classroomId,
    date: date,
    academicYearId: academicYearId,
    updates: updates,
  );
}
