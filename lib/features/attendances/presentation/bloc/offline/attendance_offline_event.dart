import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_update.dart';

abstract class AttendanceOfflineEvent extends Equatable {
  const AttendanceOfflineEvent();

  @override
  List<Object?> get props => [];
}

/// Charge la liste d'appel locale d'un jour pour une classe (AF-1).
class LoadDailyAttendanceRequested extends AttendanceOfflineEvent {
  final String classroomId;
  final DateTime date;
  final String academicYearId;

  const LoadDailyAttendanceRequested({
    required this.classroomId,
    required this.date,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [classroomId, date, academicYearId];
}

/// Confirme l'appel offline (écriture locale + outbox) pour un jour (AF-2).
class RecordDailyAttendanceRequested extends AttendanceOfflineEvent {
  final String classroomId;
  final DateTime date;
  final String academicYearId;
  final List<AttendanceUpdate> updates;

  const RecordDailyAttendanceRequested({
    required this.classroomId,
    required this.date,
    required this.academicYearId,
    required this.updates,
  });

  @override
  List<Object?> get props => [classroomId, date, academicYearId, updates];
}

/// Demande le taux de présence dérivé localement (AF-3).
class LoadLocalRateRequested extends AttendanceOfflineEvent {
  final String classroomId;
  final DateTime date;
  final String academicYearId;

  const LoadLocalRateRequested({
    required this.classroomId,
    required this.date,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [classroomId, date, academicYearId];
}
