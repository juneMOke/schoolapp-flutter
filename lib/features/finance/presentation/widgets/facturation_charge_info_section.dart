import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_context_chip.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FacturationChargeInfoSection extends StatelessWidget {
  final String chargeLabel;
  final double expectedAmountInCents;
  final double amountPaidInCents;
  final String currency;
  final StudentChargeStatus chargeStatus;

  const FacturationChargeInfoSection({
    super.key,
    required this.chargeLabel,
    required this.expectedAmountInCents,
    required this.amountPaidInCents,
    required this.currency,
    required this.chargeStatus,
  });

  double get _remainingInCents => expectedAmountInCents - amountPaidInCents;

  String _formatAmount(double cents, String currencyCode) {
    final major = (cents / 100).toStringAsFixed(2);
    final parts = major.split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ' ',
    );
    return '$whole.${parts.last} $currencyCode';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.detailCardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.financeDetailChargeInfoSurface,
            AppColors.financeDetailChargeInfoSurfaceAlt,
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(
          color: AppColors.financeDetailChargeInfoAccent.withValues(alpha: 0.18),
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
          _SectionHeader(
            title: l10n.facturationChargeDetailInfoSectionTitle,
            chargeLabel: chargeLabel,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Wrap(
            spacing: AppDimensions.spacingS,
            runSpacing: AppDimensions.spacingS,
            children: [
              FinanceContextChip(
                label: currency.isEmpty ? '-' : currency,
                icon: Icons.attach_money_outlined,
                accent: AppColors.financeDetailChargeInfoAccent,
                accentSoft: AppColors.financeDetailChargeInfoAccentSoft,
              ),
              FinanceContextChip(
                label: chargeStatus.localizedLabel(l10n),
                icon: _statusIcon(chargeStatus),
                accent: chargeStatus.badgeColor,
                accentSoft: chargeStatus.badgeColor.withValues(alpha: 0.12),
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
                  _AmountTile(
                    width: tileWidth,
                    label: l10n.facturationChargeDetailExpectedAmountLabel,
                    value: _formatAmount(expectedAmountInCents, currency),
                  ),
                  _AmountTile(
                    width: tileWidth,
                    label: l10n.facturationChargeDetailPaidAmountLabel,
                    value: _formatAmount(amountPaidInCents, currency),
                    emphasize: true,
                  ),
                  _AmountTile(
                    width: tileWidth,
                    label: l10n.facturationChargeDetailRemainingAmountLabel,
                    value: _formatAmount(_remainingInCents, currency),
                    accentColor: _remainingInCents > 0
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(StudentChargeStatus status) => switch (status) {
    StudentChargeStatus.paid => Icons.check_circle_outline,
    StudentChargeStatus.partial => Icons.timelapse_outlined,
    StudentChargeStatus.due => Icons.radio_button_unchecked,
  };
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String chargeLabel;

  const _SectionHeader({required this.title, required this.chargeLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppDimensions.spacingL,
          height: AppDimensions.spacingL,
          decoration: BoxDecoration(
            color: AppColors.financeDetailChargeInfoAccentSoft,
            borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          ),
          child: const Icon(
            Icons.receipt_long_outlined,
            size: AppDimensions.detailMiniIconSize,
            color: AppColors.financeDetailChargeInfoAccent,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.financeDetailChargeInfoAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (chargeLabel.trim().isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  chargeLabel,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AmountTile extends StatelessWidget {
  final String label;
  final String value;
  final double width;
  final bool emphasize;
  final Color? accentColor;

  const _AmountTile({
    required this.label,
    required this.value,
    required this.width,
    this.emphasize = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedAccent = accentColor ?? AppColors.financeDetailChargeInfoAccent;
    final resolvedSurface = emphasize
        ? AppColors.financeDetailChargeInfoAccentSoft
        : AppColors.surface;
    final resolvedBorder = emphasize
        ? AppColors.financeDetailChargeInfoAccent.withValues(alpha: 0.22)
        : AppColors.border;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: resolvedSurface,
          borderRadius: BorderRadius.circular(AppDimensions.spacingM),
          border: Border.all(color: resolvedBorder),
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
                color: accentColor != null ? resolvedAccent : AppColors.textPrimary,
                fontSize: emphasize ? 16 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
