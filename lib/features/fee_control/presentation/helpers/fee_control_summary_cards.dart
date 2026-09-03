import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre cartes d'une synthèse de contrôle : élèves concernés, puis
/// soldés / partiels / sans paiement.
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
List<EteeloKpiCardData> feeControlSummaryCards(
  FeeControlBreakdown breakdown,
  AppLocalizations l10n,
) {
  final total = breakdown.total;
  return [
    EteeloKpiCardData(
      label: l10n.feeControlSummaryStudents,
      value: total,
      accent: AppColors.bleuArdoise,
      accentSoft: AppColors.billingHelpSurface,
      icon: Icons.groups_outlined,
    ),
    // Les trois autres cartes portent les libellés de statut de créance du
    // détail Facturation : « Payé » / « Partiel » / « À régler ». Un même état
    // ne doit pas changer de nom d'un écran à l'autre.
    _statusCard(
      count: breakdown.settled,
      total: total,
      status: StudentChargeStatus.paid,
      l10n: l10n,
    ),
    _statusCard(
      count: breakdown.partial,
      total: total,
      status: StudentChargeStatus.partial,
      l10n: l10n,
    ),
    _statusCard(
      count: breakdown.none,
      total: total,
      status: StudentChargeStatus.due,
      l10n: l10n,
    ),
  ];
}

EteeloKpiCardData _statusCard({
  required int count,
  required int total,
  required StudentChargeStatus status,
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
  );
}
