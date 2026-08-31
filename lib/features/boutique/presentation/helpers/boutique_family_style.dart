import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que l'écran met derrière une famille d'article : un accent, une icône, un
/// libellé traduit.
///
/// **Ici et nulle part ailleurs.** Trois widgets ont besoin de ces trois
/// choses — la carte, l'intitulé de groupe, la puce de filtre — et trois copies
/// divergeraient au premier ajout de famille, sur une couleur.
///
/// La famille `null` — servie par un serveur plus récent que ce client — reçoit
/// un traitement **neutre**, jamais celui d'une famille existante : la ranger
/// d'office sous « Fournitures » lui donnerait une place et une couleur que
/// personne n'a choisies.
abstract final class BoutiqueFamilyStyle {
  static Color accentOf(ArticleFamily? family) => switch (family) {
    ArticleFamily.uniforme => AppColors.boutiqueUniformeAccent,
    ArticleFamily.fournitures => AppColors.boutiqueFournituresAccent,
    ArticleFamily.activites => AppColors.boutiqueActivitesAccent,
    ArticleFamily.actes => AppColors.boutiqueActesAccent,
    null => AppColors.textMuted,
  };

  static IconData iconOf(ArticleFamily? family) => switch (family) {
    ArticleFamily.uniforme => Icons.checkroom_outlined,
    ArticleFamily.fournitures => Icons.menu_book_outlined,
    ArticleFamily.activites => Icons.directions_walk_outlined,
    ArticleFamily.actes => Icons.description_outlined,
    null => Icons.inventory_2_outlined,
  };

  static String labelOf(ArticleFamily? family, AppLocalizations l10n) =>
      switch (family) {
        ArticleFamily.uniforme => l10n.boutiqueFamilyUniforme,
        ArticleFamily.fournitures => l10n.boutiqueFamilyFournitures,
        ArticleFamily.activites => l10n.boutiqueFamilyActivites,
        ArticleFamily.actes => l10n.boutiqueFamilyActes,
        null => '',
      };
}
