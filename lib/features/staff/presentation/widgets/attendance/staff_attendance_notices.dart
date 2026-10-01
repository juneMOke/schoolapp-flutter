import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_notice.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Montre l'annonce d'un geste du Pointage : succès, avertissement (un geste
/// refusé sur un jour figé) ou erreur (écriture locale impossible).
void showStaffAttendanceNotice(
  BuildContext context,
  StaffAttendanceNotice notice,
) {
  final l10n = AppLocalizations.of(context)!;
  final name = notice.name ?? '';
  final monthLabel = notice.month == null
      ? ''
      : PresenceLabels.month(MaterialLocalizations.of(context), notice.month!);
  switch (notice.kind) {
    case StaffAttendanceNoticeKind.dayFrozen:
      AppSnackBar.showWarning(context, l10n.staffAttendanceToastDayFrozen);
    case StaffAttendanceNoticeKind.monthFrozen:
      AppSnackBar.showWarning(context, l10n.staffAttendanceToastMonthFrozen);
    case StaffAttendanceNoticeKind.forbidden:
      AppSnackBar.showWarning(context, l10n.staffAttendanceForbidden);
    case StaffAttendanceNoticeKind.writeFailed:
      AppSnackBar.showError(context, l10n.presenceMarkToastWriteFailed);
    case StaffAttendanceNoticeKind.remainingMarked:
      AppSnackBar.showSuccess(
        context,
        l10n.staffAttendanceToastRemaining(notice.count ?? 0),
      );
    case StaffAttendanceNoticeKind.cleared:
      AppSnackBar.showInfo(context, l10n.presenceMarkToastCleared(name));
    case StaffAttendanceNoticeKind.justified:
      AppSnackBar.showSuccess(context, l10n.presenceMarkToastJustified(name));
    case StaffAttendanceNoticeKind.justificationRemoved:
      AppSnackBar.showInfo(
        context,
        l10n.presenceMarkToastJustificationRemoved(name),
      );
    case StaffAttendanceNoticeKind.settingsSaved:
      AppSnackBar.showSuccess(context, l10n.staffAttendanceToastSettings);
    case StaffAttendanceNoticeKind.reportValidated:
      AppSnackBar.showSuccess(context, l10n.staffAttendanceToastValidated);
    case StaffAttendanceNoticeKind.reportReopened:
      AppSnackBar.showInfo(context, l10n.staffAttendanceToastReopened);
    case StaffAttendanceNoticeKind.monthClosed:
      AppSnackBar.showSuccess(
        context,
        l10n.staffAttendanceToastClosed(monthLabel),
      );
  }
}
