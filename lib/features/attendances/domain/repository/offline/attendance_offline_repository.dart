import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_update.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/daily_attendance.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/local_attendance_rate.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/student_attendance_stats.dart';

/// Contrat de l'appel offline-first (AF-1/2/3).
///
/// Le roster provient de `ref_classroom_members` (produit par Classe). L'écriture
/// est locale + outbox (agrégat session, LWW). Le taux est dérivé en SQL.
abstract class AttendanceOfflineRepository {
  /// Vue d'un appel (AF-1) portant les **3 états** : `taken` (session existe ?)
  /// + roster ACTIVE présent par défaut, écrasé par les absences locales.
  Future<Either<Failure, DailyAttendance>> loadDailyAttendance({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
  });

  /// Confirme l'appel (AF-2) : matérialise la session + ses exceptions (par
  /// exception) et enfile UNE entrée d'outbox — atomiquement.
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

  /// Statistiques d'assiduité d'un élève sur une période (AF-3, §5), calculées
  /// **en local** : dénominateur = jours appelés de sa classe COURANTE
  /// (résolue en interne depuis `ref_classroom_members`, composition CF3/CF4 —
  /// aucun classroomId requis de l'appelant), numérateur = ses absences
  /// détaillées. Périodes calendaires (hebdo lundi→samedi, mensuel, annuel).
  /// Gardé par `bootstrapComplete` (invariant #7).
  Future<Either<Failure, StudentAttendanceStats>> getStudentAttendanceStats({
    required String studentId,
    required String academicYearId,
    required StatsPeriod period,
    required DateTime reference,
  });
}
