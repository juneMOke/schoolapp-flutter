import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
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
///
/// ## Deux issues, jamais un rechargement
///
/// [onWiden] **élargit** la recherche (situation = « Tous ») au lieu de la
/// rejouer : quand un filtre est trop étroit, relancer la même requête ne peut
/// que redonner le même vide. Il ne s'affiche que s'il ferait quelque chose —
/// un bouton inerte apprend à ne plus lire les boutons.
///
/// [onBilling] mène à la Facturation : si personne n'a payé, l'issue utile
/// n'est pas de re-chercher, c'est d'encaisser.
class FeeControlResultsEmptyState extends StatelessWidget {
  final List<String> criteria;
  final String description;

  /// Élargit à « Tous ». `null` quand la situation est déjà « Tous ».
  final VoidCallback? onWiden;

  final VoidCallback? onBilling;

  const FeeControlResultsEmptyState({
    super.key,
    required this.description,
    this.criteria = const <String>[],
    this.onWiden,
    this.onBilling,
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
      primaryAction: onWiden == null
          ? null
          : FilledButton.icon(
              // ⚠️ `minimumSize` : le thème veut ces boutons pleine largeur, et
              // l'hôte les pose dans un `Wrap`.
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppDimensions.minTouchTarget),
              ),
              onPressed: onWiden,
              icon: const Icon(Icons.groups_outlined, size: 16),
              label: Text(l10n.feeControlEmptyWiden),
            ),
      secondaryAction: onBilling == null
          ? null
          : OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, AppDimensions.minTouchTarget),
              ),
              onPressed: onBilling,
              icon: const Icon(Icons.point_of_sale_outlined, size: 16),
              label: Text(l10n.feeControlEmptyBilling),
            ),
      fullWidthCard: true,
    );
  }
}
