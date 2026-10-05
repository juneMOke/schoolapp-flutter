import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/core/helpers/json_fields.dart';

// Modèles des verrous du Pointage (`/api/v1/sync/staff-attendance-locks`) :
// un jour validé, un mois clos, et le geste qui les pose.

/// L'état d'un verrou, tel que le serveur le tient.
class StaffAttendanceLockDto {
  /// `DAY` · `MONTH`.
  final String kind;

  /// Le jour, ou le 1er du mois, `YYYY-MM-DD`.
  final String periodStart;

  /// `LOCKED` · `OPEN`.
  final String state;
  final String? lockedAt;

  /// Nom lisible de qui a verrouillé, quand le serveur le donne.
  final String? lockedByName;
  final int? version;
  final String? serverUpdatedAt;

  const StaffAttendanceLockDto({
    required this.kind,
    required this.periodStart,
    required this.state,
    this.lockedAt,
    this.lockedByName,
    this.version,
    this.serverUpdatedAt,
  });

  bool get isLocked => state == 'LOCKED';

  static StaffAttendanceLockDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    // L'accusé d'un geste peut envelopper l'état ; le flux le donne à nu.
    final inner = raw['staffAttendanceLock'];
    if (inner is Map) return tryParse(inner);
    final kind = raw.text('kind');
    final periodStart = raw.day('periodStart') ?? raw.day('date');
    final state = raw.text('state');
    if (kind == null || periodStart == null || state == null) return null;
    return StaffAttendanceLockDto(
      kind: kind,
      periodStart: periodStart,
      state: state,
      lockedAt: raw.instant('lockedAt'),
      lockedByName: raw.text('lockedByName'),
      version: raw.integer('version'),
      serverUpdatedAt: raw.instant('serverUpdatedAt'),
    );
  }

  /// L'accusé d'un geste. Illisible = exception : l'écriture a eu lieu, mais
  /// la tablette ne sait pas en quoi.
  factory StaffAttendanceLockDto.fromJson(Map<String, dynamic> json) =>
      tryParse(json) ??
      (throw const FormatException('Accusé de verrou illisible'));
}

/// Un geste de verrou, tel qu'il est mis en file puis poussé.
class StaffAttendanceGestureRequestDto {
  /// Clé d'idempotence : un geste rejoué n'est jamais réappliqué.
  final String gestureId;

  /// `VALIDATE_DAY` · `REOPEN_DAY` · `CLOSE_MONTH`.
  final String gesture;

  /// Le jour, ou le 1er du mois.
  final String date;

  /// Quand le geste a été posé sur la tablette (instant UTC ISO-8601), exigé
  /// par le serveur.
  final String clientRecordedAt;
  final String authorId;

  const StaffAttendanceGestureRequestDto({
    required this.gestureId,
    required this.gesture,
    required this.date,
    required this.clientRecordedAt,
    required this.authorId,
  });

  Map<String, dynamic> toJson() => {
    'gestureId': gestureId,
    'gesture': gesture,
    'date': date,
    'clientRecordedAt': clientRecordedAt,
    kOutboxAuthorIdKey: authorId,
  };

  static StaffAttendanceGestureRequestDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final gestureId = raw.text('gestureId');
    final gesture = raw.text('gesture');
    final date = raw.day('date');
    final clientRecordedAt = raw.instant('clientRecordedAt');
    final authorId = raw.text(kOutboxAuthorIdKey);
    if (gestureId == null ||
        gesture == null ||
        date == null ||
        clientRecordedAt == null ||
        authorId == null) {
      return null;
    }
    return StaffAttendanceGestureRequestDto(
      gestureId: gestureId,
      gesture: gesture,
      date: date,
      clientRecordedAt: clientRecordedAt,
      authorId: authorId,
    );
  }
}

/// Une page du flux `hr.staff-attendance-locks`.
class StaffAttendanceLockPageDto
    extends ParsedKeysetPage<StaffAttendanceLockDto> {
  StaffAttendanceLockPageDto._(ParsedKeysetPage<StaffAttendanceLockDto> parsed)
    : super(items: parsed.items, page: parsed.page, skipped: parsed.skipped);

  factory StaffAttendanceLockPageDto.fromJson(Map<String, dynamic> json) =>
      StaffAttendanceLockPageDto._(
        ParsedKeysetPage.fromJson(json, StaffAttendanceLockDto.tryParse),
      );
}
