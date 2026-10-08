import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/student_suspension.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_reason.dart';

/// Une ligne de `enrollment_suspensions`, lue telle quelle.
class EnrollmentSuspensionRow {
  final Map<String, Object?> map;

  const EnrollmentSuspensionRow(this.map);

  static const String table = 'enrollment_suspensions';

  String get id => map['id']! as String;
  String get enrollmentId => map['enrollment_id']! as String;
  String get studentId => map['student_id']! as String;
  String get academicYearId => map['academic_year_id']! as String;
  String? get reactivationId => map['reactivation_id'] as String?;
  String? get reactivatedAt => map['reactivated_at'] as String?;
  RecordSyncState get syncState =>
      RecordSyncState.fromDb(map['sync_status'] as String?);

  StudentSuspension toEntity() => StudentSuspension(
    id: id,
    enrollmentId: enrollmentId,
    studentId: studentId,
    academicYearId: academicYearId,
    suspendedAt: _instant(map['suspended_at'])!,
    suspendedBy: map['suspended_by'] as String?,
    reason: SuspensionReason.fromWire(map['reason'] as String?),
    precision: map['precision'] as String?,
    reactivatedAt: _instant(reactivatedAt),
    syncState: syncState,
    syncError: map['sync_error'] as String?,
  );

  static DateTime? _instant(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
