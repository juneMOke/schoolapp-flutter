import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_recap.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
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
      StaffAttendanceLabels.hours(l10n, recap.workedMinutes),
      for (final entry in recap.amountByCurrency.entries)
        MoneyFormat.format(Money(entry.value, entry.key)),
    ].join(' · ');
    final totals = <(String, String)>[
      (
        l10n.staffAttendanceTotalRate,
        rate == null ? '—' : '${(rate * 100).round()} %',
      ),
      (l10n.staffAttendanceTotalHours, hours),
      (
        l10n.staffAttendanceTotalLateMinutes,
        l10n.staffAttendanceMinutes(recap.lateMinutes),
      ),
      (l10n.staffAttendanceTotalUnjustified, '${recap.absentUnjustified}'),
      (l10n.staffAttendanceTotalNotMarked, '${recap.notMarked}'),
      if (recap.pending > 0) (l10n.staffSyncPending, '${recap.pending}'),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.bleuArdoiseSoft,
        borderRadius: AppRadius.brLg,
      ),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.md,
        children: [
          for (final (label, value) in totals)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMutedAa,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.bleuArdoise,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
