import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_close_dialog.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_recap.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Confirmer la clôture d'un mois du Pointage : ce qui part vers la Paie.
/// Rend `true` pour clôturer.
class StaffMonthCloseDialog extends StatelessWidget {
  final StaffMonthRecap recap;
  final String monthLabel;

  const StaffMonthCloseDialog({
    super.key,
    required this.recap,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hours = [
      PresenceLabels.hours(l10n, recap.workedMinutes),
      for (final entry in recap.amountByCurrency.entries)
        MoneyFormat.format(Money(entry.value, entry.key)),
    ].join(' · ');
    return PresenceMonthCloseDialog(
      title: l10n.staffAttendanceCloseTitle(monthLabel),
      confirmLabel: l10n.staffAttendanceCloseConfirm,
      consequences: [
        (text: l10n.staffAttendanceCloseHours(hours), icon: Icons.schedule),
        (
          text: l10n.staffAttendanceCloseAbsences(recap.absentUnjustified),
          icon: Icons.cancel_outlined,
        ),
        (
          text: l10n.staffAttendanceCloseLates(recap.lateMinutes),
          icon: Icons.timer_outlined,
        ),
      ],
      notMarkedWarning: recap.notMarked > 0
          ? l10n.staffAttendanceCloseNotMarked(recap.notMarked)
          : null,
    );
  }
}
