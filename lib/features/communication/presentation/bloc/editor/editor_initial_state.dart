import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_validation.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/audience_selections.dart';

/// L'état d'ouverture de l'éditeur : un programmé garde son heure et son mode,
/// le reste part « maintenant », avec une programmation proposée au lendemain.
AnnouncementEditorState initialEditorState({
  required String id,
  required AnnouncementContent content,
  required DateTime now,
  Announcement? announcement,
  bool readOnly = false,
}) {
  final scheduled = announcement?.status == AnnouncementStatus.scheduled
      ? announcement?.scheduledAt
      : null;
  return AnnouncementEditorState(
    id: id,
    announcement: announcement,
    content: content,
    selections: AudienceSelections.of(content.audience),
    sendMode: scheduled == null
        ? AnnouncementSendMode.now
        : AnnouncementSendMode.scheduled,
    scheduledAt: scheduled ?? defaultScheduleFor(now),
    issues: AnnouncementValidation.issuesOf(content),
    readOnly: readOnly,
  );
}

/// Le lendemain, 07:30 à l'heure de l'école.
DateTime defaultScheduleFor(DateTime now) {
  final today = SchoolTime.today(now);
  // Le jour suivant par le calendrier, pas « + 24 h » : une tablette réglée
  // sur un fuseau à heure d'été retomberait sinon le même jour.
  return SchoolTime.instantAt(
    day: DateTime(today.year, today.month, today.day + 1),
    hour: 7,
    minute: 30,
  );
}
