import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// État « aucun résultat » du Contrôle des frais.
///
/// Réutilise le composant commun [EteeloEmptyResult], comme la Facturation.
/// La [description] est fournie par l'appelant : « aucun élève de cette classe
/// ne porte ce frais » et « personne ne correspond au statut demandé » sont deux
/// constats différents, et confondre les deux enverrait chercher une erreur de
/// saisie là où il n'y a qu'une grille incomplète.
class FeeControlResultsEmptyState extends StatelessWidget {
  final List<String> criteria;
  final String description;
  final VoidCallback? onReset;

  const FeeControlResultsEmptyState({
    super.key,
    required this.description,
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
      label: l10n.feeControlEmptyTitle,
      description: description,
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
