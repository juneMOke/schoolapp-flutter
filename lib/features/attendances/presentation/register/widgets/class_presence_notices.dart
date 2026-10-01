import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_notice.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Montre l'annonce d'un geste de l'appel : succès, avertissement (un geste
/// refusé) ou erreur (écriture locale impossible).
void showClassPresenceNotice(BuildContext context, ClassPresenceNotice notice) {
  final l10n = AppLocalizations.of(context)!;
  final name = notice.name ?? '';
  switch (notice.kind) {
    case ClassPresenceNoticeKind.remainingMarked:
      AppSnackBar.showSuccess(
        context,
        l10n.classPresenceToastRemaining(notice.count ?? 0),
      );
    case ClassPresenceNoticeKind.cleared:
      AppSnackBar.showInfo(context, l10n.presenceMarkToastCleared(name));
    case ClassPresenceNoticeKind.justified:
      AppSnackBar.showSuccess(context, l10n.presenceMarkToastJustified(name));
    case ClassPresenceNoticeKind.justificationRemoved:
      AppSnackBar.showInfo(
        context,
        l10n.presenceMarkToastJustificationRemoved(name),
      );
    case ClassPresenceNoticeKind.validated:
      AppSnackBar.showSuccess(context, l10n.classPresenceToastValidated(name));
    case ClassPresenceNoticeKind.reopened:
      AppSnackBar.showInfo(context, l10n.classPresenceToastReopened);
    case ClassPresenceNoticeKind.monthClosed:
      AppSnackBar.showSuccess(
        context,
        l10n.classPresenceToastClosed(
          PresenceLabels.month(
            MaterialLocalizations.of(context),
            notice.month!,
          ),
          name,
        ),
      );
    case ClassPresenceNoticeKind.retried:
      AppSnackBar.showInfo(context, l10n.classPresenceToastRetried);
    case ClassPresenceNoticeKind.dayFrozen:
      AppSnackBar.showWarning(context, l10n.classPresenceToastDayFrozen);
    case ClassPresenceNoticeKind.dayFrozenNoAmend:
      AppSnackBar.showWarning(context, l10n.classPresenceToastDayFrozenNoAmend);
    case ClassPresenceNoticeKind.monthFrozen:
      AppSnackBar.showWarning(context, l10n.classPresenceToastMonthFrozen);
    case ClassPresenceNoticeKind.forbidden:
      AppSnackBar.showWarning(context, l10n.classPresenceToastForbidden);
    case ClassPresenceNoticeKind.unsupportedReason:
      AppSnackBar.showWarning(context, l10n.classPresenceToastUnsupported);
    case ClassPresenceNoticeKind.writeFailed:
      AppSnackBar.showError(context, l10n.presenceMarkToastWriteFailed);
  }
}
