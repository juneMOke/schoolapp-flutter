import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_family_style.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_money_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un article du catalogue, avec son pas d'ajout au pied.
///
/// **La carte n'est plus le bouton.** Toute sa surface l'a été, et le geste
/// n'avait alors pas d'inverse : pour retirer un exemplaire ajouté par erreur,
/// il fallait ouvrir le panier. Le pied porte donc « Ajouter au panier » tant
/// que l'article n'y est pas, puis « − n + » — le même endroit, le même doigt.
///
/// Une cible de 148 dp de haut, bien au-delà des 44 dp minimum — au guichet, on
/// vise vite et mal.
class BoutiqueArticleCard extends StatefulWidget {
  final BoutiqueArticle article;

  /// Somme des quantités de **toutes** les lignes portant cet article, pas le
  /// nombre de lignes : trois polos pour trois enfants font « 3 ».
  final int quantityInCart;

  /// Y a-t-il encore un exemplaire non destiné à un enfant ? C'est le seul que
  /// le pas « − » sache défaire — cf. `BoutiqueCart.removeOneBareArticle`.
  final bool canRemoveOne;

  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const BoutiqueArticleCard({
    super.key,
    required this.article,
    required this.quantityInCart,
    required this.canRemoveOne,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<BoutiqueArticleCard> createState() => _BoutiqueArticleCardState();
}

class _BoutiqueArticleCardState extends State<BoutiqueArticleCard> {
  /// Combien de temps la carte reste soulignée après un ajout.
  ///
  /// Assez pour que l'œil revienne du doigt vers la carte, trop peu pour
  /// ralentir une file : au guichet, les articles s'enchaînent.
  static const Duration _pulse = Duration(milliseconds: 420);

  /// Vrai juste après un ajout — la bordure prend l'accent, le temps de dire
  /// « c'est bien celui-là qui vient d'entrer au panier ».
  bool _justAdded = false;

  @override
  void didUpdateWidget(BoutiqueArticleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sur l'AUGMENTATION seule : un retrait n'a pas à se célébrer, et un
    // rebuild sans changement de compte ne doit rien allumer.
    if (widget.quantityInCart <= oldWidget.quantityInCart) return;
    setState(() => _justAdded = true);
    Future.delayed(_pulse, () {
      if (mounted) setState(() => _justAdded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final article = widget.article;
    final quantityInCart = widget.quantityInCart;
    final accent = BoutiqueFamilyStyle.accentOf(article.family);
    // reduced-motion : la mise en avant devient instantanée plutôt que
    // supprimée — l'information reste, le mouvement disparaît.
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      container: true,
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
        child: AnimatedContainer(
          duration: reducedMotion ? Duration.zero : _pulse,
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 148),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _justAdded ? AppColors.terreCuite : AppColors.border,
              width: _justAdded ? 2 : 1,
            ),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    _LevelBadge(accent: accent, label: l10n.boutiqueLevelBadge),
                  ],
                ],
              ),
              const SizedBox(height: AppDimensions.spacingS),
              // Le pas d'ajout, au pied : « Ajouter au panier » tant que
              // l'article n'y est pas, « − n + » ensuite. Le geste et son
              // inverse au même endroit, sous le même doigt.
              if (quantityInCart == 0)
                _AddButton(label: l10n.boutiqueAddToCart, onAdd: widget.onAdd)
              else
                _QuantityStepper(
                  quantity: quantityInCart,
                  // Un « − » qui ne pourrait rien défaire se rend INERTE
                  // plutôt que muet : tous les exemplaires sont déjà destinés
                  // à un enfant, et c'est au panier — où le nom est sous les
                  // yeux — qu'on les retire.
                  onRemove: widget.canRemoveOne ? widget.onRemove : null,
                  onAdd: widget.onAdd,
                  addLabel: l10n.boutiqueAddOneMore(article.label),
                  removeLabel: l10n.boutiqueRemoveOne(article.label),
                ),
            ],
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
    final article = widget.article;
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

/// Le geste d'entrée : plein-largeur, une seule cible, aucun doute.
class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onAdd;

  const _AddButton({required this.label, required this.onAdd});

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onAdd,
    icon: const Icon(Icons.add_shopping_cart_outlined, size: 16),
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.terreCuite,
      // ⚠️ Sans `minimumSize`, un bouton inline hérite du thème plein-largeur
      // et lève en contrainte infinie.
      minimumSize: const Size.fromHeight(40),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}

/// « − n + ». Le compte est au centre, les deux pas de part et d'autre : c'est
/// la disposition que le pouce attend, et elle évite de viser entre deux cibles.
class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onRemove;
  final VoidCallback onAdd;
  final String addLabel;
  final String removeLabel;

  const _QuantityStepper({
    required this.quantity,
    required this.onRemove,
    required this.onAdd,
    required this.addLabel,
    required this.removeLabel,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    decoration: BoxDecoration(
      color: AppColors.terreCuite.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.terreCuite.withValues(alpha: 0.35)),
    ),
    child: Row(
      children: [
        _StepButton(
          icon: Icons.remove_rounded,
          tooltip: removeLabel,
          onPressed: onRemove,
        ),
        Expanded(
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.terreCuite,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _StepButton(
          icon: Icons.add_rounded,
          tooltip: addLabel,
          onPressed: onAdd,
        ),
      ],
    ),
  );
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Semantics(
      button: true,
      label: tooltip,
      enabled: onPressed != null,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 44,
          height: 40,
          child: Icon(
            icon,
            size: 18,
            color: onPressed == null
                ? AppColors.terreCuite.withValues(alpha: 0.3)
                : AppColors.terreCuite,
          ),
        ),
      ),
    ),
  );
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
