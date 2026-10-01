import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_row_view.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La ligne d'un agent telle que la montrent les widgets communs du registre.
extension StaffDayRowPresence on StaffDayRow {
  PresenceRowView presenceView(AppLocalizations l10n) {
    final record = this.record;
    final justification = record?.justification;
    final job = member.jobTitle;
    return PresenceRowView(
      personId: member.id,
      firstName: member.firstName,
      lastName: member.lastName,
      title: StaffAttendanceLabels.familyName(member),
      subtitle: [member.firstName, ?job].join(' · '),
      status: status,
      arrival: record?.arrival,
      departure: record?.departure,
      lateMinutes: record?.lateMinutes ?? 0,
      justificationLabel: justification == null
          ? null
          : StaffAttendanceLabels.reason(l10n, justification.reason),
      sync: sync,
      refusal: record != null && record.syncState == RecordSyncState.failed
          ? StaffAttendanceLabels.refusal(l10n, record)
          : null,
    );
  }
}
