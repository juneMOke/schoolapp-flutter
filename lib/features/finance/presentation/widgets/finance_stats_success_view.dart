import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_evolution_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_fee_type_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_kpi_band.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le tableau de bord financier — **des indicateurs communs, des graphiques par
/// devise**.
///
/// ## Ce qui fusionne et ce qui se répète
///
/// Les quatre cartes du haut portent toutes les devises à la fois, une ligne
/// chacune : « combien est rentré » est une seule question, et y répondre en
/// deux cartes homonymes séparées par un écran de graphiques obligeait à faire
/// défiler pour lire un chiffre. Elles ne s'additionnent pas pour autant — cf.
/// [FinanceStatsKpiBand].
///
/// Les graphiques, eux, restent un jeu complet par devise. Ils sont faits pour
/// être lus côte à côte, et c'est la comparaison qui a de la valeur : un
/// sélecteur cacherait la moitié du pilotage derrière un clic. L'axe du temps
/// étant garanti identique d'un bloc à l'autre, les graphiques empilés
/// s'alignent naturellement.
///
/// **Jamais deux devises sur un même axe vertical** : l'écart d'échelle est de
/// ×2 800, et une courbe en francs écraserait une courbe en dollars jusqu'à
/// l'illisible.
///
/// À une seule devise, le rendu est celui d'avant — l'en-tête de devise ne
/// paraît que lorsqu'il y a quelque chose à distinguer, et les cartes gardent
/// leur ligne unique.
class FinanceStatsSuccessView extends StatelessWidget {
  final FinanceRecovery stats;

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
        // Les INDICATEURS en tête, toutes devises sur les mêmes quatre cartes :
        // « ce qui est rentré » est une question unique, et la répéter par
        // devise obligeait à faire défiler entre deux cartes homonymes.
        FinanceStatsKpiBand(blocks: stats.byCurrency),
        const SizedBox(height: AppDimensions.spacingL),
        for (final block in stats.byCurrency) ...[
          if (showCurrencyHeadings)
            _CurrencyHeading(currency: block.currency, l10n: l10n),
          // Rien n'a été facturé NI encaissé dans cette devise : deux
          // graphiques plats et une répartition vide ne disent pas ce qu'une
          // phrase dit. Le serveur garde ces devises à zéro plutôt que de les
          // omettre — leur absence se lirait comme une école qui aurait cessé
          // de facturer dedans — donc le cas arrive à l'écran.
          //
          // ⚠️ Un bloc `attendu > 0, encaissé = 0` n'est PAS sans mouvement :
          // il porte une créance entière à recouvrer, et c'est exactement ce
          // que cet onglet doit montrer. La distinction vit sur l'entité.
          if (block.hasNoMovement)
            _CurrencyNoMovement(l10n: l10n)
          else
            // Sur grand écran, Évolution et Répartition par frais se juxtaposent
            // pour occuper l'espace (flex 2:3 → la répartition garde ≥2 colonnes) ;
            // en dessous, elles s'empilent verticalement.
            LayoutBuilder(
              builder: (context, constraints) {
                final evolution = FinanceStatsEvolutionSection(
                  evolution: block.monthlyCollected,
                );
                final feeType = FinanceStatsFeeTypeSection(
                  items: block.byFeeCode,
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

/// Ce qu'on affiche à la place des graphiques d'une devise dormante.
///
/// Discret à dessein : la devise garde sa place dans la bande KPI, ses
/// montants à zéro y sont justes, et cette ligne dit seulement pourquoi il n'y
/// a rien à tracer en dessous.
class _CurrencyNoMovement extends StatelessWidget {
  final AppLocalizations l10n;

  const _CurrencyNoMovement({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '${l10n.financeStatsCurrencyNoMovement}. '
          '${l10n.financeStatsCurrencyNoMovementRecovery}',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppDimensions.spacingM),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.savings_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.financeStatsCurrencyNoMovement,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      l10n.financeStatsCurrencyNoMovementRecovery,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
