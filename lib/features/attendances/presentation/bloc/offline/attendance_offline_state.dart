import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/student_attendance_stats.dart';

abstract class AttendanceOfflineState extends Equatable {
  const AttendanceOfflineState();

  @override
  List<Object?> get props => [];
}

class AttendanceOfflineInitial extends AttendanceOfflineState {
  const AttendanceOfflineInitial();
}

class AttendanceOfflineLoading extends AttendanceOfflineState {
  const AttendanceOfflineLoading();
}

/// Statistiques d'assiduité d'un élève sur une période (AF-3, §5). L'UI ne doit
/// afficher les chiffres que si `stats.available` (bootstrapComplete).
class AttendanceOfflineStatsLoaded extends AttendanceOfflineState {
  final StudentAttendanceStats stats;

  const AttendanceOfflineStatsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

class AttendanceOfflineError extends AttendanceOfflineState {
  final String message;

  const AttendanceOfflineError(this.message);

  @override
  List<Object?> get props => [message];
}
