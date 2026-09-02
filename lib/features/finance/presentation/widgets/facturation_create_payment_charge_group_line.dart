import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_charge_group_entry.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_designation.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/fee_status_badge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La ligne d'une **nature de frais** à l'encaissement (GE-2).
///
/// Le caissier coche « Minerval », tape un montant, et l'écran ventile sur les
/// tranches — au lieu de cocher sept lignes et de taper sept montants.
///
/// **La ventilation est affichée même replié.** Le caissier valide une
/// répartition ; la lui cacher lui ferait signer quelque chose qu'il n'a pas vu,
/// et c'est cette répartition qui partira sur la note de perception.
class FacturationCreatePaymentChargeGroupLine extends StatelessWidget {
  final FacturationChargeGroupEntry group;

  /// Le titre écrit par l'école, `null` s'il n'est pas connu de cet appareil.
  final String? schoolTitle;

  final ValueChanged<bool> onSelectedChanged;
  final VoidCallback onSettleAll;
  final VoidCallback onAmountEdited;
  final VoidCallback onToggleExpanded;

  /// Les devises proposables pour CETTE nature, la sienne en tête. Moins de
  /// deux ⇒ aucun sélecteur.
  final List<String> currencyOptions;
  final ValueChanged<String> onTenderCurrencyChanged;

  /// Le comptoir vient d'être tapé : l'imputation se recalcule.
  final VoidCallback onTenderEdited;

  /// Le taux appliqué, déjà rendu. `null` quand la nature ne convertit pas.
  final String? rateLabel;

  /// La monnaie à rendre, déjà rendue.
  final String? changeLabel;

  /// Les lignes de tranche, déjà construites par l'appelant — c'est la page qui
  /// sait les câbler (devise de règlement, taux, monnaie à rendre).
  final List<Widget> trancheLines;

  const FacturationCreatePaymentChargeGroupLine({
    super.key,
    required this.group,
    required this.schoolTitle,
    required this.onSelectedChanged,
    required this.onSettleAll,
    required this.onAmountEdited,
    required this.onToggleExpanded,
    required this.trancheLines,
    this.currencyOptions = const [],
    this.onTenderCurrencyChanged = _ignore,
    this.onTenderEdited = _ignoreVoid,
    this.rateLabel,
    this.changeLabel,
  });

  static void _ignore(String _) {}
  static void _ignoreVoid() {}

  String _format(int cents) => MoneyFormat.format(Money(cents, group.currency));

