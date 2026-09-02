import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_chart_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que les versements de la fenêtre ont **éteint**, dans une devise de
/// **créance**, poste par poste.
///
/// ⚠️ **Une autre unité que le tiroir.** Depuis qu'un parent règle 50 USD en
/// tendant 115 000 FC, ces montants ne s'additionnent pas à ceux de la bande
/// KPI et ne s'y recoupent pas ligne à ligne : le même versement pèse dans le
/// bloc CDF de l'encaisse et dans le bloc USD d'ici. Le titre de la carte le
/// dit — c'est la seule chose qui empêche de lire un total commun là où il n'en
/// existe aucun.
///
/// **Un montant, et rien d'autre** : ni attendu, ni reste dû, ni taux. Ce qu'il
/// reste à recouvrer sur un poste est la question de l'onglet d'à côté.
class FinanceTillImputationSection extends StatelessWidget {
  final TillImputation imputation;

  const FinanceTillImputationSection({super.key, required this.imputation});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final symbol = MoneyFormat.symbolOf(imputation.currency);
    // Les décimales se décident sur la DEVISE, jamais sur la valeur : 425,00 \$
    // ne doit pas se rendre « 425 » sous un titre qui annonce des dollars,
    // pendant que les cartes dessous portent leurs centimes.
    final total = MoneyFormat.format(
      Money.parse(imputation.total, imputation.currency),
    );

    return FinanceStatsChartCard(
      title: l10n.financeTillImputationCardTitle(symbol),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.financeTillImputationTotal(total),
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          if (imputation.byFeeCode.isEmpty)
            FinanceStatsEmptyState(
              message: l10n.financeStatsNoData,
              hint: l10n.financeStatsNoDataHint,
              semanticLabel: l10n.financeStatsEmptyA11yLabel,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth =
                    constraints.maxWidth >=
                        AppBreakpoints.financeStatsFeeTypeThreeColMin
                    ? (constraints.maxWidth - AppDimensions.spacingM * 2) / 3
                    : constraints.maxWidth >=
                          AppBreakpoints.financeStatsFeeTypeTwoColMin
                    ? (constraints.maxWidth - AppDimensions.spacingM) / 2
                    : constraints.maxWidth;

                return Semantics(
                  container: true,
                  label: l10n.financeTillImputationSectionA11yLabel(symbol),
                  child: Wrap(
                    spacing: AppDimensions.spacingM,
                    runSpacing: AppDimensions.spacingM,
                    children: [
                      for (final item in imputation.byFeeCode)
                        SizedBox(
                          width: cardWidth,
                          child: _TillFeeCodeCard(item: item),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TillFeeCodeCard extends StatelessWidget {
  final TillFeeCodeAmount item;

  const _TillFeeCodeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amount = formatMonetaryAmount(item.amount / 100);

    return Semantics(
      container: true,
      label: l10n.financeTillFeeCodeAmountA11yLabel(item.label, amount),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.spacingM),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.bleuArdoise,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                amount,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
