import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_schedule.dart';

/// Les réglages du Pointage d'une école : l'horaire commun ([PresenceSchedule])
/// et où en est sa modification sur la tablette.
class StaffAttendanceSettings extends PresenceSchedule {
  /// Où en est un réglage modifié sur la tablette. Les défauts et un réglage
  /// reçu du serveur sont [RecordSyncState.synced].
  final RecordSyncState syncState;

  const StaffAttendanceSettings({
    required super.start,
    required super.toleranceMinutes,
    this.syncState = RecordSyncState.synced,
  });

  /// L'école qui n'a rien posé : l'horaire par défaut, au serveur.
  static final StaffAttendanceSettings defaults = StaffAttendanceSettings(
    start: PresenceSchedule.defaults.start,
    toleranceMinutes: PresenceSchedule.defaults.toleranceMinutes,
  );

  StaffAttendanceSettings copyWith({
    ClockTime? start,
    int? toleranceMinutes,
    RecordSyncState? syncState,
  }) => StaffAttendanceSettings(
    start: start ?? this.start,
    toleranceMinutes: toleranceMinutes ?? this.toleranceMinutes,
    syncState: syncState ?? this.syncState,
  );

  @override
  List<Object?> get props => [...super.props, syncState];
}
