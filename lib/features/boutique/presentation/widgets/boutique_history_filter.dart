import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sales_history_period.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre fenêtres, en bascule exclusive.
///
/// **Une seule à la fois, jamais deux cases à cocher** : « aujourd'hui ET cette
/// semaine » n'a pas de sens, et l'offrir laisserait composer une fenêtre qui
/// n'existe pas.
class BoutiqueHistoryFilter extends StatelessWidget {
  final SalesHistoryPeriod selected;
  final ValueChanged<SalesHistoryPeriod> onChanged;

  /// Inerte pendant la lecture : changer de fenêtre sous une requête en vol
  /// laisserait arriver la réponse de la précédente par-dessus.
  final bool enabled;

  const BoutiqueHistoryFilter({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingS,
      children: [
        for (final period in SalesHistoryPeriod.values)
          ChoiceChip(
            label: Text(labelOf(period, l10n)),
            selected: period == selected,
            onSelected: enabled ? (_) => onChanged(period) : null,
            selectedColor: AppColors.terreCuite.withValues(alpha: 0.14),
            side: BorderSide(
              color: period == selected
                  ? AppColors.terreCuite
                  : AppColors.border,
            ),
            labelStyle: TextStyle(
              color: period == selected
                  ? AppColors.terreCuite
                  : AppColors.textPrimary,
              fontWeight: period == selected
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
      ],
    );
  }

  /// Partagé avec le total de la fenêtre, qui NOMME la période qu'il additionne.
  static String labelOf(SalesHistoryPeriod period, AppLocalizations l10n) =>
      switch (period) {
        SalesHistoryPeriod.day => l10n.boutiqueHistoryPeriodDay,
        SalesHistoryPeriod.week => l10n.boutiqueHistoryPeriodWeek,
        SalesHistoryPeriod.month => l10n.boutiqueHistoryPeriodMonth,
        SalesHistoryPeriod.year => l10n.boutiqueHistoryPeriodYear,
      };
}
