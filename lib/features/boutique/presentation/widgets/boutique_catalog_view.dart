import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_family_style.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_article_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le catalogue : une recherche, cinq puces exclusives, puis des groupes par
/// famille.
///
/// **Le catalogue n'est pas une grille plate.** Il est découpé par famille, dans
/// l'ordre de l'énumération — jamais alphabétique, jamais par volume de ventes.
/// Passé quelques dizaines d'articles, c'est la seule navigation praticable au
/// guichet.
class BoutiqueCatalogView extends StatelessWidget {
  final Map<ArticleFamily, List<BoutiqueArticle>> groups;

  /// Quantité au panier, par identifiant d'article.
  final int Function(String articleId) quantityOf;

  /// Somme des quantités du panier, par famille — le badge « n au panier » de
  /// l'intitulé de groupe.
  final int Function(ArticleFamily family) cartCountOfFamily;

  final void Function(BoutiqueArticle article) onArticleTap;

  const BoutiqueCatalogView({
    super.key,
    required this.groups,
    required this.quantityOf,
    required this.cartCountOfFamily,
    required this.onArticleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groups.entries) ...[
          _GroupHeader(
            family: entry.key,
            articleCount: entry.value.length,
            cartCount: cartCountOfFamily(entry.key),
          ),
          const SizedBox(height: 10),
          _ArticleGrid(
            articles: entry.value,
            quantityOf: quantityOf,
            onArticleTap: onArticleTap,
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

/// La grille de cartes.
///
/// `minmax(190, 1fr)` de la spec, rendu en `SliverGridDelegate` : **190 est le
/// minimum pour que « Duplicata de bulletin » tienne sur deux lignes**. En
/// dessous, le libellé se tronque et le guichet ne distingue plus deux actes
/// administratifs voisins.
class _ArticleGrid extends StatelessWidget {
  final List<BoutiqueArticle> articles;
  final int Function(String articleId) quantityOf;
  final void Function(BoutiqueArticle article) onArticleTap;

  const _ArticleGrid({
    required this.articles,
    required this.quantityOf,
    required this.onArticleTap,
  });

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 260,
      // 148 et non 128 : la spec donne 128 comme **minimum** de carte, et
      // `mainAxisExtent` en ferait une hauteur FIXE — trop juste dès qu'un
      // libellé prend deux lignes, ce qui est le cas nominal (« Duplicata de
      // bulletin »). Une carte qui déborde de six pixels raye son propre prix.
      mainAxisExtent: 148,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    ),
    itemCount: articles.length,
    itemBuilder: (context, index) {
      final article = articles[index];
      return BoutiqueArticleCard(
        article: article,
        quantityInCart: quantityOf(article.id),
        onTap: () => onArticleTap(article),
      );
    },
  );
}

/// L'intitulé d'un groupe : pastille, nom, compte, et ce que la famille pèse
/// dans le panier.
class _GroupHeader extends StatelessWidget {
  final ArticleFamily family;
  final int articleCount;
  final int cartCount;

  const _GroupHeader({
    required this.family,
    required this.articleCount,
    required this.cartCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = BoutiqueFamilyStyle.accentOf(family);
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Text(
          BoutiqueFamilyStyle.labelOf(family, l10n),
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppColors.bleuProfond,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Text(
          l10n.boutiqueArticleCount(articleCount),
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        // Seulement si la famille pèse dans le panier : un « 0 au panier »
        // occuperait la place sans rien dire.
        if (cartCount > 0) ...[
          const SizedBox(width: AppDimensions.spacingS),
          Text(
            l10n.boutiqueInCartBadge(cartCount),
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(width: AppDimensions.spacingS),
        // Le filet comble jusqu'au bord droit : il sépare les groupes sans
        // ajouter de bloc.
        const Expanded(child: Divider(height: 1)),
      ],
    );
  }
}
