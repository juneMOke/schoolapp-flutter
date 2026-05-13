import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FacturationPaymentsTable extends StatelessWidget {
  final List<Payment> payments;
  final ValueChanged<Payment> onViewRequested;

  const FacturationPaymentsTable({
    super.key,
    required this.payments,
    required this.onViewRequested,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
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
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: payments.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) => _PaymentRow(
                      payment: payments[index],
                      onViewRequested: onViewRequested,
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
                l10n.facturationDetailPaymentPayerColumn,
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
                l10n.facturationDetailPaymentPaidAtColumn,
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
                l10n.facturationDetailPaymentAmountColumn,
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

class _PaymentRow extends StatelessWidget {
  final Payment payment;
  final ValueChanged<Payment> onViewRequested;

  const _PaymentRow({required this.payment, required this.onViewRequested});

  String _formatAmount(Payment value) {
    return formatMonetaryAmountWithCurrency(
      amount: value.amountInCents / 100,
      currency: value.currency,
    );
  }

  String _formatDate(BuildContext context, DateTime value) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatShortDate(value);
  }

  String _payerFullName(AppLocalizations l10n) {
    final middleName = payment.payerMiddleName?.trim();
    final names = <String>[
      payment.payerLastName,
      payment.payerFirstName,
      if (middleName != null && middleName.isNotEmpty) middleName,
    ];
    final fullName = names.where((name) => name.trim().isNotEmpty).join(' ');
    return fullName.isEmpty ? l10n.facturationDetailUnknownValue : fullName;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: AppColors.surfaceRaised,
      child: InkWell(
        onTap: () => onViewRequested(payment),
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
                  child: Row(
                    children: [
                      StudentAvatar(
                        firstName: payment.payerFirstName,
                        lastName: payment.payerLastName,
                        size: 32,
                        variant: AvatarVariant.solid,
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Expanded(
                        child: Text(
                          _payerFullName(l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatDate(context, payment.paidAt),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatAmount(payment),
                    style: AppTextStyles.moneyTabular.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => onViewRequested(payment),
                    tooltip: l10n.facturationDetailViewPaymentLabel,
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
