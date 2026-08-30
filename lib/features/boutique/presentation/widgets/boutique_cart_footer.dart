import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_blocker.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_money_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le pied du panier : le total, ce qui manque, le bouton.
///
/// **Le bouton d'encaissement n'est jamais un bouton grisé muet.** Quand il est
/// inactif, le pied dit exactement ce qui manque, dans l'ordre où l'utilisateur
/// peut le corriger. Un bouton qui refuse sans dire pourquoi apprend au guichet
/// à taper au hasard.
class BoutiqueCartFooter extends StatelessWidget {
  final BoutiqueCart cart;
  final VoidCallback? onCollect;

  /// `null` une fois la vente encaissée : le panier reste affiché pour qu'on
  /// puisse relire ce qu'on remet, mais le vider effacerait justement ce que la
  /// barre de reçu sert à réimprimer.
  final VoidCallback? onClear;

  const BoutiqueCartFooter({
    super.key,
    required this.cart,
    required this.onCollect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final blockers = cart.blockers;
    final ready = blockers.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Le total sur son propre bandeau, en Bleu Profond texturé : c'est le
        // chiffre qu'on compare au tiroir, et il ne doit pas se confondre avec
        // les totaux de ligne juste au-dessus.
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
            ),
          ),
          child: Stack(
            children: [
              const KubaPatternLayer(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                  vertical: AppDimensions.spacingM,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.boutiqueTotalLabel.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.orDoux,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.boutiqueArticleCount(cart.articleCount),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textOnDark.withValues(
                                alpha: 0.72,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      BoutiqueMoneyFormat.exact(
                        cart.totalInCents,
                        cart.currency ?? 'USD',
                      ),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnDark,
                        // Chiffres à chasse fixe : un total qui danse en
                        // changeant de largeur se relit mal quand on le compare
                        // au tiroir.
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!ready) ...[
          const SizedBox(height: AppDimensions.spacingS),
          _BlockerList(blockers: blockers),
        ],
        const SizedBox(height: AppDimensions.spacingM),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            // `onPressed: null` plutôt qu'un bouton masqué : il reste à sa
            // place, et le guichet apprend où il sera quand tout sera prêt.
            onPressed: ready ? onCollect : null,
            icon: const Icon(Icons.payments_outlined, size: 20),
            label: Text(
              l10n.boutiqueCollectAction,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.terreCuite,
              // ⚠️ Sans `minimumSize`, un bouton inline hérite du thème
              // plein-largeur et lève en contrainte infinie — piège déjà payé
              // ailleurs dans ce dépôt.
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        // Seulement si le panier a des lignes ET que le geste a encore un sens :
        // proposer de vider un panier vide occupe la place sans rien offrir.
        if (!cart.isEmpty && onClear != null) ...[
          const SizedBox(height: AppDimensions.spacingS),
          // Bordé et non souligné : le geste EFFACE une vente en composition,
          // il mérite d'avoir l'air d'un bouton — un lien souligné en petit se
          // touche par accident, et rien ne le distinguait d'une mention.
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.delete_sweep_outlined, size: 18),
            label: Text(l10n.boutiqueCartClear),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.35)),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BlockerList extends StatelessWidget {
  final List<CartBlocker> blockers;

  const _BlockerList({required this.blockers});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Panier vide : le seul manque énoncé, et sans le préfixe « À compléter » —
    // il n'y a rien à compléter, il y a quelque chose à commencer.
    final onlyEmptyCart =
        blockers.length == 1 &&
        blockers.single.kind == CartBlockerKind.emptyCart;

    final text = onlyEmptyCart
        ? l10n.boutiqueBlockerEmptyCart
        : '${l10n.boutiqueBlockersPrefix} '
              '${blockers.map((b) => _labelOf(b, l10n)).join(' · ')}';

    return Semantics(
      // `liveRegion` : la liste change à chaque frappe du guichet, et un
      // lecteur d'écran doit annoncer ce qui reste sans qu'on aille le
      // rechercher.
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: 15,
            color: AppColors.terreCuite,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.terreCuite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _labelOf(CartBlocker blocker, AppLocalizations l10n) =>
      switch (blocker.kind) {
        CartBlockerKind.emptyCart => l10n.boutiqueBlockerEmptyCart,
        CartBlockerKind.missingLastName => l10n.boutiqueBlockerLastName,
        CartBlockerKind.missingMiddleName => l10n.boutiqueBlockerMiddleName,
        CartBlockerKind.missingFirstName => l10n.boutiqueBlockerFirstName,
        CartBlockerKind.missingPhone => l10n.boutiqueBlockerPhone,
        CartBlockerKind.incompletePhone => l10n.boutiqueBlockerPhoneIncomplete,
        CartBlockerKind.linesWithoutLevel =>
          l10n.boutiqueBlockerLinesWithoutLevel(blocker.count),
      };
}
