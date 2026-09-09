import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_chart_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_cash_boxes.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La caisse en train de se charger — **à sa propre silhouette**.
///
/// Le squelette du recouvrement ne convient pas : il pose deux cartes côte à
/// côte, alors que la caisse empile une bande de tuiles, puis un graphique, puis
/// des rangées de barres. Un squelette qui ne ressemble pas à ce qui arrive fait
/// sauter la page sous l'œil, ce qu'il existe précisément pour éviter — il vaut
/// alors à peine mieux qu'un rond qui tourne.
///
/// ## Trois tuiles, et ce que ce nombre suppose
///
/// La bande réelle porte **une tuile par devise, plus le compteur de reçus** :
/// trois pour une école bi-devise, qui est le cas de la spec. On ne connaît pas
/// encore les devises au moment du squelette — c'est tout le problème d'un
/// squelette — donc trois est une **hypothèse**, pas une lecture. Une école qui
/// en aurait davantage verrait ses largeurs se réajuster à l'arrivée des
/// données ; l'ordre et les hauteurs, eux, ne bougent pas.
///
/// ⚠️ **Aucune teinte de devise sur le bord haut.** La tuile réelle porte un
/// bord coloré qui nomme sa caisse ; le squelette prend le gris neutre, parce
/// qu'annoncer « dollars » avant de savoir serait affirmer ce qu'on ignore — et
/// la couleur changerait sous l'œil si l'ordre arrivait autrement.
class FinanceTillLoadingView extends StatelessWidget {
  const FinanceTillLoadingView({super.key});

  /// Les hauteurs des douze barres, en fraction — celles de la spec.
  ///
  /// Fixes et non aléatoires : un squelette qui change de dessin à chaque
  /// rendu attire l'œil sur lui-même, et deux chargements successifs du même
  /// écran se mettraient à différer sans que rien n'ait changé.
  static const List<double> _barFractions = [
    0.42,
    0.58,
    0.30,
    0.74,
    0.52,
    0.88,
    0.64,
    0.46,
    0.70,
    0.36,
    0.60,
    0.80,
  ];

  /// Les quatre rangées de la ventilation, largeurs dégressives.
  static const List<double> _rowFractions = [0.86, 0.64, 0.48, 0.34];

  static const double _chartHeight = 190;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.financeStatsLoadingA11yLabel,
      readOnly: true,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TillSkeletonBoxes(),
            const SizedBox(height: AppDimensions.spacingXL),
            FinanceStatsChartCard.skeleton(
              child: SizedBox(
                height: _chartHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < _barFractions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: EteeloSkeletonBox(
                          height: _chartHeight * _barFractions[i],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            FinanceStatsChartCard.skeleton(
              child: LayoutBuilder(
                builder: (context, constraints) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final fraction in _rowFractions) ...[
                      if (fraction != _rowFractions.first)
                        const SizedBox(height: AppDimensions.spacingM),
                      EteeloSkeletonBox(
                        width: constraints.maxWidth * fraction,
                        height: 14,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La bande de tuiles, aux largeurs de la vraie bande.
class _TillSkeletonBoxes extends StatelessWidget {
  const _TillSkeletonBoxes();

  /// Deux caisses, comme la spec. Voir la note d'hypothèse ci-dessus.
  static const int _cashBoxes = 2;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppDimensions.spacingM;
        const gutters = spacing * _cashBoxes;
        const basisTotal =
            FinanceTillCashBoxes.cashBoxBasis * _cashBoxes +
            FinanceTillCashBoxes.counterBasis;

        final fitsOneRow = constraints.maxWidth >= basisTotal + gutters;
        final available = constraints.maxWidth - gutters;
        final cashWidth = fitsOneRow
            ? (available * FinanceTillCashBoxes.cashBoxBasis / basisTotal)
                  .floorToDouble()
            : constraints.maxWidth;
        final counterWidth = fitsOneRow
            ? (available * FinanceTillCashBoxes.counterBasis / basisTotal)
                  .floorToDouble()
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < _cashBoxes; i++)
              _SkeletonTile(width: cashWidth),
            _SkeletonTile(width: counterWidth),
          ],
        );
      },
    );
  }
}

/// Une tuile : médaillon, libellé, montant — **en blocs**.
class _SkeletonTile extends StatelessWidget {
  final double width;

  const _SkeletonTile({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        // Gris neutre, jamais la teinte d'une devise qu'on ne connaît pas
        // encore.
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const EteeloSkeletonBox(width: 26, height: 26),
              const SizedBox(width: AppDimensions.spacingS),
              EteeloSkeletonBox(width: width * 0.45, height: 12),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          EteeloSkeletonBox(width: width * 0.64, height: 22),
        ],
      ),
    );
  }
}
