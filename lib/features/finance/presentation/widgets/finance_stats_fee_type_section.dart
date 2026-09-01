import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_chart_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FinanceStatsFeeTypeSection extends StatelessWidget {
  final List<FeeTypeItem> items;

  const FinanceStatsFeeTypeSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FinanceStatsChartCard(
      title: l10n.financeStatsSectionFeeTypeDistribution,
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
                  label: l10n.financeStatsFeeTypeSectionA11yLabel,
                  child: Wrap(
                    spacing: AppDimensions.spacingM,
                    runSpacing: AppDimensions.spacingM,
                    children: [
                      for (final item in items)
                        SizedBox(
                          width: cardWidth,
                          child: _FeeTypeCard(item: item),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _FeeTypeCard extends StatelessWidget {
  final FeeTypeItem item;

  const _FeeTypeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Le libellé descend du serveur — « Minerval » pour `TUITION` — et le
    // mapping retombe déjà sur le code si le serveur n'envoie rien. La table
    // locale de vingt-trois traductions n'est plus appelée ICI ; elle reste en
    // place pour ses trois autres appelants (désignation d'une créance, options
    // du contrôle des frais, étape « Frais scolaires » du wizard), qui ne
    // reçoivent, eux, aucun libellé du serveur.
    final label = item.label;
    final semanticLabel = l10n.financeStatsFeeTypeItemA11yLabel(
      label,
      _formatCents(item.collected),
      _formatCents(item.expected),
      _formatCents(item.outstanding),
      item.collectionRate,
    );

    return Semantics(
      container: true,
      label: semanticLabel,
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
                label,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.bleuArdoise,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                l10n.financeStatsFeeTypeCollected(_formatCents(item.collected)),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                l10n.financeStatsFeeTypeExpected(_formatCents(item.expected)),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              // Ce qui rend la ligne lisible quand l'encaissé dépasse
              // l'attendu : l'excédent est un arriéré d'un AUTRE exercice qui
              // se solde, et ce chiffre-ci dit ce que celui-là doit encore.
              Text(
                l10n.financeStatsFeeTypeOutstanding(
                  _formatCents(item.outstanding),
                ),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.spacingXS),
                child: LinearProgressIndicator(
                  value: item.hasNoExpectation
                      ? 0
                      : item.collectionRate.clamp(0, 100) / 100,
                  minHeight: AppDimensions.financeStatsFeeTypeProgressHeight,
                  backgroundColor: AppColors.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    item.collectionRate >= 70
                        ? AppColors.bleuArdoise
                        : AppColors.warning,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                // Rien n'était attendu : le serveur rend 100, qui se lit « rien
                // ne manque » et non « tout a été recouvré ». Sur un poste
                // dormant, le pourcentage triomphant serait un contresens.
                item.hasNoExpectation
                    ? l10n.financeStatsFeeTypeRateNotApplicable
                    : l10n.financeStatsFeeTypeRate(item.collectionRate),
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

  String _formatCents(int amountInCents) =>
      formatMonetaryAmount(amountInCents / 100);
}
