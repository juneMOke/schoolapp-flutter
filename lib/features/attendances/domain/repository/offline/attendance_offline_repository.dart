import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/student_attendance_stats.dart';

/// L'assiduité d'un élève calculée sur la tablette (AF-3). L'appel d'une
/// classe a son propre contrat (`ClassPresenceRepository`).
abstract class AttendanceOfflineRepository {
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
