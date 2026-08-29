import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_family_style.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_money_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un article du catalogue. **La carte EST le bouton d'ajout** : toute sa
/// surface est tapable, il n'y a pas de « + » séparé.
///
/// Une cible de 128 dp de haut, bien au-delà des 44 dp minimum — au guichet, on
/// vise vite et mal.
class BoutiqueArticleCard extends StatelessWidget {
  final BoutiqueArticle article;

  /// Somme des quantités de **toutes** les lignes portant cet article, pas le
  /// nombre de lignes : trois polos pour trois enfants font « 3 ».
  final int quantityInCart;

  final VoidCallback onTap;

  const BoutiqueArticleCard({
    super.key,
    required this.article,
    required this.quantityInCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = BoutiqueFamilyStyle.accentOf(article.family);

    return Semantics(
      button: true,
      // Le lecteur d'écran annonce ce que l'œil voit : libellé, prix, famille,
      // et ce qui est déjà au panier. Sans le compteur, l'utilisateur non
      // voyant ajouterait un quatrième polo sans savoir qu'il en a trois.
      label: [
        article.label,
        _priceLabel(l10n),
        BoutiqueFamilyStyle.labelOf(article.family, l10n),
        if (quantityInCart > 0) l10n.boutiqueInCartBadge(quantityInCart),
      ].join(', '),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 128),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Medallion(accent: accent, family: article.family),
                    const Spacer(),
                    if (quantityInCart > 0) _CartCounter(count: quantityInCart),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  article.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.bleuProfond,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  article.code,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        _priceLabel(l10n),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.bleuProfond,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // ⚠️ Rendu depuis `showsLevelBadge`, donc depuis
                    // `pricingMode` — JAMAIS d'une comparaison min/max. Un
                    // article à grille dont toutes les cases valent 10 $ porte
                    // le badge ; un article plat à 10 $ ne le porte jamais
                    // (invariant I-1).
                    if (article.showsLevelBadge) ...[
                      const SizedBox(width: AppDimensions.spacingXS),
                      _LevelBadge(
                        accent: accent,
                        label: l10n.boutiqueLevelBadge,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// « 3 $ » sur un prix unique, « 10 $ – 15 $ » sur une grille.
  ///
  /// Une grille dont min et max coïncident affiche **un seul montant** — mais
  /// garde son badge : la fourchette décrit les prix, le badge décrit la règle.
  String _priceLabel(AppLocalizations l10n) {
    final min = article.minPriceInCents;
    final max = article.maxPriceInCents;
    if (min == null || max == null) return '—';
    final currency = article.currency;
    if (min == max) return BoutiqueMoneyFormat.compact(min, currency);
    return l10n.boutiquePriceRange(
      BoutiqueMoneyFormat.compact(min, currency),
      BoutiqueMoneyFormat.compact(max, currency),
    );
  }
}

class _Medallion extends StatelessWidget {
  final Color accent;
  final ArticleFamily? family;

  const _Medallion({required this.accent, required this.family});

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(BoutiqueFamilyStyle.iconOf(family), size: 20, color: accent),
  );
}

/// La pastille de quantité. Terre-cuite comme le bouton d'encaissement : c'est
/// la couleur de ce qui va être payé.
class _CartCounter extends StatelessWidget {
  final int count;

  const _CartCounter({required this.count});

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: const BoxDecoration(
      color: AppColors.terreCuite,
      shape: BoxShape.circle,
    ),
    child: Text(
      '$count',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _LevelBadge extends StatelessWidget {
  final Color accent;
  final String label;

  const _LevelBadge({required this.accent, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: accent),
    ),
  );
}
