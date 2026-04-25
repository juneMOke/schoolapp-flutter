import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
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
              color: AppColors.financeDetailPaymentsAccentSoft,
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
            itemCount: payments.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, index) => _PaymentRow(
              payment: payments[index],
              onViewRequested: onViewRequested,
              isEven: index.isEven,
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
              l10n.facturationDetailPaymentPayerColumn,
              style: AppTextStyles.tableHeader.copyWith(
                color: AppColors.financeDetailPaymentsAccent,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              l10n.facturationDetailPaymentPaidAtColumn,
              style: AppTextStyles.tableHeader.copyWith(
                color: AppColors.financeDetailPaymentsAccent,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              l10n.facturationDetailPaymentAmountColumn,
              style: AppTextStyles.tableHeader.copyWith(
                color: AppColors.financeDetailPaymentsAccent,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                l10n.facturationDetailPaymentActionsColumn,
                style: AppTextStyles.tableHeader.copyWith(
                  color: AppColors.financeDetailPaymentsAccent,
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
  final bool isEven;

  const _PaymentRow({
    required this.payment,
    required this.onViewRequested,
    required this.isEven,
  });

  String _formatAmount(Payment value) {
    final majorUnits = value.amountInCents / 100;
    return '${majorUnits.toStringAsFixed(2)} ${value.currency}';
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

    return Container(
      color: isEven ? AppColors.surface : AppColors.financeDetailMutedSurface,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              _payerFullName(l10n),
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(context, payment.paidAt),
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatAmount(payment),
              style: AppTextStyles.bodyStrong.copyWith(color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => onViewRequested(payment),
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: AppColors.financeDetailPaymentsAccent,
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
