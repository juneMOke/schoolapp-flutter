import 'package:school_app_flutter/core/helpers/json_fields.dart';
import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Une période de désactivation telle que le serveur la rend — ligne du flux
/// `enrollment.suspensions` et état canonique d'un geste
/// (`EnrollmentSuspensionDelta`).
class SuspensionPeriodDto {
  final String id;
  final String enrollmentId;
  final String studentId;
  final String academicYearId;
  final String suspendedAt;
  final String? suspendedBy;
  final String? reason;
  final String? precision;
  final String? reactivationId;
  final String? reactivatedAt;
  final String? reactivatedBy;
  final String? serverUpdatedAt;

  const SuspensionPeriodDto({
    required this.id,
    required this.enrollmentId,
    required this.studentId,
    required this.academicYearId,
    required this.suspendedAt,
    this.suspendedBy,
    this.reason,
    this.precision,
    this.reactivationId,
    this.reactivatedAt,
    this.reactivatedBy,
    this.serverUpdatedAt,
  });

  bool get isOpen => reactivatedAt == null;

  static SuspensionPeriodDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw.text('id');
    final enrollmentId = raw.text('enrollmentId');
    final studentId = raw.text('studentId');
    final yearId = raw.text('academicYearId');
    final suspendedAt = raw.instant('suspendedAt');
    if (id == null ||
        enrollmentId == null ||
        studentId == null ||
        yearId == null ||
        suspendedAt == null) {
      return null;
    }
    return SuspensionPeriodDto(
      id: id,
      enrollmentId: enrollmentId,
      studentId: studentId,
      academicYearId: yearId,
      suspendedAt: suspendedAt,
      suspendedBy: raw.text('suspendedBy'),
      reason: raw.text('reason'),
      precision: raw.text('precision'),
      reactivationId: raw.text('reactivationId'),
      reactivatedAt: raw.instant('reactivatedAt'),
      reactivatedBy: raw.text('reactivatedBy'),
      serverUpdatedAt: raw.instant('serverUpdatedAt'),
    );
  }

  /// La ligne locale qu'elle devient : la vérité du serveur, sans geste en
  /// attente.
  Map<String, Object?> toRow({required String schoolId, required int nowMs}) =>
      {
        'id': id,
        'school_id': schoolId,
        'enrollment_id': enrollmentId,
        'student_id': studentId,
        'academic_year_id': academicYearId,
        'suspended_at': suspendedAt,
        'suspended_by': suspendedBy,
        'reason': reason,
        'precision': precision,
        'reactivation_id': reactivationId,
        'reactivated_at': reactivatedAt,
        'reactivated_by': reactivatedBy,
        'server_updated_at': serverUpdatedAt,
        'pending_op': null,
        'sync_status': RecordSyncState.synced.dbValue,
        'sync_error': null,
        'sync_error_code': null,
        'updated_at': nowMs,
      };
}

/// L'état canonique d'une inscription après un geste
/// (`SuspensionGestureResponse`) : [period] est l'ouverte si l'élève est
/// désactivé, sinon la dernière fermée, ou `null` s'il ne l'a jamais été.
class SuspensionGestureAckDto {
  final String enrollmentId;
  final bool suspended;
  final SuspensionPeriodDto? period;

  const SuspensionGestureAckDto({
    required this.enrollmentId,
    required this.suspended,
    this.period,
  });

  static SuspensionGestureAckDto parse(Object? json) {
    final enrollmentId = json is Map ? json.text('enrollmentId') : null;
    final suspended = json is Map ? json.flag('suspended') : null;
    if (json is! Map || enrollmentId == null || suspended == null) {
      throw const FormatException('Accusé de désactivation illisible');
    }
    return SuspensionGestureAckDto(
      enrollmentId: enrollmentId,
      suspended: suspended,
      period: SuspensionPeriodDto.tryParse(json['period']),
    );
  }
}

/// Page du flux `enrollment.suspensions`.
class SuspensionPageDto extends ParsedKeysetPage<SuspensionPeriodDto> {
  SuspensionPageDto._(ParsedKeysetPage<SuspensionPeriodDto> parsed)
    : super(items: parsed.items, page: parsed.page, skipped: parsed.skipped);

  factory SuspensionPageDto.fromJson(Map<String, dynamic> json) =>
      SuspensionPageDto._(
        ParsedKeysetPage.fromJson(json, SuspensionPeriodDto.tryParse),
      );
}
