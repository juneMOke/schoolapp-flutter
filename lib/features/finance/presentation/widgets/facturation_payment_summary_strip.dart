import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';

class FacturationPaymentSummaryStrip extends StatelessWidget {
  final String amountLabel;
  final String paidAtLabel;
  final String payerLabel;
  final String unknownValue;
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;
  final int amountInCents;
  final String currency;
  final DateTime paidAt;

  const FacturationPaymentSummaryStrip({
    super.key,
    required this.amountLabel,
    required this.paidAtLabel,
    required this.payerLabel,
    required this.unknownValue,
    required this.payerFirstName,
    required this.payerLastName,
    required this.payerMiddleName,
    required this.amountInCents,
    required this.currency,
    required this.paidAt,
  });

  String _formatAmount() {
    return formatMonetaryAmountWithCurrency(
      amount: amountInCents / 100,
      currency: currency,
    );
  }

  String _payerFullName() {
    final middle = payerMiddleName?.trim();
    final values = <String>[
      payerLastName.trim(),
      payerFirstName.trim(),
      if (middle != null && middle.isNotEmpty) middle,
    ];
    final payer = values.where((value) => value.isNotEmpty).join(' ');
    return payer.isEmpty ? unknownValue : payer;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final fullDate = localizations.formatFullDate(paidAt);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 780;
        final dividerWidth = compact ? AppDimensions.spacingS : AppDimensions.spacingM;

        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingS,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
            border: Border.all(
              color: AppColors.borderStrong.withValues(alpha: 0.3),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCell(
                    label: amountLabel,
                    value: _formatAmount(),
                    valueStyle: AppTextStyles.totalAmountLora.copyWith(
                      fontSize: 22,
                      color: AppColors.bleuArdoise,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                VerticalDivider(
                  width: dividerWidth,
                  thickness: 1,
                  color: AppColors.border,
                ),
                Expanded(
                  child: _SummaryCell(
                    label: paidAtLabel,
                    value: fullDate,
                  ),
                ),
                VerticalDivider(
                  width: dividerWidth,
                  thickness: 1,
                  color: AppColors.border,
                ),
                Expanded(
                  child: _SummaryCell(
                    label: payerLabel,
                    value: _payerFullName(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _SummaryCell({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: valueStyle ??
              AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
