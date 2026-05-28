import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FacturationCreatePaymentChargeImpactTable extends StatelessWidget {
  final double expectedAmountInCents;
  final double beforePaidInCents;
  final double afterPaidInCents;
  final String currency;
  final StudentChargeStatus beforeStatus;
  final StudentChargeStatus afterStatus;

  const FacturationCreatePaymentChargeImpactTable({
    super.key,
    required this.expectedAmountInCents,
    required this.beforePaidInCents,
    required this.afterPaidInCents,
    required this.currency,
    required this.beforeStatus,
    required this.afterStatus,
  });

  String _formatAmount(double cents) =>
      formatMonetaryAmountWithCurrency(amount: cents / 100, currency: currency);

  StatusBadge _statusBadge(StudentChargeStatus status, AppLocalizations l10n) =>
      switch (status) {
        StudentChargeStatus.due => StatusBadge(
          label: status.localizedLabel(l10n),
          color: status.badgeColor,
          icon: Icons.radio_button_unchecked,
          size: StatusBadgeSize.small,
        ),
        StudentChargeStatus.partial => StatusBadge.partial(
          label: status.localizedLabel(l10n),
          size: StatusBadgeSize.small,
        ),
        StudentChargeStatus.paid => StatusBadge.paid(
          label: status.localizedLabel(l10n),
          size: StatusBadgeSize.small,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final beforeRemaining = (expectedAmountInCents - beforePaidInCents)
        .clamp(0, double.infinity)
        .toDouble();
    final afterRemaining = (expectedAmountInCents - afterPaidInCents)
        .clamp(0, double.infinity)
        .toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.papier,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.facturationCreatePaymentChargeImpactTitle,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : AppDimensions.detailTableMinWidth;
                return SizedBox(
                  width: width > AppDimensions.detailTableMinWidth
                      ? width
                      : AppDimensions.detailTableMinWidth,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: AppDimensions.detailTableLabelColumnWidth,
                          ),
                          Expanded(
                            child: Text(
                              l10n.facturationCreatePaymentExpectedLabel,
                              style: AppTextStyles.tableHeader.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              l10n.facturationCreatePaymentPaidLabel,
                              style: AppTextStyles.tableHeader.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              l10n.facturationCreatePaymentRemainingLabel,
                              style: AppTextStyles.tableHeader.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              l10n.facturationCreatePaymentStatusLabel,
                              style: AppTextStyles.tableHeader.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      _ImpactRow(
                        label: l10n.facturationCreatePaymentBeforeLabel,
                        expected: _formatAmount(expectedAmountInCents),
                        paid: _formatAmount(beforePaidInCents),
                        remaining: _formatAmount(beforeRemaining),
                        status: _statusBadge(beforeStatus, l10n),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      _ImpactRow(
                        label: l10n.facturationCreatePaymentAfterLabel,
                        expected: _formatAmount(expectedAmountInCents),
                        paid: _formatAmount(afterPaidInCents),
                        remaining: _formatAmount(afterRemaining),
                        status: _statusBadge(afterStatus, l10n),
                        highlightPaid: true,
                        highlightRemaining: true,
                        highlightStatus: true,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  final String label;
  final String expected;
  final String paid;
  final String remaining;
  final StatusBadge status;
  final bool highlightPaid;
  final bool highlightRemaining;
  final bool highlightStatus;

  const _ImpactRow({
    required this.label,
    required this.expected,
    required this.paid,
    required this.remaining,
    required this.status,
    this.highlightPaid = false,
    this.highlightRemaining = false,
    this.highlightStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: AppDimensions.detailTableLabelColumnWidth,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            expected,
            style: AppTextStyles.moneyTabular.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            paid,
            style: AppTextStyles.moneyTabular.copyWith(
              color: highlightPaid
                  ? AppColors.bleuArdoise
                  : AppColors.textPrimary,
              fontWeight: highlightPaid ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            remaining,
            style: AppTextStyles.moneyTabular.copyWith(
              color: highlightRemaining
                  ? AppColors.bleuArdoise
                  : AppColors.textPrimary,
              fontWeight: highlightRemaining
                  ? FontWeight.w700
                  : FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: highlightStatus
                  ? AppColors.bleuArdoise.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimensions.spacingXS),
            ),
            child: Align(alignment: Alignment.centerLeft, child: status),
          ),
        ),
      ],
    );
  }
}
