import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_close_dialog.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Confirmer la clôture du mois, sur les totaux du serveur. Rend `true` pour
/// clôturer.
class HrPresenceCloseDialog extends StatelessWidget {
  final HrAttendanceRecap recap;
  final String monthLabel;

  const HrPresenceCloseDialog({
    super.key,
    required this.recap,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totals = recap.totals;
    final lateMinutes = recap.staff.fold<int>(
      0,
      (sum, row) => sum + row.lateMinutes,
    );
    final hours = [
      PresenceLabels.hours(l10n, totals.workedMinutes),
      for (final amount in totals.amounts ?? const [])
        MoneyFormat.format(amount),
    ].join(' · ');
    return PresenceMonthCloseDialog(
      title: l10n.staffAttendanceCloseTitle(monthLabel),
      confirmLabel: l10n.staffAttendanceCloseConfirm,
      irreversibleMessage: l10n.staffAttendanceCloseIrreversible,
      consequences: [
        (text: l10n.staffAttendanceCloseHours(hours), icon: Icons.schedule),
        (
          text: l10n.staffAttendanceCloseAbsences(totals.unjustifiedAbsences),
          icon: Icons.cancel_outlined,
        ),
        (
          text: l10n.staffAttendanceCloseLates(lateMinutes),
          icon: Icons.timer_outlined,
        ),
      ],
      notMarkedWarning: recap.unscored > 0
          ? l10n.staffAttendanceCloseNotMarked(recap.unscored)
          : null,
    );
  }
}
