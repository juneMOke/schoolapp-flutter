import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_designation.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/utils/facturation_collect_payment_utils.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_form_fields.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ligne de frais à régler de la page d'encaissement (spec MODALE-12).
///
/// Repliée : case à cocher + libellé + statut + l'état « Dû / Déjà payé /
/// Restant ». Cochée : **comment le parent règle ce frais**, le ou les montants,
/// l'avertissement de dépassement, et le restant après paiement recalculé en
/// direct.
///
/// ## Deux cases quand les unités diffèrent, une seule sinon
///
/// La question « le parent règle en quoi ? » se pose sur le frais, parce que
/// c'est là qu'elle a une réponse : la devise de la créance est le point de
/// départ. Tant qu'il règle dans cette devise-là, rien ne change — un champ, le
/// même qu'avant. Dès qu'il en choisit une autre, la ligne montre les **deux**
/// montants : ce qu'on impute, et ce qu'on compte au comptoir. Remplir l'un
/// remplit l'autre.
///
/// C'est plus court à lire qu'une valeur dérivée en petit sous le champ, et
/// surtout ça se manipule dans les deux sens : le caissier tape le billet posé
/// devant lui, ou la part de dette qu'il éteint, selon ce que le parent dit.
class FacturationCreatePaymentChargeAllocationLine extends StatelessWidget {
  final StudentCharge charge;
  final bool selected;
  final TextEditingController amountController;
  final ValueChanged<bool> onSelectedChanged;
  final VoidCallback onSettleAll;

  /// Les devises proposables pour CE frais, la sienne en tête. Moins de deux ⇒
  /// aucun sélecteur : il n'y a rien à choisir.
  final List<String> currencyOptions;

  /// La devise de règlement retenue pour cette ligne.
  final String tenderCurrency;

  final ValueChanged<String> onTenderCurrencyChanged;

  /// Le montant **posé sur le comptoir**, dans [tenderCurrency]. Utilisé
  /// seulement quand les deux devises diffèrent.
  final TextEditingController tenderController;

  /// Le taux appliqué, déjà rendu (« 2 800 FC / \\$ »). `null` quand il n'y a
  /// rien à convertir.
  ///
  /// C'est le chiffre que le parent conteste au guichet : il se lit sur la
  /// ligne qu'il concerne, pas dans un encadré commun où deux frais réglés
  /// différemment se confondraient.
  final String? rateLabel;

  /// La monnaie à rendre, déjà rendue. `null` quand la conversion tombe juste.
  ///
  /// 50 000 FC à 2 800 éteignent 17,85 \\$ et laissent 20 FC : ils repartent
  /// avec le parent, ils n'entrent pas dans le tiroir.
  final String? changeLabel;

  /// L'un des deux montants vient d'être tapé : l'autre se recalcule.
  final VoidCallback onAllocationEdited;
  final VoidCallback onTenderEdited;

  const FacturationCreatePaymentChargeAllocationLine({
    super.key,
    required this.charge,
    required this.selected,
    required this.amountController,
    required this.onSelectedChanged,
    required this.onSettleAll,
    required this.tenderController,
    required this.onAllocationEdited,
    required this.onTenderEdited,
    this.currencyOptions = const [],
    this.tenderCurrency = '',
    this.onTenderCurrencyChanged = _ignore,
    this.rateLabel,
    this.changeLabel,
  });

  static void _ignore(String _) {}

  /// Vrai quand cette ligne convertit — le seul cas à deux champs.
  bool get _converted =>
      tenderCurrency.isNotEmpty && tenderCurrency != charge.currency;

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
                  chargeDesignation(charge, l10n),
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
              _format(charge.paidTotalInCents),
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
                      // « Le parent règle en… » — la question se pose ici,
                      // après le frais et avant le montant, dans l'ordre où
                      // elle se pose au comptoir.
                      if (currencyOptions.length > 1) ...[
                        _TenderCurrencyPicker(
                          options: currencyOptions,
                          selected: tenderCurrency,
                          onSelected: onTenderCurrencyChanged,
                          label: l10n.facturationCreatePaymentTenderCurrency,
                        ),
                        const SizedBox(height: AppDimensions.spacingM),
                      ],
                      _MoneyField(
                        controller: amountController,
                        currency: charge.currency,
                        label: l10n.facturationCreatePaymentAmountToSettleLabel,
                        hint: l10n.facturationCreatePaymentAmountHint,
                        onEdited: onAllocationEdited,
                      ),
                      if (_converted) ...[
                        const SizedBox(height: AppDimensions.spacingS),
                        _MoneyField(
                          controller: tenderController,
                          currency: tenderCurrency,
                          label: l10n.facturationCreatePaymentTenderAmountLabel,
                          hint: l10n.facturationCreatePaymentAmountHint,
                          accent: AppColors.terreCuiteDark,
                          onEdited: onTenderEdited,
                        ),
                        if (rateLabel != null || changeLabel != null) ...[
                          const SizedBox(height: AppDimensions.spacingXS),
                          _ConversionCaption(
                            rateLabel: rateLabel,
                            changeLabel: changeLabel,
                          ),
                        ],
                      ],
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
/// « Le parent règle en… » — une bascule exclusive, jamais deux champs reliés
/// par un « ou ».
///
/// La devise de règlement est un **mode** : on en choisit un, et seuls ses
/// montants partent. Même règle que la recherche bi-mode, pour la même raison —
/// deux blocs concurrents laisseraient croire qu'on peut panacher sur une même
/// ligne, ce que le modèle ne sait pas représenter.
class _TenderCurrencyPicker extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final String label;

  const _TenderCurrencyPicker({
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.badge.copyWith(
            color: AppColors.terreCuite,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        SegmentedTabFilter<String>(
          expand: true,
          selected: selected,
          onSelected: onSelected,
          semanticsLabel: label,
          options: [
            for (final currency in options)
              SegmentedTabOption<String>(
                label: MoneyFormat.symbolOf(currency),
                value: currency,
                semanticLabel: currency,
              ),
          ],
        ),
      ],
    );
  }
}

/// Un montant, dans une devise nommée.
///
/// `onEdited` ne part qu'à la frappe de l'utilisateur : c'est ce qui permet à
/// la page de recalculer l'AUTRE champ sans jamais réécrire celui qui a le
/// curseur.
class _MoneyField extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  final String label;
  final String hint;
  final Color accent;
  final VoidCallback onEdited;

  const _MoneyField({
    required this.controller,
    required this.currency,
    required this.label,
    required this.hint,
    required this.onEdited,
    this.accent = AppColors.bleuArdoise,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTextStyles.moneyTabular.copyWith(color: AppColors.textPrimary),
      onChanged: (_) => onEdited(),
      decoration: financeInputDecoration(
        label: label,
        hint: hint,
        accentColor: accent,
        readOnly: false,
      ).copyWith(suffixText: currency),
    );
  }
}

/// Le taux appliqué, et ce qui repart avec le parent.
///
/// Les deux se lisent sur la ligne qu'ils concernent : deux frais réglés
/// différemment ont deux taux, et un encadré commun les confondrait.
class _ConversionCaption extends StatelessWidget {
  final String? rateLabel;
  final String? changeLabel;

  const _ConversionCaption({this.rateLabel, this.changeLabel});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.spacingM,
      runSpacing: AppDimensions.spacingXS,
      children: [
        if (rateLabel != null)
          Text(
            rateLabel!,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        if (changeLabel != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.savings_outlined,
                size: 14,
                color: AppColors.terreCuiteDark,
              ),
              const SizedBox(width: AppDimensions.spacingXS),
              Text(
                changeLabel!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.terreCuiteDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

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
