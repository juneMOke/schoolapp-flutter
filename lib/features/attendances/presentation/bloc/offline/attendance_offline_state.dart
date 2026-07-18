import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/daily_attendance.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/local_attendance_rate.dart';
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

/// Appel du jour chargé depuis la base locale (AF-1), avec les 3 états.
class AttendanceOfflineLoaded extends AttendanceOfflineState {
  final DailyAttendance daily;

  const AttendanceOfflineLoaded(this.daily);

  @override
  List<Object?> get props => [daily];
}

class AttendanceOfflineRecording extends AttendanceOfflineState {
  const AttendanceOfflineRecording();
}

/// Appel confirmé localement : écriture par exception + mise en file outbox.
/// État pending-sync exposé à l'UI (AF-2).
class AttendanceOfflinePendingSync extends AttendanceOfflineState {
  const AttendanceOfflinePendingSync();
}

/// Taux de présence dérivé localement (AF-3).
class AttendanceOfflineRateLoaded extends AttendanceOfflineState {
  final LocalAttendanceRate rate;

  const AttendanceOfflineRateLoaded(this.rate);

  @override
  List<Object?> get props => [rate];
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
