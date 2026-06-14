import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/absence_reason_stats.dart';

class AbsenceReasonStatsModel {
  final String? reason;
  final int absenceDays;

  const AbsenceReasonStatsModel({
    required this.reason,
    required this.absenceDays,
  });

  factory AbsenceReasonStatsModel.fromJson(Map<String, dynamic> json) {
    return AbsenceReasonStatsModel(
      reason: json['reason'] as String?,
      absenceDays: (json['count'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'reason': reason,
    'count': absenceDays,
  };

  AbsenceReasonStats toEntity() => AbsenceReasonStats(
    reason: AbsenceReasonX.fromApiValue(reason),
    absenceDays: absenceDays,
  );
}
