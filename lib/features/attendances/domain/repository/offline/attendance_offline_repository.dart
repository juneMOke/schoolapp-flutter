import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_update.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/local_attendance_rate.dart';

/// Contrat de l'appel offline-first (AF-1/2/3).
///
/// Le roster provient de `ref_classroom_members` (produit par Classe). L'écriture
/// est locale + outbox (full-write, LWW). Le taux est dérivé en SQL.
abstract class AttendanceOfflineRepository {
  /// Vue fusionnée d'un appel (AF-1) : tout le roster ACTIVE présent par
  /// défaut, écrasé par les absences/retards locaux du jour.
  Future<Either<Failure, List<AttendanceRecord>>> loadDailyAttendance({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
  });

  /// Confirme l'appel (AF-2) : matérialise l'état complet localement (par
  /// exception) et enfile UNE entrée d'outbox full-write — atomiquement.
  Future<Either<Failure, void>> recordDailyAttendance({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
    required List<AttendanceUpdate> updates,
  });

  /// Taux de présence dérivé localement (AF-3).
  Future<Either<Failure, LocalAttendanceRate>> getAttendanceRate({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
  });
}
