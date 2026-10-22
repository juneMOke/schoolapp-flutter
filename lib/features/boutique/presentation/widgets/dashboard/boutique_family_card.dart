import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_bar_rows.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_currency_stats.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_family_style.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Par famille » — ce qu'on vend, famille par famille, dans la devise
/// détaillée. Une famille sans vente n'est pas affichée.
class BoutiqueFamilyCard extends StatelessWidget {
  final BoutiqueCurrencyStats block;

  /// La barre la plus courte reste visible : un 6 % de la plus longue.
  static const double _minimumFraction = 0.06;

  const BoutiqueFamilyCard({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final families = [
      for (final f in block.families)
        if (f.amount > 0) f,
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    final total = families.fold<int>(0, (sum, f) => sum + f.amount);

    return EteeloStatsCard(
      title: l10n.boutiqueDashboardFamiliesTitle,
      subtitle: l10n.boutiqueDashboardFamiliesSubtitle,
      icon: Icons.category_outlined,
      iconColor: AppColors.bleuArdoise,
      child: EteeloBarRows(
        // Proportionnelle au plus gros montant, pas au total.
        scale: EteeloBarRowsScale.byMax,
        minimumFraction: _minimumFraction,
        rows: [
          for (final f in families)
            EteeloBarRow(
              label: f.family == null
                  ? l10n.boutiqueDashboardFamilyUnknown
                  : BoutiqueFamilyStyle.labelOf(f.family, l10n),
              caption: l10n.boutiqueDashboardFamilyMeta(
                total == 0 ? 0 : (f.amount * 100 / total).round(),
                f.quantity,
              ),
              value: f.amount,
              valueLabel: MoneyFormat.format(
                Money.parse(f.amount, block.currency),
              ),
              color: BoutiqueFamilyStyle.accentOf(f.family),
            ),
        ],
      ),
    );
  }
}
