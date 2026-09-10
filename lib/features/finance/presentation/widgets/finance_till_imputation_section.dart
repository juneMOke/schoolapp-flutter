import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_bar_rows.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/till_fee_code_palette.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_chart_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que les versements de la fenêtre ont **éteint**, poste par poste.
///
/// ⚠️ **Une autre unité que le tiroir.** Depuis qu'un parent règle 50 USD en
/// tendant 115 000 FC, ces montants ne s'additionnent pas à ceux de la bande de
/// caisses et ne s'y recoupent pas ligne à ligne : le même versement pèse dans
/// le bloc CDF de l'encaisse et dans le bloc USD d'ici. **Une carte par devise
/// de créance**, chacune nommant la sienne — c'est ce qui empêche de lire un
/// total commun là où il n'en existe aucun. Deux gardes le rendent nécessaire :
/// « Par source » la précède immédiatement et compte, elle, en devise **reçue**
/// ; et sa jumelle est désormais **à côté d'elle** sur la même ligne, où deux
/// titres qui ne nommeraient pas leur devise se liraient comme deux moitiés
/// d'un même total.
///
/// **Un montant, et rien d'autre** : ni attendu, ni reste dû, ni taux. Ce qu'il
/// reste à recouvrer sur un poste est la question de l'onglet d'à côté.
///
/// ## Des barres, et ce qu'elles mesurent
///
/// La barre montre la part **du plus fort poste** : la carte se lit comme un
/// classement — « à quoi l'argent est allé, du plus au moins ». Le pourcentage
/// écrit dessous, lui, est la part **du total de cette carte**. Les deux disent
/// des choses différentes et c'est voulu : la barre porte le rang, le chiffre
/// porte la proportion.
class FinanceTillImputationSection extends StatelessWidget {
  final TillImputation imputation;

  /// La plus petite barre visible, en fraction — la spec écrit
  /// `max(6%, value/max × 100%)`. Un poste réel mais marginal doit se voir.
  static const double _minimumBarFraction = 0.06;

  const FinanceTillImputationSection({super.key, required this.imputation});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final symbol = MoneyFormat.symbolOf(imputation.currency);
    // Les décimales se décident sur la DEVISE, jamais sur la valeur : 425,00 $
    // ne doit pas se rendre « 425 » sous un titre qui annonce des dollars.
    final total = MoneyFormat.format(
      Money.parse(imputation.total, imputation.currency),
    );

    // Aucune ligne à zéro, et le plus fort en tête : la carte est un classement
    // de ce qui a été éteint, pas un catalogue des postes de l'école.
    final lines = imputation.byFeeCode.where((line) => line.amount > 0).toList()
      ..sort((a, b) {
        final byAmount = b.amount.compareTo(a.amount);
        // Le code départage à montant égal, pour que deux rendus successifs de
        // la même fenêtre ne s'échangent pas deux lignes.
        return byAmount != 0 ? byAmount : a.code.compareTo(b.code);
      });

    return FinanceStatsChartCard(
      title: l10n.financeTillImputationCardTitle(symbol),
      // L'icône que Facturation donne déjà à ses créances : c'est le même objet
      // qu'on regarde ici, éteint plutôt qu'ouvert.
      icon: Icons.receipt_long_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.financeTillImputationTotal(total),
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textSecondary,
              fontFeatures: AppTextStyles.tabularFigures,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          // ⚠️ **La carte nomme son unité**, et rien dans sa mise en page ne
          // le dit à sa place : « Par source » la précède en devise reçue, sa
          // jumelle la jouxte en une autre devise de créance. Sans cette
          // mention, ce voisinage invite à additionner ce qui ne s'additionne
          // pas.
          Text(
            l10n.financeTillImputationCardHint,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          if (lines.isEmpty)
            FinanceStatsEmptyState(
              message: l10n.financeStatsNoData,
              hint: l10n.financeStatsNoDataHint,
              semanticLabel: l10n.financeStatsEmptyA11yLabel,
            )
          else ...[
            Semantics(
              container: true,
              label: l10n.financeTillImputationSectionA11yLabel(symbol),
              child: EteeloBarRows(
                // Le rang se lit sur la barre, la proportion sur le chiffre.
                scale: EteeloBarRowsScale.byMax,
                minimumFraction: _minimumBarFraction,
                rows: [
                  for (final line in lines)
                    EteeloBarRow(
                      label: line.label,
                      value: line.amount,
                      valueLabel: MoneyFormat.format(
                        Money.parse(line.amount, imputation.currency),
                      ),
                      // La teinte repère le poste ; le libellé le nomme. Un
                      // code sans famille écrite prend le gris neutre plutôt
                      // qu'une couleur devinée.
                      color: tillFeeCodeAccent(line.code),
                      semanticsLabel: l10n.financeTillFeeCodeAmountA11yLabel(
                        line.label,
                        MoneyFormat.format(
                          Money.parse(line.amount, imputation.currency),
                        ),
                      ),
                      // Pas de `onTap` : le poste n'a pas d'écran de
                      // destination, et promettre un geste qui n'existe pas est
                      // pire que de n'en promettre aucun.
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            _ShareLegend(lines: lines, total: imputation.total, l10n: l10n),
          ],
        ],
      ),
    );
  }
}

/// « n % du total » par poste — **la part dans CETTE caisse**, pas dans
/// l'encaissement global.
///
/// Les parts peuvent faire 99 ou 101 : ce sont des arrondis entiers, et il ne
/// faut **jamais dériver un montant d'un pourcentage affiché**.
class _ShareLegend extends StatelessWidget {
  final List<TillFeeCodeAmount> lines;
  final int total;
  final AppLocalizations l10n;

  const _ShareLegend({
    required this.lines,
    required this.total,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();

    // ⚠️ **Chaque entrée est bornée à la largeur disponible.** Sans ça, un
    // libellé de poste un peu long débordait la carte sur un téléphone étroit
    // — mesuré à 320 dp — parce qu'une `Row` de taille minimale dans un `Wrap`
    // n'est bornée par rien.
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: AppDimensions.spacingM,
        runSpacing: AppDimensions.spacingXS,
        children: [
          for (final line in lines)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: tillFeeCodeAccent(line.code),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingXS),
                  Flexible(
                    child: Text(
                      l10n.financeTillImputationShare(
                        line.label,
                        (line.amount * 100 / total).round(),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // Une colonne de parts, une par poste : les « 100 % » et
                      // les « 7 % » s'alignent, ou la légende se relit ligne à
                      // ligne.
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontFeatures: AppTextStyles.tabularFigures,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
