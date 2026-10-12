import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_dates.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que l'éditeur doit dire avant les sections : un programmé modifiable
/// jusqu'à l'heure, un échec du planificateur, une relecture serveur.
class EditorStatusBanner extends StatelessWidget {
  final AnnouncementEditorState state;
  final DateTime now;

  const EditorStatusBanner({super.key, required this.state, required this.now});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notice = switch (state.notice) {
      AnnouncementEditorNotice.notEditable => EteeloNotice.warning(
        l10n.communicationNoticeLocked,
      ),
      AnnouncementEditorNotice.reloaded => EteeloNotice.warning(
        l10n.communicationNoticeReloaded,
      ),
      null => null,
    };
    if (notice != null) return notice;
    final announcement = state.announcement;
    final at = announcement?.scheduledAt;
    return switch (announcement?.status) {
      AnnouncementStatus.scheduled when at != null => EteeloNotice.tinted(
        message: l10n.communicationScheduledBanner(
          AnnouncementDates.moment(l10n, at, now),
        ),
        icon: Icons.schedule_send_outlined,
        ink: AppColors.bleuArdoise,
        background: AppColors.bleuArdoiseSoft,
      ),
      AnnouncementStatus.failed => EteeloNotice.error(
        l10n.communicationFailedBanner(
          announcement?.lastSendError ?? l10n.communicationFailedNoReason,
        ),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
