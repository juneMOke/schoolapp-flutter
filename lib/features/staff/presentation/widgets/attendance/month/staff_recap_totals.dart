import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_totals_band.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_recap.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau des totaux du récapitulatif : ce que la clôture transmettra.
class StaffRecapTotals extends StatelessWidget {
  final StaffMonthRecap recap;

  const StaffRecapTotals({super.key, required this.recap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rate = recap.presenceRate;
    final hours = [
      PresenceLabels.hours(l10n, recap.workedMinutes),
      for (final entry in recap.amountByCurrency.entries)
        MoneyFormat.format(Money(entry.value, entry.key)),
    ].join(' · ');
    final totals = <(String, String)>[
      (
        l10n.presenceMarkTotalRate,
        rate == null ? '—' : '${(rate * 100).round()} %',
      ),
      (l10n.staffAttendanceTotalHours, hours),
      (
        l10n.presenceMarkTotalLateMinutes,
        l10n.presenceMarkMinutes(recap.lateMinutes),
      ),
      (l10n.presenceMarkTotalUnjustified, '${recap.absentUnjustified}'),
      (l10n.presenceMarkTotalNotMarked, '${recap.notMarked}'),
      if (recap.pending > 0) (l10n.recordSyncPending, '${recap.pending}'),
    ];
    return PresenceTotalsBand(totals: totals);
  }
}
