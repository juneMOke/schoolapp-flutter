import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/local_attendance_rate.dart';

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

/// Liste d'appel du jour chargée depuis la base locale (AF-1).
class AttendanceOfflineLoaded extends AttendanceOfflineState {
  final List<AttendanceRecord> records;

  const AttendanceOfflineLoaded(this.records);

  @override
  List<Object?> get props => [records];
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

class AttendanceOfflineError extends AttendanceOfflineState {
  final String message;

  const AttendanceOfflineError(this.message);

  @override
  List<Object?> get props => [message];
}
