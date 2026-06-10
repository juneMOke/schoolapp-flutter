import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_fee_code_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Table des paiements affectés à un frais : une ligne par allocation
/// (libellé à gauche · montant imputé à l'extrême droite) + total alloué.
///
/// Épouse la largeur disponible (pas de défilement horizontal) → la colonne
/// montant reste toujours visible, y compris dans une popin étroite.
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

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        children: [
          for (final allocation in allocations) ...[
            _AllocationRow(
              allocation: allocation,
              formatAmount: _formatAmount,
              l10n: l10n,
            ),
            const Divider(height: 1, color: AppColors.border),
          ],
          _TotalAllocationRow(
            label: l10n.facturationChargeDetailAllocationsTotalLabel,
            amount: _formatAmount(totalInCents),
          ),
        ],
      ),
    );
  }
}

class _AllocationRow extends StatelessWidget {
  final PaymentAllocation allocation;
  final String Function(double) formatAmount;
  final AppLocalizations l10n;

  const _AllocationRow({
    required this.allocation,
    required this.formatAmount,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS + 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              allocation.feeCode.localizedFeeLabel(l10n),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Text(
            formatAmount(allocation.amountInCents.toDouble()),
            style: AppTextStyles.moneyTabular.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

class _TotalAllocationRow extends StatelessWidget {
  final String label;
  final String amount;

  const _TotalAllocationRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.papier,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS + 2,
      ),
      child: Row(
        children: [
          Expanded(
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
          const SizedBox(width: AppDimensions.spacingM),
          Text(
            amount,
            style: AppTextStyles.totalAmountLora.copyWith(
              fontSize: 16,
              color: AppColors.terreCuite,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
