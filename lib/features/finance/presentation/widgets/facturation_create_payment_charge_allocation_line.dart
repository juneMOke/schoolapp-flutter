import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_fee_code_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/utils/facturation_collect_payment_utils.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_form_fields.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ligne de frais à régler de la modale d'encaissement (spec MODALE-12).
///
/// Repliée : case à cocher + libellé + statut + l'état « Dû / Déjà payé /
/// Restant ». Cochée : champ « Montant à régler » (+ « Tout solder »),
/// avertissement de dépassement, et restant après paiement recalculé en direct.
class FacturationCreatePaymentChargeAllocationLine extends StatelessWidget {
  final StudentCharge charge;
  final bool selected;
  final TextEditingController amountController;
  final ValueChanged<bool> onSelectedChanged;
  final VoidCallback onSettleAll;

  const FacturationCreatePaymentChargeAllocationLine({
    super.key,
    required this.charge,
    required this.selected,
    required this.amountController,
    required this.onSelectedChanged,
    required this.onSettleAll,
  });

  String _format(num cents) => formatMonetaryAmountWithCurrency(
    amount: cents / 100,
    currency: charge.currency,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remaining = chargeRemainingInCents(charge);
    final effective = effectiveAllocationCents(
      selected: selected,
      rawAmount: amountController.text,
      remainingInCents: remaining,
    );
    final overflowing = isAmountOverflowing(
      selected: selected,
      rawAmount: amountController.text,
      remainingInCents: remaining,
    );
    final remainingAfter = remaining - effective;

    return AnimatedContainer(
      duration: FinanceMotion.standard,
      curve: FinanceMotion.outCurve,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.bleuArdoise.withValues(alpha: 0.04)
            : AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: selected ? AppColors.billingHelpBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AllocationCheckbox(
                value: selected,
                onChanged: () => onSelectedChanged(!selected),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  charge.feeCode.localizedFeeLabel(l10n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              _StatusBadge(
                status: charge.status,
                label: charge.status.localizedLabel(l10n),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          _StateLine(
            dueLabel: l10n.facturationCreatePaymentChargeDue(
              _format(charge.expectedAmountInCents),
            ),
            paidLabel: l10n.facturationCreatePaymentChargePaid(
              _format(charge.amountPaidInCents),
            ),
            remainingLabel: l10n.facturationCreatePaymentChargeRemaining(
              _format(remaining),
            ),
          ),
          AnimatedSwitcher(
            duration: FinanceMotion.standard,
            switchInCurve: FinanceMotion.outCurve,
            switchOutCurve: FinanceMotion.inCurve,
            child: !selected
                ? const SizedBox.shrink(key: ValueKey('collapsed'))
                : Column(
                    key: const ValueKey('expanded'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppDimensions.spacingM),
                      TextField(
                        // La mise à jour du total/restant est portée par le
                        // listener du controller côté modale ; pas d'onChanged
                        // redondant ici.
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppTextStyles.moneyTabular.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: financeInputDecoration(
                          label:
                              l10n.facturationCreatePaymentAmountToSettleLabel,
                          hint: l10n.facturationCreatePaymentAmountHint,
                          accentColor: AppColors.bleuArdoise,
                          readOnly: false,
                        ).copyWith(suffixText: charge.currency),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: onSettleAll,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.spacingXS,
                            ),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.facturationCreatePaymentSettleAllAction,
                          ),
                        ),
                      ),
                      if (overflowing) ...[
                        const SizedBox(height: AppDimensions.spacingS),
                        _OverflowWarning(
                          message: l10n
                              .facturationCreatePaymentAmountClampedWarning(
                                _format(remaining),
                              ),
                        ),
                      ],
                      const SizedBox(height: AppDimensions.spacingS),
                      _RemainingAfter(
                        isSettled: remainingAfter <= 0,
                        label: l10n.facturationCreatePaymentRemainingAfter(
                          _format(remainingAfter < 0 ? 0 : remainingAfter),
                        ),
                        settledChip: l10n.facturationCreatePaymentSettledChip,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Case à cocher 20 dp : bleu-ardoise plein + coche blanche quand cochée.
class _AllocationCheckbox extends StatelessWidget {
  final bool value;
  final VoidCallback onChanged;

  const _AllocationCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      child: InkWell(
        onTap: onChanged,
        borderRadius: AppRadius.brSm,
        child: AnimatedContainer(
          duration: FinanceMotion.fast,
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: value ? AppColors.bleuArdoise : AppColors.surface,
            borderRadius: AppRadius.brSm,
            border: Border.all(
              color: value ? AppColors.bleuArdoise : AppColors.borderStrong,
              width: 1.5,
            ),
          ),
          child: value
              ? const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: AppColors.textOnDark,
                )
              : null,
        ),
      ),
    );
  }
}

/// Pastille de statut compacte du frais (Soldé / Partiel / Impayé).
class _StatusBadge extends StatelessWidget {
  final StudentChargeStatus status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final visuals = status.visuals;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: visuals.soft,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: visuals.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visuals.icon, size: 13, color: visuals.color),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            label,
            style: AppTextStyles.badge.copyWith(color: visuals.color),
          ),
        ],
      ),
    );
  }
}

/// État avant paiement : « Dû · Déjà payé · Restant » (restant en rouge).
class _StateLine extends StatelessWidget {
  final String dueLabel;
  final String paidLabel;
  final String remainingLabel;

  const _StateLine({
    required this.dueLabel,
    required this.paidLabel,
    required this.remainingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.caption.copyWith(color: AppColors.textSecondary);
    return Wrap(
      spacing: AppDimensions.spacingM,
      runSpacing: AppDimensions.spacingXS,
      children: [
        Text(dueLabel, style: base),
        Text(paidLabel, style: base),
        Text(
          remainingLabel,
          style: base.copyWith(
            color: AppColors.feeStatusDue,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Avertissement ambre : la saisie dépasse le restant, montant ramené.
class _OverflowWarning extends StatelessWidget {
  final String message;

  const _OverflowWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingS),
      decoration: BoxDecoration(
        color: AppColors.feeStatusPartialSoft,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: AppColors.feeStatusPartialBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: AppColors.feeStatusPartial,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.feeStatusPartial,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Restant après paiement : vert + chip « Soldé » si 0, sinon rouge.
class _RemainingAfter extends StatelessWidget {
  final bool isSettled;
  final String label;
  final String settledChip;

  const _RemainingAfter({
    required this.isSettled,
    required this.label,
    required this.settledChip,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSettled ? AppColors.feeStatusPaid : AppColors.feeStatusDue;
    return Row(
      children: [
        Icon(
          isSettled
              ? Icons.check_circle_outline_rounded
              : Icons.account_balance_wallet_outlined,
          size: 16,
          color: color,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (isSettled)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingS,
              vertical: AppDimensions.spacingXS,
            ),
            decoration: BoxDecoration(
              color: AppColors.feeStatusPaidSoft,
              borderRadius: AppRadius.brPill,
              border: Border.all(color: AppColors.feeStatusPaidBorder),
            ),
            child: Text(
              settledChip,
              style: AppTextStyles.badge.copyWith(
                color: AppColors.feeStatusPaid,
              ),
            ),
          ),
      ],
    );
  }
}
