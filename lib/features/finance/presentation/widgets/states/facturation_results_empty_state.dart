import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// État « aucun résultat » de la liste Facturation.
///
/// Réutilise le composant commun [EteeloEmptyResult] (le même que la liste des
/// inscriptions) ; seul le message est adapté au contexte facturation.
class FacturationResultsEmptyState extends StatelessWidget {
  final List<String> criteria;
  final VoidCallback? onReset;

  const FacturationResultsEmptyState({
    super.key,
    this.criteria = const <String>[],
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasCriteria = criteria.isNotEmpty;

    final criteriaChips = criteria
        .map(
          (item) => Chip(
            label: Text(item),
            backgroundColor: AppColors.surfaceAlt,
            labelStyle: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            side: const BorderSide(color: AppColors.border),
            visualDensity: VisualDensity.compact,
          ),
        )
        .toList(growable: false);

    return EteeloEmptyResult(
      label: l10n.facturationEmptyTitle,
      description: l10n.facturationNoResultsDescription,
      criteriaChips: criteriaChips,
      medallionIcon: Icons.search_off_rounded,
      cornerBadgeIcon: hasCriteria ? Icons.filter_list_rounded : null,
      secondaryAction: onReset == null
          ? null
          : OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.clear),
            ),
      fullWidthCard: true,
    );
  }
}
