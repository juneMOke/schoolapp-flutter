import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/attendance_pull_outcome.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/attendance_pull_repository.dart';

/// Déclenche le pull keyset de la Présence (hydratation au montage du
/// FeatureScope). Le second déclencheur — retour online — passe par le
/// `PullCoordinator` (`AttendancePullHandler`). Les DEUX sont nécessaires : une
/// tablette démarrée déjà connectée ne tirerait jamais sur le seul signal online.
class SyncAttendancePullUseCase {
  final AttendancePullRepository _repository;

  const SyncAttendancePullUseCase(this._repository);

  Future<Either<Failure, AttendancePullOutcome>> call() =>
      _repository.syncAttendance();
}
