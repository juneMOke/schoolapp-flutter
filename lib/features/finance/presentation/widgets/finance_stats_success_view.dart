import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_evolution_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_fee_type_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_kpi_band.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le tableau de bord financier — **un bloc complet par devise**.
///
/// ## Répéter, plutôt qu'un sélecteur
///
/// Les blocs sont faits pour être lus côte à côte, et c'est la comparaison qui a
/// de la valeur : un sélecteur cacherait la moitié du pilotage derrière un clic.
/// L'axe du temps étant garanti identique d'un bloc à l'autre, les graphiques
/// empilés s'alignent naturellement.
///
/// **Jamais deux devises sur un même axe vertical** : l'écart d'échelle est de
/// ×2 800, et une courbe en francs écraserait une courbe en dollars jusqu'à
/// l'illisible.
///
/// À une seule devise, le rendu est celui d'avant — l'en-tête de devise ne
/// paraît que lorsqu'il y a quelque chose à distinguer.
class FinanceStatsSuccessView extends StatelessWidget {
  final FinanceStats stats;

  const FinanceStatsSuccessView({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Aucun argent n'a circulé sur la fenêtre. C'est un état VIDE, pas une
    // erreur — et surtout pas un zéro dans une unité que personne n'a choisie.
    if (stats.byCurrency.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXL),
        child: EteeloEmptyResult(
          label: l10n.financeStatsNoMovementLabel,
          description: l10n.financeStatsNoMovementDescription,
          medallionIcon: Icons.savings_outlined,
        ),
      );
    }

    final showCurrencyHeadings = stats.byCurrency.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in stats.byCurrency) ...[
          if (showCurrencyHeadings)
            _CurrencyHeading(currency: block.currency, l10n: l10n),
          FinanceStatsKpiBand(
            kpis: block.kpis,
            distribution: block.distributionByFeeType,
            currency: block.currency,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          // Sur grand écran, Évolution et Répartition par frais se juxtaposent
          // pour occuper l'espace (flex 2:3 → la répartition garde ≥2 colonnes) ;
          // en dessous, elles s'empilent verticalement.
          LayoutBuilder(
            builder: (context, constraints) {
              final evolution = FinanceStatsEvolutionSection(
                evolution: block.evolution,
              );
              final feeType = FinanceStatsFeeTypeSection(
                distribution: block.distributionByFeeType,
              );
              if (constraints.maxWidth >=
                  AppBreakpoints.financeStatsTwoColMin) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: evolution),
                    const SizedBox(width: AppDimensions.spacingL),
                    Expanded(flex: 3, child: feeType),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  evolution,
                  const SizedBox(height: AppDimensions.spacingL),
                  feeType,
                ],
              );
            },
          ),
          const SizedBox(height: AppDimensions.spacingXL),
        ],
      ],
    );
  }
}

/// Nomme la devise du bloc qui suit.
///
/// N'apparaît qu'à partir de deux devises : sur une école mono-devise, il
/// répéterait une information que chaque montant porte déjà.
class _CurrencyHeading extends StatelessWidget {
  final String currency;
  final AppLocalizations l10n;

  const _CurrencyHeading({required this.currency, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Text(
              l10n.financeStatsCurrencyHeading(MoneyFormat.symbolOf(currency)),
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingS),
            const Expanded(child: Divider(height: 1, color: AppColors.border)),
          ],
        ),
      ),
    );
  }
}
