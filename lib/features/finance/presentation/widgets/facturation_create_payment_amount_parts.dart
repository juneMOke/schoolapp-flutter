import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_form_fields.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les briques de saisie d'un montant à l'encaissement, **une seule fois** : la
/// ligne d'une nature de frais et celle d'une tranche se lisent de la même
/// façon, au guichet, quel que soit le découpage du frais.

/// « Le parent règle en… » — une bascule exclusive, jamais deux champs reliés
/// par un « ou ».
///
/// La devise de règlement est un **mode** : on en choisit un, et seuls ses
/// montants partent. Même règle que la recherche bi-mode, pour la même raison —
/// deux blocs concurrents laisseraient croire qu'on peut panacher sur une même
/// ligne, ce que le modèle ne sait pas représenter.
class FacturationTenderCurrencyPicker extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const FacturationTenderCurrencyPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(
      context,
    )!.facturationCreatePaymentTenderCurrency;
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
class FacturationAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  final String label;
  final String hint;
  final Color accent;
  final bool readOnly;
  final VoidCallback onEdited;

  const FacturationAmountField({
    super.key,
    required this.controller,
    required this.currency,
    required this.label,
    required this.hint,
    required this.onEdited,
    this.accent = AppColors.bleuArdoise,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      style: AppTextStyles.moneyTabular.copyWith(color: AppColors.textPrimary),
      onChanged: (_) => onEdited(),
      decoration: financeInputDecoration(
        label: label,
        hint: hint,
        accentColor: accent,
        readOnly: readOnly,
      ).copyWith(suffixText: MoneyFormat.symbolOf(currency)),
    );
  }
}

/// Le champ du montant, et « Tout solder » à sa droite.
class FacturationSettleableAmountRow extends StatelessWidget {
  final Widget field;
  final VoidCallback onSettleAll;

  const FacturationSettleableAmountRow({
    super.key,
    required this.field,
    required this.onSettleAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(child: field),
        const SizedBox(width: AppDimensions.spacingS),
        // `minimumSize` explicite : le thème pose les boutons en pleine
        // largeur, et un bouton inline sans cette borne réclame une largeur
        // infinie dans une `Row`. 48 dp : il se touche au doigt, au guichet.
        OutlinedButton(
          onPressed: onSettleAll,
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          child: Text(l10n.facturationCreatePaymentSettleAllAction),
        ),
      ],
    );
  }
}
