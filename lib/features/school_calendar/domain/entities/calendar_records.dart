import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';

/// Un cadre national publié, pour une année (une ligne de `calendar.framework`).
class NationalFramework extends Equatable {
  final String id;
  final String yearLabel;
  final int version;
  final DateTime startDate;
  final DateTime endDate;
  final List<CalendarElement> items;

  const NationalFramework({
    required this.id,
    required this.yearLabel,
    required this.version,
    required this.startDate,
    required this.endDate,
    required this.items,
  });

  @override
  List<Object?> get props => [
    id,
    yearLabel,
    version,
    startDate,
    endDate,
    items,
  ];
}

/// Un événement de l'école tel que l'appareil le connaît : l'élément, son
/// calendrier, et où en est son envoi.
class SchoolEventRecord extends Equatable {
  final CalendarElement element;
  final String calendarId;
  final int clientUpdatedAtMs;
  final bool deleted;
  final RecordSyncState syncState;

  /// Le code du refus (`CALENDAR_ARCHIVED`…), sur [RecordSyncState.failed].
  final String? errorCode;

  /// Un autre appareil a gagné : l'écran le signale une fois, puis l'efface.
  final bool superseded;

  const SchoolEventRecord({
    required this.element,
    required this.calendarId,
    required this.clientUpdatedAtMs,
    this.deleted = false,
    this.syncState = RecordSyncState.synced,
    this.errorCode,
    this.superseded = false,
  });

  bool get isPending => syncState == RecordSyncState.pending;

  bool get isRejected => syncState == RecordSyncState.failed;

  @override
  List<Object?> get props => [
    element,
    calendarId,
    clientUpdatedAtMs,
    deleted,
    syncState,
    errorCode,
    superseded,
  ];
}
