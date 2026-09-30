import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_notice.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Montre l'annonce d'un geste de la paie : succès, règle refusée ou écriture
/// impossible.
void showPayrollNotice(
  BuildContext context,
  PayrollNotice notice, {
  required String monthLabel,
}) {
  final l10n = AppLocalizations.of(context)!;
  final name = notice.name ?? '';
  final amount = notice.amount ?? '';
  switch (notice.kind) {
    case PayrollNoticeKind.variablesSaved:
      AppSnackBar.showSuccess(context, l10n.payrollToastVariables(name));
    case PayrollNoticeKind.submitted:
      AppSnackBar.showSuccess(context, l10n.payrollToastSubmitted);
    case PayrollNoticeKind.validated:
      AppSnackBar.showSuccess(context, l10n.payrollToastValidated);
    case PayrollNoticeKind.returned:
      AppSnackBar.showInfo(context, l10n.payrollToastReturned);
    case PayrollNoticeKind.reopened:
      AppSnackBar.showInfo(context, l10n.payrollToastReopened);
    case PayrollNoticeKind.paid:
      AppSnackBar.showSuccess(context, l10n.payrollToastPaid(amount, name));
    case PayrollNoticeKind.payCancelled:
      AppSnackBar.showInfo(context, l10n.payrollToastPayCancelled);
    case PayrollNoticeKind.advanceGranted:
      AppSnackBar.showSuccess(context, l10n.payrollToastAdvance(amount, name));
    case PayrollNoticeKind.advanceCancelled:
      AppSnackBar.showInfo(context, l10n.payrollToastAdvanceCancelled);
    case PayrollNoticeKind.profileSaved:
      AppSnackBar.showSuccess(context, l10n.payrollToastProfile);
    case PayrollNoticeKind.settingsSaved:
      AppSnackBar.showSuccess(context, l10n.payrollToastSettings);
    case PayrollNoticeKind.shared:
      AppSnackBar.showInfo(context, l10n.payrollToastShared);
    case PayrollNoticeKind.downloaded:
      AppSnackBar.showSuccess(context, l10n.payrollToastDownloaded);
    case PayrollNoticeKind.offline:
      AppSnackBar.showWarning(context, l10n.payrollToastOffline);
    case PayrollNoticeKind.downloadFailed:
      AppSnackBar.showError(context, l10n.payrollToastDownloadFailed);
    case PayrollNoticeKind.refused:
      final rule = notice.rule;
      if (rule != null) {
        AppSnackBar.showWarning(
          context,
          PayrollLabels.rule(l10n, rule, month: monthLabel),
        );
      }
    case PayrollNoticeKind.writeFailed:
      AppSnackBar.showError(context, l10n.payrollToastWriteFailed);
  }
}
