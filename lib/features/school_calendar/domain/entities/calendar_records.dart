import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';

/// Le document officiel du ministère joint à un cadre (PDF servi en ligne).
class FrameworkDocument extends Equatable {
  final String fileName;
  final int? sizeBytes;
  final DateTime? uploadedAt;

  const FrameworkDocument({
    required this.fileName,
    this.sizeBytes,
    this.uploadedAt,
  });

  @override
  List<Object?> get props => [fileName, sizeBytes, uploadedAt];
}

/// Un cadre national publié, pour une année (une ligne de `calendar.framework`).
class NationalFramework extends Equatable {
  final String id;
  final String yearLabel;
  final int version;
  final DateTime startDate;
  final DateTime endDate;
  final List<CalendarElement> items;

  /// Le document officiel, s'il y en a un.
  final FrameworkDocument? document;

  const NationalFramework({
    required this.id,
    required this.yearLabel,
    required this.version,
    required this.startDate,
    required this.endDate,
    required this.items,
    this.document,
  });

  @override
  List<Object?> get props => [
    id,
    yearLabel,
    version,
    startDate,
    endDate,
    items,
    document,
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

  /// Le serveur a déjà accepté une version de l'événement (horloge serveur
  /// connue). Un refus ne vaut « sans effet » que pour une création jamais
  /// acceptée : une modification ou une suppression refusée laisse vivante,
  /// côté serveur, la version acceptée.
  final bool knownToServer;

  const SchoolEventRecord({
    required this.element,
    required this.calendarId,
    required this.clientUpdatedAtMs,
    this.deleted = false,
    this.syncState = RecordSyncState.synced,
    this.errorCode,
    this.superseded = false,
    this.knownToServer = false,
  });

  bool get isPending => syncState == RecordSyncState.pending;

  bool get isRejected => syncState == RecordSyncState.failed;

  /// Refusé à sa création : n'existe pas côté serveur, ne compte pas.
  bool get isRejectedCreation => isRejected && !knownToServer;

  @override
  List<Object?> get props => [
    element,
    calendarId,
    clientUpdatedAtMs,
    deleted,
    syncState,
    errorCode,
    superseded,
    knownToServer,
  ];
}
