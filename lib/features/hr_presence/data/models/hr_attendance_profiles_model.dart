import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/features/hr_presence/data/models/hr_attendance_agent_model.dart';
import 'package:school_app_flutter/features/hr_presence/data/models/hr_attendance_json.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_profiles.dart';

/// Miroir de `AttendanceProfilesDto` (`GET /hr/attendance-stats/profiles`).
abstract final class HrAttendanceProfilesModel {
  static HrAttendanceProfiles fromJson(Map<String, dynamic> json) {
    final year = json['schoolYear'];
    final counts = HrAttendanceJson.map(json['profileCounts']);
    return HrAttendanceProfiles(
      month: json['month'] as String?,
      schoolYear: year == null
          ? null
          : HrAttendanceAgentModel.schoolYear(HrAttendanceJson.map(year)),
      from: json['from'] as String,
      to: json['to'] as String,
      classDays: HrAttendanceJson.count(json, 'classDays'),
      // Les cinq profils, zéro compris : un profil absent de la réponse se
      // compte 0 ; un profil inconnu de ce poste n'est pas affiché.
      profileCounts: {
        for (final profile in PresenceProfile.values)
          profile: (counts[profile.wire] as num?)?.toInt() ?? 0,
      },
      staff: [
        for (final row in HrAttendanceJson.list(json['staff']))
          HrAttendanceProfileRow(
            agent: HrAttendanceJson.agent(row),
            scored: HrAttendanceJson.count(row, 'scored'),
            presenceRatePct: HrAttendanceJson.rate(row, 'presenceRatePct'),
            lateRatePct: HrAttendanceJson.rate(row, 'lateRatePct'),
            absenceRatePct: HrAttendanceJson.rate(row, 'absenceRatePct'),
            profile: HrAttendanceJson.profile(row),
          ),
      ],
    );
  }
}
