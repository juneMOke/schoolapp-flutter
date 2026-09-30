import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_period.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_contract_tone.dart';
import 'package:school_app_flutter/core/formatters/local_date_time_format.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_contract_badge.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_sync_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une période de la frise : statut, dates, et — pour qui les voit — ce
/// qu'elle paie.
class StaffContractPeriodTile extends StatelessWidget {
  final StaffContractPeriod period;
  final StaffContract? detail;
  final bool isCurrent;
  final ValueChanged<StaffContract>? onCorrect;

  const StaffContractPeriodTile({
    super.key,
    required this.period,
    required this.detail,
    required this.isCurrent,
    this.onCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = StaffContractTone.of(period.kind);
    final detail = this.detail;
    final correct = onCorrect;
    final lines = detail == null ? const <String>[] : _payLines(l10n, detail);
    final canCorrect =
        correct != null &&
        detail != null &&
        detail.syncState == StaffSyncState.synced &&
        !detail.isCorrected;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isCurrent ? tone.soft : AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: isCurrent ? tone.outline : AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StaffContractBadge(kind: period.kind),
                    if (period.isHourlyVacataire)
                      Text(
                        l10n.staffPayModeHourly,
                        style: AppTypography.labelSmall,
                      ),
                    if (isCurrent)
                      Text(
                        l10n.staffContractCurrent,
                        style: AppTypography.labelSmall.copyWith(
                          color: tone.ink,
                        ),
                      ),
                    if (detail != null &&
                        detail.syncState != StaffSyncState.synced)
                      StaffSyncPill(state: detail.syncState),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  period.endsOn == null
                      ? l10n.staffContractFrom(
                          formatIsoDay(period.effectiveFrom),
                        )
                      : l10n.staffContractBetween(
                          formatIsoDay(period.effectiveFrom),
                          formatIsoDay(period.endsOn!),
                        ),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                for (final line in lines)
                  Text(line, style: AppTypography.bodyMedium),
                if (detail?.syncError case final error?)
                  Text(
                    l10n.staffContractRejected(error),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ),
          if (canCorrect)
            TextButton(
              onPressed: () => correct(detail),
              child: Text(l10n.staffContractCorrect),
            ),
        ],
      ),
    );
  }

  static List<String> _payLines(AppLocalizations l10n, StaffContract c) => [
    if (c.amount case final amount?)
      switch ((c.kind, c.payMode)) {
        (StaffContractKind.vacataire, StaffPayMode.hourly) =>
          l10n.staffPayHourlyRate(MoneyFormat.format(amount)),
        (StaffContractKind.vacataire, _) => l10n.staffPayMonthlyFlat(
          MoneyFormat.format(amount),
        ),
        _ => l10n.staffPaySalary(MoneyFormat.format(amount)),
      },
    if (c.secopeNumber case final secope?) l10n.staffPaySecope(secope),
    if (c.bonus case final bonus?)
      l10n.staffPayBonus(MoneyFormat.format(bonus)),
  ];
}
