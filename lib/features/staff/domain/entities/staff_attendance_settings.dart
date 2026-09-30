import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_clock_time.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Les réglages du Pointage d'une école : l'heure de début des cours et la
/// tolérance avant retard.
///
/// Ils s'appliquent **aux pointages à venir** : la tablette classe au moment
/// du pointage, et un réglage changé ensuite ne reclasse rien.
class StaffAttendanceSettings extends Equatable {
  final StaffClockTime start;

  /// Une des [tolerances].
  final int toleranceMinutes;

  /// Où en est un réglage modifié sur la tablette. Les défauts et un réglage
  /// reçu du serveur sont [StaffSyncState.synced].
  final StaffSyncState syncState;

  const StaffAttendanceSettings({
    required this.start,
    required this.toleranceMinutes,
    this.syncState = StaffSyncState.synced,
  });

  /// Les tolérances proposées, en minutes.
  static const List<int> tolerances = [0, 5, 10, 15, 20];

  /// L'école qui n'a rien posé : 07:30, 10 minutes.
  static final StaffAttendanceSettings defaults = StaffAttendanceSettings(
    start: StaffClockTime.fromMinutes(7 * 60 + 30),
    toleranceMinutes: 10,
  );

  /// L'heure de début la plus tardive qu'on puisse régler : au-delà, la fin
  /// de la tolérance et une arrivée « en retard » ne tiendraient plus dans la
  /// journée, et le serveur refuserait un retard de 0 minute.
  static final StaffClockTime latestStart = StaffClockTime.fromMinutes(18 * 60);

  /// La dernière heure encore « à l'heure ».
  StaffClockTime get lastOnTime => start.plus(toleranceMinutes);

  StaffAttendanceSettings copyWith({
    StaffClockTime? start,
    int? toleranceMinutes,
    StaffSyncState? syncState,
  }) => StaffAttendanceSettings(
    start: start ?? this.start,
    toleranceMinutes: toleranceMinutes ?? this.toleranceMinutes,
    syncState: syncState ?? this.syncState,
  );

  @override
  List<Object?> get props => [start, toleranceMinutes, syncState];
}
