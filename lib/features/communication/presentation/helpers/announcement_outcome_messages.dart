import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_dates.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le toast qui suit un geste abouti, au retour à la liste.
extension AnnouncementOutcomeMessages on AppLocalizations {
  String outcomeMessage(
    AnnouncementEditorOutcome outcome,
    Announcement announcement,
    DateTime now,
  ) {
    final at = announcement.scheduledAt;
    final reach = announcement.reachAtSend;
    return switch (outcome) {
      AnnouncementEditorOutcome.draftSaved => communicationToastDraft,
      AnnouncementEditorOutcome.scheduled when at != null =>
        communicationToastScheduled(AnnouncementDates.moment(this, at, now)),
      AnnouncementEditorOutcome.scheduled => communicationToastScheduledNoDate,
      AnnouncementEditorOutcome.sent when reach != null =>
        communicationToastSent(reach.reachableMessages),
      AnnouncementEditorOutcome.sent => communicationToastSentNoCount,
      AnnouncementEditorOutcome.cancelled => communicationToastCancelled,
    };
  }
}
