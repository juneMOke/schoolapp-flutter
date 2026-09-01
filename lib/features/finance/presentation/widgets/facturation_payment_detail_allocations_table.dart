import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_designation.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Table « Répartition par frais » : une ligne par allocation (libellé du frais
/// à gauche · montant imputé à l'extrême droite), suivie du total imputé.
///
/// Épouse la largeur disponible (pas de défilement horizontal) : la colonne
/// montant reste donc toujours visible, y compris dans une popin étroite.
class FacturationPaymentDetailAllocationsTable extends StatelessWidget {
  final List<PaymentAllocation> allocations;

  const FacturationPaymentDetailAllocationsTable({
    super.key,
    required this.allocations,
  });

  /// Chaque imputation porte SA devise — elle solde une créance, donc elle en
  /// tient exactement une. La table recevait une devise unique pour toute la
  /// répartition : juste tant que le versement n'en réglait qu'une.
  String _formatAmount(PaymentAllocation allocation) => MoneyFormat.format(
    Money.parse(allocation.amountInCents, allocation.currency),
  );

  /// Le total imputé, **par devise**, dérivé des lignes.
  MoneyBag get _total => MoneyBag.sumBy(
    allocations,
    (a) => Money.parse(a.amountInCents, a.currency),
  );

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
            label: l10n.facturationPaymentAllocationsTotalLabel,
            amount: _total.entries.map(MoneyFormat.format).join(' · '),
          ),
        ],
      ),
    );
  }
}

class _AllocationRow extends StatelessWidget {
  final PaymentAllocation allocation;
  final String Function(PaymentAllocation) formatAmount;
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
              // Le libellé GELÉ à l'encaissement — ce que le guichet a validé
              // ce jour-là — et le code de la tranche visée. La nature seule
              // rendait indistinctes deux imputations d'un même minerval.
              feeDesignation(
                label: allocation.studentChargeLabel,
                feeCode: allocation.feeCode,
                feeTariffCode: allocation.feeTariffCode,
                l10n: l10n,
              ),
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
            formatAmount(allocation),
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
