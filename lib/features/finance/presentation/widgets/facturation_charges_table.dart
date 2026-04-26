import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FacturationChargesTable extends StatelessWidget {
  final List<StudentCharge> charges;
  final ValueChanged<StudentCharge> onViewRequested;

  const FacturationChargesTable({
    super.key,
    required this.charges,
    required this.onViewRequested,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.financeDetailCard,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.financeDetailShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.financeDetailChargesAccentSoft,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.sectionCardRadius),
                topRight: Radius.circular(AppDimensions.sectionCardRadius),
              ),
            ),
            child: _HeaderRow(l10n: l10n),
          ),
          const Divider(height: 1, color: AppColors.border),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: charges.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, index) => _ChargeRow(
              charge: charges[index],
              onViewRequested: onViewRequested,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final AppLocalizations l10n;

  const _HeaderRow({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              l10n.facturationDetailChargeLabelColumn,
              style: AppTextStyles.tableHeader.copyWith(
                color: AppColors.financeDetailChargesAccent,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              l10n.facturationDetailChargeExpectedAmountColumn,
              style: AppTextStyles.tableHeader.copyWith(
                color: AppColors.financeDetailChargesAccent,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              l10n.facturationDetailChargePaidAmountColumn,
              style: AppTextStyles.tableHeader.copyWith(
                color: AppColors.financeDetailChargesAccent,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              l10n.facturationDetailChargeRemainingAmountColumn,
              style: AppTextStyles.tableHeader.copyWith(
                color: AppColors.financeDetailChargesAccent,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.facturationDetailChargeStatusColumn,
                style: AppTextStyles.tableHeader.copyWith(
                  color: AppColors.financeDetailChargesAccent,
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                l10n.facturationDetailPaymentActionsColumn,
                style: AppTextStyles.tableHeader.copyWith(
                  color: AppColors.financeDetailChargesAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChargeRow extends StatelessWidget {
  final StudentCharge charge;
  final ValueChanged<StudentCharge> onViewRequested;

  const _ChargeRow({required this.charge, required this.onViewRequested});

  String _formatAmount(double value, String currency) {
    return '${value.toStringAsFixed(2)} $currency';
  }

  Color _resolveRowColor(StudentCharge charge) => switch (charge.status) {
    StudentChargeStatus.paid => AppColors.financeDetailChargeRowPaid,
    StudentChargeStatus.partial => AppColors.financeDetailChargeRowPartial,
    StudentChargeStatus.due => AppColors.financeDetailChargeRowDue,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remaining = charge.expectedAmountInCents - charge.amountPaidInCents;

    return Container(
      color: _resolveRowColor(charge),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              charge.label,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatAmount(charge.expectedAmountInCents, charge.currency),
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatAmount(charge.amountPaidInCents, charge.currency),
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatAmount(remaining, charge.currency),
              style: AppTextStyles.bodyStrong.copyWith(color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                  vertical: AppDimensions.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: charge.status.badgeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppDimensions.spacingXL),
                ),
                child: Text(
                  charge.status.localizedLabel(l10n),
                  style: AppTextStyles.badge.copyWith(
                    color: charge.status.badgeColor,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => onViewRequested(charge),
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: AppColors.financeDetailChargesAccent,
                ),
                tooltip: l10n.facturationDetailViewPaymentLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}