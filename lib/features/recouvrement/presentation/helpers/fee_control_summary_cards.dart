import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les cartes d'une synthèse de contrôle : élèves concernés, puis soldés /
/// partiels / sans paiement — et, sur l'écran nominatif, ce qui a été encaissé.
///
/// **Une seule anatomie pour les deux écrans du module.** L'écran nominatif
/// synthétise une classe, le tableau de bord synthétise un périmètre entier :
/// ce sont les mêmes quatre nombres, et les recomposer de part et d'autre
/// aurait fini par les faire diverger — sur les libellés, sur les teintes, ou
/// sur l'arrondi.
///
/// Les teintes sont celles des **statuts** de créance ([StudentChargeStatusUiX])
/// et jamais une palette de série : une couleur veut dire ici ce qu'elle veut
/// dire sur la pastille de chaque ligne. Chaque carte porte en outre son icône
/// et son libellé — l'état n'est jamais dit par la seule couleur.
///
/// ## Les quatre premières **filtrent**
///
/// [onSituation] les rend cliquables : la tuile applique la situation qu'elle
/// compte. Aucune n'active « a payé au moins… » — un plancher se saisit, il ne
/// se devine pas. Laisser [onSituation] à `null` rend les cartes de lecture du
/// tableau de bord, inchangées.
List<EteeloKpiCardData> feeControlSummaryCards(
  FeeControlBreakdown breakdown,
  AppLocalizations l10n, {
  FeeControlPaymentFilter? active,
  ValueChanged<FeeControlPaymentFilter>? onSituation,
}) {
  final total = breakdown.total;
  return [
    EteeloKpiCardData(
      label: l10n.feeControlSummaryStudents,
      value: total,
      accent: AppColors.bleuArdoise,
      accentSoft: AppColors.billingHelpSurface,
      icon: Icons.groups_outlined,
      selected: active == FeeControlPaymentFilter.all,
      onTap: onSituation == null
          ? null
          : () => onSituation(FeeControlPaymentFilter.all),
    ),
    // Les trois autres cartes portent les libellés de statut de créance du
    // détail Facturation : « Payé » / « Partiel » / « À régler ». Un même état
    // ne doit pas changer de nom d'un écran à l'autre.
    _statusCard(
      count: breakdown.settled,
      total: total,
      status: StudentChargeStatus.paid,
      filter: FeeControlPaymentFilter.settled,
      active: active,
      onSituation: onSituation,
      l10n: l10n,
    ),
    _statusCard(
      count: breakdown.partial,
      total: total,
      status: StudentChargeStatus.partial,
      filter: FeeControlPaymentFilter.partial,
      active: active,
      onSituation: onSituation,
      l10n: l10n,
    ),
    _statusCard(
      count: breakdown.none,
      total: total,
      status: StudentChargeStatus.due,
      filter: FeeControlPaymentFilter.none,
      active: active,
      onSituation: onSituation,
      l10n: l10n,
    ),
  ];
}

/// La cinquième carte : **ce qui est rentré**, et sur quoi.
///
/// Elle ne filtre rien — un montant n'est pas une situation — et elle ne somme
/// jamais deux devises : en sélection mixte, chaque devise prend sa ligne, et
/// la sous-ligne fait de même pour l'attendu.
EteeloKpiCardData feeControlCollectedCard({
  required MoneyBag collected,
  required MoneyBag expected,
  required AppLocalizations l10n,
}) => EteeloKpiCardData(
  label: l10n.feeControlSummaryCollected,
  valueLines: _lines(collected),
  subline: l10n.feeControlSummaryCollectedOn(_lines(expected).join(' · ')),
  accent: AppColors.vertSavane,
  accentSoft: AppColors.enrollmentStatsCardSurface,
  icon: Icons.savings_outlined,
);

/// Un sac vide s'écrit « — » : « aucune créance » n'est pas « zéro dollar ».
List<String> _lines(MoneyBag bag) => bag.isEmpty
    ? const ['—']
    : [for (final entry in bag.entries) MoneyFormat.format(entry)];

EteeloKpiCardData _statusCard({
  required int count,
  required int total,
  required StudentChargeStatus status,
  required FeeControlPaymentFilter filter,
  required FeeControlPaymentFilter? active,
  required ValueChanged<FeeControlPaymentFilter>? onSituation,
  required AppLocalizations l10n,
}) {
  final visuals = status.visuals;
  return EteeloKpiCardData(
    label: status.localizedLabel(l10n),
    value: count,
    percent: feeSharePercent(count, total),
    accent: visuals.color,
    accentSoft: visuals.soft,
    icon: visuals.icon,
    selected: active == filter,
    onTap: onSituation == null ? null : () => onSituation(filter),
  );
}