  /// « T1 500 FC · T2 500 FC · T3 200 FC » — ce que le montant va imputer.
  ///
  /// Ne rend `null` que si rien n'est ventilé : une mention vide vaut moins que
  /// pas de mention.
  String? _ventilation(AppLocalizations l10n) {
    final parts = <String>[
      for (final tranche in group.tranches)
        if (tranche.effectiveCents > 0)
          l10n.facturationCreatePaymentGroupVentilationItem(
            shortTrancheLabel(tranche.charge, l10n),
            _format(tranche.effectiveCents),
          ),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = group.selected;
    // Statut du groupe dérivé du COMPOSÉ, jamais du miroir serveur : rien ne le
    // recalcule après un encaissement local (GF-4).
    final status = group.asChargeGroup.status;
    final ventilation = _ventilation(l10n);

    return AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.outCurve,
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
          _HeaderRow(
            selected: selected,
            label: chargeGroupDesignation(
              group.asChargeGroup,
              l10n,
              schoolTitle: schoolTitle,
            ),
            trancheLabel: l10n.facturationCreatePaymentGroupRemainingTranches(
              group.trancheCount,
            ),
            statusLabel: status.localizedLabel(l10n),
            statusVisuals: status.visuals,
            onSelectedChanged: onSelectedChanged,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            l10n.facturationCreatePaymentChargeRemaining(
              _format(group.capInCents),
            ),
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          AnimatedSize(
            duration: AppMotion.layout,
            curve: AppMotion.outCurve,
            alignment: Alignment.topCenter,
            child: !selected
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppDimensions.spacingM),
                      // Dès que les TRANCHES commandent, la nature cesse
                      // d'être l'unité de règlement : son sélecteur de devise
                      // et son comptoir disparaissent, et son montant n'est
                      // plus qu'un total. Les laisser afficherait deux devises
                      // concurrentes pour un même versement.
                      if (group.groupIsSource &&
                          currencyOptions.length > 1) ...[
                        _CurrencyPicker(
                          options: currencyOptions,
                          selected: group.effectiveTenderCurrency,
                          onSelected: onTenderCurrencyChanged,
                        ),
                        const SizedBox(height: AppDimensions.spacingS),
                      ],
                      _AmountRow(
                        controller: group.controller,
                        currency: group.currency,
                        // Les tranches commandent : le champ du groupe n'est
                        // plus une saisie mais leur total. Le laisser
                        // modifiable ferait deux vérités pour un montant.
                        readOnly: !group.groupIsSource,
                        onEdited: onAmountEdited,
                        onSettleAll: onSettleAll,
                      ),
                      // Le comptoir : un seul champ pour toute la nature, là où
                      // l'écran en affichait un par tranche. Les tranches d'un
                      // groupe partagent la devise de créance, donc une seule
                      // conversion et un seul taux à lire pour le parent.
                      if (group.groupIsSource && group.isConverted) ...[
                        const SizedBox(height: AppDimensions.spacingS),
                        _TenderRow(
                          controller: group.tenderController,
                          currency: group.effectiveTenderCurrency,
                          onEdited: onTenderEdited,
                        ),
                        if (rateLabel != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppDimensions.spacingXS,
                            ),
                            child: Text(
                              rateLabel!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        if (changeLabel != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppDimensions.spacingXS,
                            ),
                            child: Text(
                              changeLabel!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                      if (ventilation != null) ...[
                        const SizedBox(height: AppDimensions.spacingS),
                        Text(
                          l10n.facturationCreatePaymentGroupVentilation(
                            ventilation,
                          ),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.bleuArdoise,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          if (!group.isSingleTranche) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onToggleExpanded,
                icon: Icon(
                  group.expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: AppDimensions.detailHeaderIconSize,
                ),
                label: Text(
                  group.expanded
                      ? l10n.facturationCreatePaymentGroupCollapseAction
                      : l10n.facturationCreatePaymentGroupExpandAction,
                ),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 0),
                  foregroundColor: AppColors.bleuArdoise,
                ),
              ),
            ),
          ],
          AnimatedSize(
            duration: AppMotion.layout,
            curve: AppMotion.outCurve,
            alignment: Alignment.topCenter,
            child: group.expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: AppDimensions.spacingS),
                      for (var i = 0; i < trancheLines.length; i++) ...[
                        trancheLines[i],
                        if (i < trancheLines.length - 1)
                          const SizedBox(height: AppDimensions.spacingS),
                      ],
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final bool selected;
  final String label;
  final String trancheLabel;
  final String statusLabel;
  final FeeStatusVisuals statusVisuals;
  final ValueChanged<bool> onSelectedChanged;

  const _HeaderRow({
    required this.selected,
    required this.label,
    required this.trancheLabel,
    required this.statusLabel,
    required this.statusVisuals,
    required this.onSelectedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: selected,
            onChanged: (value) => onSelectedChanged(value ?? false),
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                trancheLabel,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        FeeStatusBadge(label: statusLabel, visuals: statusVisuals),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  final bool readOnly;
  final VoidCallback onEdited;
  final VoidCallback onSettleAll;

  const _AmountRow({
    required this.controller,
    required this.currency,
    required this.readOnly,
    required this.onEdited,
    required this.onSettleAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onEdited(),
            decoration: InputDecoration(
              labelText: l10n.facturationCreatePaymentGroupAmountLabel,
              hintText: l10n.facturationCreatePaymentGroupAmountHint,
              suffixText: MoneyFormat.symbolOf(currency),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        // `minimumSize` explicite : le thème pose les boutons en pleine
        // largeur, et un bouton inline sans cette borne réclame une largeur
        // infinie dans une `Row`.
        OutlinedButton(
          onPressed: onSettleAll,
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          child: Text(l10n.facturationCreatePaymentSettleAllAction),
        ),
      ],
    );
  }
}

class _TenderRow extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  final VoidCallback onEdited;

  const _TenderRow({
    required this.controller,
    required this.currency,
    required this.onEdited,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => onEdited(),
      decoration: InputDecoration(
        labelText: l10n.facturationCreatePaymentTenderAmountLabel,
        suffixText: MoneyFormat.symbolOf(currency),
        isDense: true,
      ),
    );
  }
}

/// Le choix de la devise de règlement, pour toute la nature.
class _CurrencyPicker extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CurrencyPicker({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.spacingXS,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(MoneyFormat.symbolOf(option)),
            selected: option == selected,
            onSelected: (_) => onSelected(option),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
