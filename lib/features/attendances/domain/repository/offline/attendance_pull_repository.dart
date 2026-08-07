import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/attendance_pull_outcome.dart';

/// Contrat du PULL KEYSET de la Présence (`GET /sync/attendance`). Cadré à
/// l'année, résumable, ne lève jamais (échec encodé en `Left`).
abstract class AttendancePullRepository {
  Future<Either<Failure, AttendancePullOutcome>> syncAttendance();
}
