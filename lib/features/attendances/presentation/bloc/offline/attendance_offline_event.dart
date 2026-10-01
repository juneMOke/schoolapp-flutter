import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';

abstract class AttendanceOfflineEvent extends Equatable {
  const AttendanceOfflineEvent();

  @override
  List<Object?> get props => [];
}

/// Demande les statistiques d'assiduité d'un élève sur une période (AF-3, §5).
/// [reference] = date de référence (fournie par l'UI, ex. aujourd'hui). La
/// classe courante de l'élève est résolue en interne (composition CF3/CF4),
/// pas besoin de la fournir.
class LoadStudentStatsRequested extends AttendanceOfflineEvent {
  final String studentId;
  final String academicYearId;
  final StatsPeriod period;
  final DateTime reference;

  const LoadStudentStatsRequested({
    required this.studentId,
    required this.academicYearId,
    required this.period,
    required this.reference,
  });

  @override
  List<Object?> get props => [studentId, academicYearId, period, reference];
}
