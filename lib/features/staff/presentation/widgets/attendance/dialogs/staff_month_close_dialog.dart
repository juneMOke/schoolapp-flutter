import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_recap.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/common/staff_attendance_dialog.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/common/staff_attendance_warning.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Confirmer la clôture d'un mois : ce qui part vers la Paie, et ce que la
/// clôture fige. Rend `true` pour clôturer.
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
    final amounts = [
      for (final entry in recap.amountByCurrency.entries)
        MoneyFormat.format(Money(entry.value, entry.key)),
    ];
    final hours = [
      StaffAttendanceLabels.hours(l10n, recap.workedMinutes),
      ...amounts,
    ].join(' · ');
    Widget line(String text, IconData icon) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: StaffAttendanceWarning(
        message: text,
        icon: icon,
        tone: StaffAttendanceStatus.none,
      ),
    );
    return StaffAttendanceDialog(
      title: l10n.staffAttendanceCloseTitle(monthLabel),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          line(l10n.staffAttendanceCloseHours(hours), Icons.schedule),
          line(
            l10n.staffAttendanceCloseAbsences(recap.absentUnjustified),
            Icons.cancel_outlined,
          ),
          line(
            l10n.staffAttendanceCloseLates(recap.lateMinutes),
            Icons.timer_outlined,
          ),
          if (recap.notMarked > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: StaffAttendanceWarning(
                icon: Icons.back_hand_outlined,
                message: l10n.staffAttendanceCloseNotMarked(recap.notMarked),
              ),
            ),
          StaffAttendanceWarning(
            icon: Icons.lock_outline,
            tone: StaffAttendanceStatus.absent,
            message: l10n.staffAttendanceCloseIrreversible,
          ),
        ],
      ),
      actions: [
        EteeloButton.ghost(
          label: l10n.staffAttendanceCancel,
          onPressed: () => Navigator.of(context).pop(false),
          fullWidth: false,
        ),
        EteeloButton.primary(
          label: l10n.staffAttendanceCloseConfirm,
          icon: Icons.lock,
          onPressed: () => Navigator.of(context).pop(true),
          fullWidth: false,
        ),
      ],
    );
  }
}
