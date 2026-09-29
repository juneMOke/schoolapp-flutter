import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_json.dart';

/// Les réglages du Pointage, tels qu'ils sont mis en file puis poussés
/// (`PUT /api/v1/sync/staff-attendance-settings`, dernier écrit gagne).
class StaffAttendanceSettingsRequestDto {
  /// `HH:mm`.
  final String startTime;
  final int toleranceMinutes;
  final String clientUpdatedAt;
  final String authorId;

  const StaffAttendanceSettingsRequestDto({
    required this.startTime,
    required this.toleranceMinutes,
    required this.clientUpdatedAt,
    required this.authorId,
  });

  Map<String, dynamic> toJson() => {
    'staffAttendanceSettings': {
      'startTime': startTime,
      'toleranceMinutes': toleranceMinutes,
      'clientUpdatedAt': clientUpdatedAt,
    },
    kOutboxAuthorIdKey: authorId,
  };

  static StaffAttendanceSettingsRequestDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final settings = raw['staffAttendanceSettings'];
    if (settings is! Map) return null;
    final startTime = settings.text('startTime');
    final tolerance = settings.integer('toleranceMinutes');
    final clientUpdatedAt = settings.text('clientUpdatedAt');
    final authorId = raw.text(kOutboxAuthorIdKey);
    if (startTime == null ||
        tolerance == null ||
        clientUpdatedAt == null ||
        authorId == null) {
      return null;
    }
    return StaffAttendanceSettingsRequestDto(
      startTime: startTime,
      toleranceMinutes: tolerance,
      clientUpdatedAt: clientUpdatedAt,
      authorId: authorId,
    );
  }
}
