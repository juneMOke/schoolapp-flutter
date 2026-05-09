import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Tableau ETEELO des allocations (paiements imputés) pour une charge en détail.
/// Structure : colonnes (libellé paiement / montant) + séparations + total imputé en pied.
class FacturationChargeDetailAllocationsTable extends StatelessWidget {
  final List<PaymentAllocation> allocations;
  final double totalInCents;
  final String currency;

  const FacturationChargeDetailAllocationsTable({
    super.key,
    required this.allocations,
    required this.totalInCents,
    required this.currency,
  });

  String _formatAmount(double cents) {
    return formatMonetaryAmountWithCurrency(
      amount: cents / 100,
      currency: currency,
    );
  }

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
                    itemCount: allocations.length + 1, // +1 pour le total
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      if (index < allocations.length) {
                        return _AllocationRow(
                          allocation: allocations[index],
                          formatAmount: _formatAmount,
                        );
                      }
                      return _TotalAllocationRow(
                        label: l10n.facturationChargeDetailAllocationsTotalLabel,
                        amount: _formatAmount(totalInCents),
                      );
                    },
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
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                l10n.facturationDetailPaymentAmountColumn,
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

class _AllocationRow extends StatelessWidget {
  final PaymentAllocation allocation;
  final String Function(double) formatAmount;

  const _AllocationRow({
    required this.allocation,
    required this.formatAmount,
  });

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
                allocation.studentChargeLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatAmount(allocation.amountInCents.toDouble()),
                style: AppTextStyles.moneyTabular.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalAllocationRow extends StatelessWidget {
  final String label;
  final String amount;

  const _TotalAllocationRow({
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.papier,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                amount,
                style: AppTextStyles.totalAmountLora.copyWith(
                  fontSize: 16,
                  color: AppColors.terreCuite,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
