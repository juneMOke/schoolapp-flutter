import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/core/helpers/json_fields.dart';

// Modèles du pointage sur le fil (`/api/v1/sync/staff-attendance`).
//
// ⚠️ Le round-trip `toJson` → `tryParse` EST le chemin du push : l'outbox
// range le texte, le handler le relit avant de pousser. Un champ perdu à la
// relecture partirait muet.

/// Un pointage : ce que la tablette pousse, et ce que le serveur rend (avec
/// sa version et son horloge).
class StaffAttendanceDto {
  final String id;
  final String staffMemberId;

  /// `YYYY-MM-DD`.
  final String workDate;

  /// `NONE` · `PRESENT` · `RETARD` · `ABSENT`.
  final String status;

  /// `HH:mm`, heure locale sans fuseau.
  final String? arrivalTime;
  final String? departureTime;
  final int lateMinutes;
  final int? workedMinutes;
  final String? justificationReason;
  final String? justificationNote;

  /// Instant UTC ISO-8601 : l'horloge d'arbitrage.
  final String clientUpdatedAt;

  /// Posés par le serveur seulement.
  final int? version;
  final String? serverUpdatedAt;

  const StaffAttendanceDto({
    required this.id,
    required this.staffMemberId,
    required this.workDate,
    required this.status,
    required this.clientUpdatedAt,
    this.arrivalTime,
    this.departureTime,
    this.lateMinutes = 0,
    this.workedMinutes,
    this.justificationReason,
    this.justificationNote,
    this.version,
    this.serverUpdatedAt,
  });

  /// Le corps poussé : jamais la version ni l'horloge du serveur.
  Map<String, dynamic> toJson() => {
    'id': id,
    'staffMemberId': staffMemberId,
    'workDate': workDate,
    'status': status,
    'arrivalTime': arrivalTime,
    'departureTime': departureTime,
    'lateMinutes': lateMinutes,
    'workedMinutes': workedMinutes,
    'justificationReason': justificationReason,
    'justificationNote': justificationNote,
    'clientUpdatedAt': clientUpdatedAt,
  };

  static StaffAttendanceDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw.text('id');
    final staffMemberId = raw.text('staffMemberId');
    final workDate = raw.day('workDate');
    final status = raw.text('status');
    final clientUpdatedAt = raw.instant('clientUpdatedAt');
    if (id == null ||
        staffMemberId == null ||
        workDate == null ||
        status == null ||
        clientUpdatedAt == null) {
      return null;
    }
    return StaffAttendanceDto(
      id: id,
      staffMemberId: staffMemberId,
      workDate: workDate,
      status: status,
      arrivalTime: raw.text('arrivalTime'),
      departureTime: raw.text('departureTime'),
      lateMinutes: raw.integer('lateMinutes') ?? 0,
      workedMinutes: raw.integer('workedMinutes'),
      justificationReason: raw.text('justificationReason'),
      justificationNote: raw.text('justificationNote'),
      clientUpdatedAt: clientUpdatedAt,
      version: raw.integer('version'),
      serverUpdatedAt: raw.instant('serverUpdatedAt'),
    );
  }
}

/// Le corps d'une remontée : un pointage et l'auteur du geste.
class StaffAttendanceSyncRequestDto {
  final StaffAttendanceDto staffAttendance;
  final String authorId;

  const StaffAttendanceSyncRequestDto({
    required this.staffAttendance,
    required this.authorId,
  });

  Map<String, dynamic> toJson() => {
    'staffAttendance': staffAttendance.toJson(),
    kOutboxAuthorIdKey: authorId,
  };

  static StaffAttendanceSyncRequestDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final record = StaffAttendanceDto.tryParse(raw['staffAttendance']);
    final authorId = raw.text(kOutboxAuthorIdKey);
    if (record == null || authorId == null) return null;
    return StaffAttendanceSyncRequestDto(
      staffAttendance: record,
      authorId: authorId,
    );
  }
}

/// L'accusé : la ligne telle que stockée, que le serveur ait retenu
/// l'écriture (`APPLIED`) ou gardé une plus récente (`SUPERSEDED`).
class StaffAttendanceSyncResponseDto {
  final StaffAttendanceDto staffAttendance;
  final String lwwOutcome;

  const StaffAttendanceSyncResponseDto({
    required this.staffAttendance,
    required this.lwwOutcome,
  });

  factory StaffAttendanceSyncResponseDto.fromJson(Map<String, dynamic> json) {
    final record = StaffAttendanceDto.tryParse(json['staffAttendance']);
    if (record == null) {
      throw const FormatException('Accusé de pointage illisible');
    }
    return StaffAttendanceSyncResponseDto(
      staffAttendance: record,
      lwwOutcome: (json['lwwOutcome'] as String?) ?? 'APPLIED',
    );
  }
}

/// Une page du flux `hr.staff-attendance`.
class StaffAttendancePageDto extends ParsedKeysetPage<StaffAttendanceDto> {
  StaffAttendancePageDto._(ParsedKeysetPage<StaffAttendanceDto> parsed)
    : super(items: parsed.items, page: parsed.page, skipped: parsed.skipped);

  factory StaffAttendancePageDto.fromJson(Map<String, dynamic> json) =>
      StaffAttendancePageDto._(
        ParsedKeysetPage.fromJson(json, StaffAttendanceDto.tryParse),
      );
}
