import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Un jour validé (rapport journalier) ou un mois clos, **tel que la tablette
/// le montre** : le dernier geste posé sur la tablette l'emporte sur l'état du
/// serveur tant qu'il n'est pas accusé.
class StaffAttendanceLock extends Equatable {
  final StaffAttendanceLockKind kind;

  /// Le jour, ou le 1er du mois, `YYYY-MM-DD`.
  final String periodStart;

  final bool locked;

  /// Qui a verrouillé, et quand (ISO-8601) — l'auteur est un nom lisible
  /// quand le serveur le donne, `null` sinon.
  final String? lockedAt;
  final String? lockedByName;

  /// Où en est le dernier geste de la tablette sur cette période ;
  /// [RecordSyncState.synced] quand il n'y en a pas.
  final RecordSyncState syncState;

  const StaffAttendanceLock({
    required this.kind,
    required this.periodStart,
    required this.locked,
    this.lockedAt,
    this.lockedByName,
    this.syncState = RecordSyncState.synced,
  });

  @override
  List<Object?> get props => [
    kind,
    periodStart,
    locked,
    lockedAt,
    lockedByName,
    syncState,
  ];
}
