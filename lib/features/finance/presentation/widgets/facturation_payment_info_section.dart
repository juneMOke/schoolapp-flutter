import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_context_chip.dart';

class FacturationPaymentInfoSection extends StatelessWidget {
  final String title;
  final String payerLabel;
  final String amountLabel;
  final String paidAtLabel;
  final String unknownValue;
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;
  final int amountInCents;
  final String currency;
  final DateTime paidAt;

  const FacturationPaymentInfoSection({
    super.key,
    required this.title,
    required this.payerLabel,
    required this.amountLabel,
    required this.paidAtLabel,
    required this.unknownValue,
    required this.payerFirstName,
    required this.payerLastName,
    required this.payerMiddleName,
    required this.amountInCents,
    required this.currency,
    required this.paidAt,
  });

  String _formatAmount(int cents, String currencyCode) {
    final major = (cents / 100).toStringAsFixed(2);
    final parts = major.split('.');
    final wholePart = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ' ',
    );
    return '$wholePart.${parts.last} $currencyCode';
  }

  String _payerFullName() {
    final middle = payerMiddleName?.trim();
    final values = <String>[
      payerLastName,
      payerFirstName,
      if (middle != null && middle.isNotEmpty) middle,
    ];
    return values.where((value) => value.trim().isNotEmpty).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final payer = _payerFullName();
    final isUnknownPayer = payer.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.detailCardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.financeDetailPaymentsSurface,
            AppColors.financeDetailPaymentsSurfaceAlt,
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(
          color: AppColors.financeDetailPaymentsAccent.withValues(alpha: 0.18),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.financeDetailShadow,
            blurRadius: AppDimensions.financeDetailCardShadowBlur,
            offset: Offset(0, AppDimensions.financeDetailCardShadowOffsetY),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppDimensions.spacingL,
                height: AppDimensions.spacingL,
                decoration: BoxDecoration(
                  color: AppColors.financeDetailPaymentsAccentSoft,
                  borderRadius: BorderRadius.circular(AppDimensions.spacingS),
                ),
                child: const Icon(
                  Icons.info_outline,
                  size: AppDimensions.detailMiniIconSize,
                  color: AppColors.financeDetailPaymentsAccent,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: AppColors.financeDetailPaymentsAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Wrap(
            spacing: AppDimensions.spacingS,
            runSpacing: AppDimensions.spacingS,
            children: [
              FinanceContextChip(
                label: currency.isEmpty ? unknownValue : currency,
                icon: Icons.attach_money_outlined,
                accent: AppColors.financeDetailPaymentsAccent,
                accentSoft: AppColors.financeDetailPaymentsAccentSoft,
              ),
              FinanceContextChip(
                label: localizations.formatShortDate(paidAt),
                icon: Icons.event_outlined,
                accent: AppColors.financeDetailTeal,
                accentSoft: AppColors.financeDetailTealSoft,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < AppDimensions.detailCompactBreakpoint;
              final tileWidth = compact
                  ? constraints.maxWidth
                  : AppDimensions.detailInfoItemWidth;

              return Wrap(
                spacing: AppDimensions.spacingM,
                runSpacing: AppDimensions.spacingM,
                children: [
                  _InfoTile(
                    width: tileWidth,
                    label: payerLabel,
                    value: isUnknownPayer ? unknownValue : payer,
                    isUnknown: isUnknownPayer,
                  ),
                  _InfoTile(
                    width: tileWidth,
                    label: amountLabel,
                    value: _formatAmount(amountInCents, currency),
                    emphasizeValue: true,
                  ),
                  _InfoTile(
                    width: tileWidth,
                    label: paidAtLabel,
                    value: localizations.formatFullDate(paidAt),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final double width;
  final bool emphasizeValue;
  final bool isUnknown;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.width,
    this.emphasizeValue = false,
    this.isUnknown = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: emphasizeValue
              ? AppColors.financeDetailPaymentsAccentSoft
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.spacingM),
          border: Border.all(
            color: emphasizeValue
                ? AppColors.financeDetailPaymentsAccent.withValues(alpha: 0.22)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.tableHeader.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              value,
              style: AppTextStyles.bodyStrong.copyWith(
                color: isUnknown
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontSize: emphasizeValue ? 16 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}