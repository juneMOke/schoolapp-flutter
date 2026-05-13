import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_fee_code_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FacturationChargesTable extends StatelessWidget {
  static const double _footerHeight = 72;

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
    final totalExpected = charges.fold<double>(
      0,
      (sum, charge) => sum + charge.expectedAmountInCents,
    );
    final totalPaid = charges.fold<double>(
      0,
      (sum, charge) => sum + charge.amountPaidInCents,
    );
    final totalRemaining = totalExpected - totalPaid;
    final currency = charges.isNotEmpty ? charges.first.currency : '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < AppDimensions.detailCompactBreakpoint;
        final viewportWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : AppDimensions.detailTableMinWidth;
        final tableWidth = viewportWidth > AppDimensions.detailTableMinWidth
            ? viewportWidth
            : AppDimensions.detailTableMinWidth;

        return Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.border),
              bottom: BorderSide(color: AppColors.border),
              left: BorderSide(color: AppColors.border),
              right: BorderSide(color: AppColors.border),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingM,
                      vertical: AppDimensions.spacingS,
                    ),
                    child: _HeaderRow(l10n: l10n),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  if (compact || charges.length <= 4)
                    Column(
                      children: [
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
                        _TotalsFooter(
                          l10n: l10n,
                          expected: totalExpected,
                          paid: totalPaid,
                          remaining: totalRemaining,
                          currency: currency,
                          compact: true,
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      height: 360,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: _footerHeight,
                              ),
                              child: ListView.separated(
                                itemCount: charges.length,
                                separatorBuilder: (_, _) => const Divider(
                                  height: 1,
                                  color: AppColors.border,
                                ),
                                itemBuilder: (context, index) => _ChargeRow(
                                  charge: charges[index],
                                  onViewRequested: onViewRequested,
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: _TotalsFooter(
                              l10n: l10n,
                              expected: totalExpected,
                              paid: totalPaid,
                              remaining: totalRemaining,
                              currency: currency,
                              compact: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
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
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.facturationDetailChargeLabelColumn,
                style: AppTextStyles.tableHeader.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.facturationDetailChargeExpectedAmountColumn,
                style: AppTextStyles.tableHeader.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.facturationDetailChargePaidAmountColumn,
                style: AppTextStyles.tableHeader.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.facturationDetailChargeRemainingAmountColumn,
                style: AppTextStyles.tableHeader.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
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
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.facturationDetailPaymentActionsColumn,
                style: AppTextStyles.tableHeader.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
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
    return formatMonetaryAmountWithCurrency(
      amount: value / 100,
      currency: currency,
    );
  }

  StatusBadge _buildStatusBadge(AppLocalizations l10n) =>
      switch (charge.status) {
        StudentChargeStatus.due => StatusBadge(
          label: charge.status.localizedLabel(l10n),
          color: charge.status.badgeColor,
          icon: Icons.radio_button_unchecked,
          size: StatusBadgeSize.small,
        ),
        StudentChargeStatus.partial => StatusBadge.partial(
          label: charge.status.localizedLabel(l10n),
          size: StatusBadgeSize.small,
        ),
        StudentChargeStatus.paid => StatusBadge.paid(
          label: charge.status.localizedLabel(l10n),
          size: StatusBadgeSize.small,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remaining = charge.expectedAmountInCents - charge.amountPaidInCents;
    final localizedLabel = charge.feeCode.localizedFeeLabel(l10n);

    return Material(
      color: AppColors.surfaceRaised,
      child: InkWell(
        onTap: () => onViewRequested(charge),
        hoverColor: AppColors.bleuArdoise.withValues(alpha: 0.08),
        splashColor: AppColors.bleuArdoise.withValues(alpha: 0.12),
        highlightColor: AppColors.bleuArdoise.withValues(alpha: 0.16),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    localizedLabel,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatAmount(
                      charge.expectedAmountInCents,
                      charge.currency,
                    ),
                    style: AppTextStyles.moneyTabular.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatAmount(charge.amountPaidInCents, charge.currency),
                    style: AppTextStyles.moneyTabular.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatAmount(remaining, charge.currency),
                    style: AppTextStyles.moneyTabular.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildStatusBadge(l10n),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => onViewRequested(charge),
                    tooltip: l10n.facturationDetailViewChargeLabel,
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.bleuArdoise,
                      backgroundColor: AppColors.bleuArdoise.withValues(alpha: 0.08),
                      hoverColor: AppColors.bleuArdoise.withValues(alpha: 0.08),
                      focusColor: AppColors.bleuArdoise.withValues(alpha: 0.12),
                      highlightColor: AppColors.bleuArdoise.withValues(alpha: 0.16),
                      minimumSize: const Size(
                        AppDimensions.minTouchTarget,
                        AppDimensions.minTouchTarget,
                      ),
                    ),
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: AppDimensions.detailHeaderIconSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalsFooter extends StatelessWidget {
  final AppLocalizations l10n;
  final double expected;
  final double paid;
  final double remaining;
  final String currency;
  final bool compact;

  const _TotalsFooter({
    required this.l10n,
    required this.expected,
    required this.paid,
    required this.remaining,
    required this.currency,
    required this.compact,
  });

  String _formatAmount(double value) =>
      formatMonetaryAmountWithCurrency(amount: value / 100, currency: currency);

  @override
  Widget build(BuildContext context) {
    final footer = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingM,
      ),
      decoration: BoxDecoration(
        color: AppColors.papier,
        border: const Border(top: BorderSide(color: AppColors.borderStrong)),
        boxShadow: compact
            ? null
            : const [
                BoxShadow(
                  color: AppColors.financeDetailShadow,
                  blurRadius: 12,
                  offset: Offset(0, -4),
                ),
              ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.facturationDetailChargeTotalsLabel,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.bleuArdoise,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _formatAmount(expected),
                style: AppTextStyles.totalAmountLora.copyWith(
                  fontSize: 14,
                  color: AppColors.bleuArdoise,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _formatAmount(paid),
                style: AppTextStyles.totalAmountLora.copyWith(
                  fontSize: 14,
                  color: AppColors.bleuArdoise,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _formatAmount(remaining),
                style: AppTextStyles.totalAmountLora.copyWith(
                  fontSize: 14,
                  color: AppColors.terreCuite,
                ),
              ),
            ),
          ),
          const Expanded(flex: 3, child: SizedBox.shrink()),
        ],
      ),
    );

    if (!compact) {
      return footer;
    }

    return footer;
  }
}
