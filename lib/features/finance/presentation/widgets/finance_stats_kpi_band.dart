import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bande KPI du tableau de bord Finances — **toutes les devises sur la même
/// carte**.
///
/// Réutilise le composant DS partagé [EteeloKpiBand]/`KpiCard` — même rendu en
/// cartes et même responsivité (grille auto-fill, aucun scroll horizontal) que
/// le tableau de bord Inscription.
///
/// ## Une carte, une ligne par devise
///
/// Les indicateurs descendent du serveur par devise, et ils s'affichaient bloc
/// par bloc : « Encaissé » en dollars en haut de l'écran, « Encaissé » en
/// francs plus bas, chacun juste mais seul. Lire ce qui est rentré demandait de
/// faire défiler entre deux cartes portant le même intitulé.
///
/// Elles n'en font plus qu'une : 425,00 $ **et** 90 000 FC, l'un sous l'autre.
/// Ils ne sont toujours pas additionnés — leur total n'existe pas, il
/// demanderait un taux de change qui bouge alors qu'aucun argent n'a bougé.
/// L'ordre est celui du serveur, le même que celui des sections qui suivent.
///
/// Les **graphiques**, eux, restent par devise : l'écart d'échelle est de
/// ×2 800 et une courbe en francs écraserait une courbe en dollars.
///
/// À une seule devise, le rendu est **exactement** celui d'avant — une ligne,
/// et la part du total en pastille.
class FinanceStatsKpiBand extends StatelessWidget {
  /// Les blocs du serveur, dans leur ordre — le même que celui des sections
  /// qui suivent.
  final List<RecoveryCurrencyBlock> blocks;

  const FinanceStatsKpiBand({super.key, required this.blocks})
    : assert(
        blocks.length > 0,
        'FinanceStatsKpiBand : aucun bloc à afficher. Quatre cartes vides ne '
        'disent pas « aucun mouvement » — la vue rend son état vide avant.',
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      container: true,
      label: l10n.financeStatsKpiBandA11yLabel,
      child: EteeloKpiBand(
        cards: [
          EteeloKpiCardData(
            label: l10n.financeStatsKpiCollected,
            valueLines: _money((kpis) => kpis.collected),
            accent: AppColors.feeStatusPaid,
            accentSoft: AppColors.feeStatusPaidSoft,
            icon: Icons.payments_rounded,
          ),
          EteeloKpiCardData(
            label: l10n.financeStatsKpiExpected,
            valueLines: _money((kpis) => kpis.expected),
            percent: _soleShare((kpis) => kpis.expected),
            accent: AppColors.bleuArdoise,
            accentSoft: AppColors.billingHelpSurface,
            icon: Icons.receipt_long_rounded,
          ),
          EteeloKpiCardData(
            label: l10n.financeStatsKpiOutstanding,
            valueLines: _money((kpis) => kpis.outstanding),
            percent: _soleShare((kpis) => kpis.outstanding),
            accent: AppColors.feeStatusDue,
            accentSoft: AppColors.feeStatusDueSoft,
            icon: Icons.pending_actions_rounded,
          ),
          EteeloKpiCardData(
            label: l10n.financeStatsKpiCollectionRate,
            valueLines: _rates(l10n),
            accent: AppColors.feeStatusPartial,
            accentSoft: AppColors.feeStatusPartialSoft,
            icon: Icons.percent_rounded,
          ),
        ],
      ),
    );
  }

  /// Un montant par devise, dans l'ordre des blocs.
  ///
  /// **L'ordre des blocs, et rien d'autre.** Une première version rangeait ces
  /// lignes-ci par [MoneyBag] — donc par code de devise croissant — pendant que
  /// les taux, eux, suivaient l'ordre reçu. Les deux coïncident tant que le
  /// serveur trie, et le jour où il ne trierait plus, la deuxième ligne de
  /// « Total encaissé » et la deuxième ligne du taux auraient parlé de deux
  /// devises différentes, sans que rien ne le signale. Un écran de pilotage ne
  /// se repose pas sur une promesse qu'il ne vérifie pas : ici tout descend de
  /// la même liste, cartes et graphiques compris.
  List<String> _money(int Function(FinanceKpis kpis) pick) => [
    for (final block in blocks)
      MoneyFormat.format(Money.parse(pick(block.kpis), block.currency)),
  ];

  /// Le taux de recouvrement, qui ne se moyenne pas davantage que les montants.
  ///
  /// À plusieurs devises chaque ligne dit LAQUELLE elle commente : deux
  /// pourcentages nus empilés ne se rattacheraient à rien.
  ///
  /// **« Sans objet » quand rien n'était attendu.** Le serveur rend alors
  /// `100`, qui se lit « rien ne manque » et non « tout a été recouvré » — et
  /// les devises dormantes sont désormais renvoyées à zéro plutôt qu'absentes,
  /// donc le cas se présente à l'écran, pas seulement en théorie.
  List<String> _rates(AppLocalizations l10n) {
    if (blocks.length == 1) {
      final kpis = blocks.single.kpis;
      return [
        if (kpis.hasNoExpectation)
          l10n.financeStatsRateNotApplicable
        else
          '${kpis.collectionRate}%',
      ];
    }
    return [
      for (final block in blocks)
        if (block.kpis.hasNoExpectation)
          l10n.financeStatsRateNotApplicableForCurrency(
            MoneyFormat.symbolOf(block.currency),
          )
        else
          l10n.financeStatsKpiRateForCurrency(
            block.kpis.collectionRate,
            MoneyFormat.symbolOf(block.currency),
          ),
    ];
  }

  /// Part du total facturé par type de frais — la pastille en haut de carte.
  ///
  /// `null` dans deux cas, et la pastille disparaît alors :
  ///
  /// - **deux devises** : la carte n'a qu'une pastille, et un pourcentage
  ///   unique posé sur deux montants désignerait l'un des deux sans le dire ;
  /// - **rien à rapporter** : sans répartition par type de frais, il n'y a pas
  ///   de total dont on soit une part. La pastille affichait « 0 % », ce qui se
  ///   lit comme un résultat — « rien n'a été facturé sur ces postes » — quand
  ///   elle voulait dire qu'on ne sait pas.
  int? _soleShare(int Function(FinanceKpis kpis) pick) {
    if (blocks.length != 1) return null;
    final block = blocks.single;
    final total = block.byFeeCode.fold<int>(
      0,
      (sum, item) => sum + item.expected,
    );
    if (total <= 0) return null;
    return ((pick(block.kpis) * 100) / total).round();
  }
}
