import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_chart_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que chaque poste de frais a rapporté dans la fenêtre.
///
/// **Un montant, et rien d'autre** : ni attendu, ni reste dû, ni taux, ni barre
/// de progression. La caisse compte ce qui est entré dans le tiroir ; ce qu'il
/// reste à recouvrer sur ce poste est la question de l'onglet d'à côté, et l'y
/// mêler ferait lire un taux là où le caissier cherche un montant à rapprocher
/// de ses billets.
///
/// ⚠️ La somme de ces montants vaut la moitié **frais**, jamais le total : une
/// vente boutique n'est imputée sur aucune créance, elle n'a donc aucun poste,
/// et sa contribution reste entière dans la carte « Ventes boutique ».
class FinanceTillFeeCodeSection extends StatelessWidget {
  final List<TillFeeCodeAmount> items;

  const FinanceTillFeeCodeSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FinanceStatsChartCard(
      title: l10n.financeTillSectionFeeCodes,
      child: items.isEmpty
          ? FinanceStatsEmptyState(
              message: l10n.financeStatsNoData,
              hint: l10n.financeStatsNoDataHint,
              semanticLabel: l10n.financeStatsEmptyA11yLabel,
            )
          : LayoutBuilder(
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
                  label: l10n.financeTillFeeCodeSectionA11yLabel,
                  child: Wrap(
                    spacing: AppDimensions.spacingM,
                    runSpacing: AppDimensions.spacingM,
                    children: [
                      for (final item in items)
                        SizedBox(
                          width: cardWidth,
                          child: _TillFeeCodeCard(item: item),
                        ),
                    ],
                  ),
                );
              },
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
