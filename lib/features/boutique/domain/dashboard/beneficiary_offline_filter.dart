import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/beneficiaries_query.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_beneficiaries_page.dart';

/// Filtre **hors ligne** la page en cache — la première, sans filtre — pour une
/// recherche par classe ou par nom.
///
/// Le filtre par article, lui, **ne se rejoue pas** : le serveur restreint
/// alors aussi le contenu et les montants de chaque élève à l'article choisi,
/// et le cache ne porte pas le montant article par article. Répondre quand
/// même afficherait des totaux qui mentent sur la question posée.
abstract final class BeneficiaryOfflineFilter {
  /// `null` quand la question ne peut pas se poser au cache.
  static BoutiqueBeneficiariesPage? apply(
    BoutiqueBeneficiariesPage cached,
    BeneficiariesQuery query,
  ) {
    if (query.articleId != null || query.page > 0) return null;
    final items = [
      for (final item in cached.items)
        if ((query.classId == null || item.classId == query.classId) &&
            SearchNormalizationHelper.contains(item.fullName, query.search))
          item,
    ];
    return BoutiqueBeneficiariesPage(
      // Le cache ne garde qu'une page : le compte est celui de ce qu'il montre,
      // et « Voir les n élèves » ne promet rien qu'il ne puisse tenir.
      totalElements: items.length,
      page: 0,
      size: items.length,
      classes: cached.classes,
      walkInLineCount: cached.walkInLineCount,
      items: items,
      cachedAt: cached.cachedAt,
    );
  }
}
