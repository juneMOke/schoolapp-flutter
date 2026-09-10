import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_key_figures.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre cartes de tête : **deux montants, puis deux effectifs**.
///
/// L'ordre porte la lecture — ce qui est dû, ce qui est rentré, puis qui n'a
/// rien fait et qui a commencé. « Tout soldé » ne prend pas de carte : il se lit
/// dans la sous-ligne du perçu, parce qu'une quatrième tuile d'effectif pour une
/// population qui n'a que trois états redirait ce que les deux autres disent.
///
/// **Aucun montant n'est jamais sommé entre devises.** Un sac à deux entrées
/// rend deux lignes empilées dans la même carte ([EteeloKpiCardData.valueLines])
/// — jamais un total qui n'existe pas.
///
/// Les teintes des deux effectifs sont celles des **statuts** de créance
/// ([StudentChargeStatusUiX]), comme sur l'écran de contrôle : une couleur veut
/// dire ici ce qu'elle veut dire sur la pastille de chaque ligne. Chaque carte
/// porte en outre son icône et son libellé — l'état n'est jamais dit par la
/// seule couleur.
List<EteeloKpiCardData> recouvrementKeyFigureCards(
  RecouvrementKeyFigures figures,
  AppLocalizations l10n,
) {
  final settled = StudentChargeStatus.paid.visuals;
  final none = StudentChargeStatus.due.visuals;
  final partial = StudentChargeStatus.partial.visuals;

  return [
    EteeloKpiCardData(
      label: l10n.recouvrementExpectedLabel,
      valueLines: _moneyLines(figures.expected, l10n),
      accent: AppColors.bleuArdoise,
      accentSoft: AppColors.bleuArdoiseSoft,
      icon: Icons.receipt_long_outlined,
      // En sélection mixte, la carte porte deux montants : la sous-ligne dit
      // pourquoi ils ne sont pas additionnés, plutôt que de laisser croire à un
      // oubli de total.
      subline: figures.expected.isMultiCurrency
          ? l10n.recouvrementExpectedMixedSubline
          : null,
    ),
    EteeloKpiCardData(
      label: l10n.recouvrementCollectedLabel,
      valueLines: _moneyLines(figures.paid, l10n),
      accent: settled.color,
      accentSoft: settled.soft,
      icon: Icons.payments_outlined,
      subline: l10n.recouvrementSettledSubline(
        figures.settled,
        figures.percentOf(figures.settled),
      ),
    ),
    EteeloKpiCardData(
      label: l10n.recouvrementNothingPaidLabel,
      value: figures.none,
      percent: figures.percentOf(figures.none),
      accent: none.color,
      accentSoft: none.soft,
      icon: none.icon,
      subline: l10n.recouvrementNothingPaidSubline,
    ),
    EteeloKpiCardData(
      label: l10n.recouvrementPartialLabel,
      value: figures.partial,
      percent: figures.percentOf(figures.partial),
      accent: partial.color,
      accentSoft: partial.soft,
      icon: partial.icon,
      subline: l10n.recouvrementPartialSubline,
    ),
  ];
}

/// Une ligne par devise, chacune avec son symbole.
///
/// Un sac **vide** — aucune créance du tout — rend un tiret plutôt qu'un
/// « 0 » : rien n'est dû, et un zéro laisserait croire qu'on sait dans quelle
/// unité rien n'est dû. Une entrée **à zéro**, elle, s'écrit bien « 0 $ » :
/// c'est une devise où il ne reste rien, ce qui n'est pas la même phrase.
List<String> _moneyLines(MoneyBag bag, AppLocalizations l10n) => bag.isEmpty
    ? [l10n.recouvrementNoAmountDash]
    : [for (final entry in bag.entries) MoneyFormat.format(entry)];
