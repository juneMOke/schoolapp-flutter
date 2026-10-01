import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_recap.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_warning.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

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
      PresenceLabels.hours(l10n, recap.workedMinutes),
      ...amounts,
    ].join(' · ');
    Widget line(String text, IconData icon) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: PresenceWarning(
        message: text,
        icon: icon,
        tone: PresenceStatus.none,
      ),
    );
    return EteeloFormDialog(
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
              child: PresenceWarning(
                icon: Icons.back_hand_outlined,
                message: l10n.staffAttendanceCloseNotMarked(recap.notMarked),
              ),
            ),
          PresenceWarning(
            icon: Icons.lock_outline,
            tone: PresenceStatus.absent,
            message: l10n.presenceMarkCloseIrreversible,
          ),
        ],
      ),
      actions: [
        EteeloButton.ghost(
          label: l10n.presenceMarkCancel,
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
