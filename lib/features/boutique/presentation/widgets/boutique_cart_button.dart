import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le panier, dans la barre du haut — **la seule porte** vers sa page, et la
/// seule chose de cet écran qui ne défile pas.
///
/// **Il porte le compte, et c'est tout son intérêt** : le panier vit ailleurs,
/// et un guichet qui ne voit pas ce qu'il a déjà ajouté rouvre pour vérifier —
/// ou ajoute deux fois.
///
/// Délibérément plus grand que la cible minimale : c'est la commande principale
/// de l'écran, visée vite, parfois à deux mains occupées.
///
/// **Posé sur la barre sombre**, il en emprunte les couleurs : un bouton clair
/// sur fond Bleu Profond ferait une tache, et l'or-doux de la pastille est déjà
/// la couleur des accents de cette barre.
///
/// À zéro article, l'icône reste **présente mais sans pastille** : la faire
/// apparaître au premier ajout déplacerait la cible sous le doigt, et le geste
/// « ouvrir le panier » doit exister avant d'avoir quelque chose dedans (le
/// payeur se saisit aussi bien avant qu'après).
class BoutiqueCartButton extends StatelessWidget {
  /// Somme des quantités — ce que le client comptera en recevant ses articles,
  /// jamais le nombre de lignes.
  final int articleCount;

  final VoidCallback onPressed;

  const BoutiqueCartButton({
    super.key,
    required this.articleCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Le lecteur d'écran annonce le COMPTE, pas seulement le geste : « voir le
    // panier » seul laisserait un utilisateur non voyant l'ouvrir uniquement
    // pour savoir s'il est vide.
    final label = articleCount == 0
        ? l10n.boutiqueOpenCart
        : l10n.boutiqueOpenCartWithCount(articleCount);

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          // Blanc translucide, comme le bouton de retour : le contraste vient
          // du fond bleu, pas d'une surface claire posée dessus.
          color: AppColors.textOnDark.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              // 52 dp, au-delà des 48 recommandés : c'est la porte d'entrée du
              // panier sur un écran où rien d'autre ne l'ouvre.
              constraints: const BoxConstraints(minWidth: 56, minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textOnDark.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 24,
                    color: AppColors.textOnDark,
                  ),
                  if (articleCount > 0) ...[
                    const SizedBox(width: 8),
                    _Counter(count: articleCount),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La pastille de compte, en or-doux sur bleu profond : c'est l'accent de cette
/// barre, et le seul qui ressorte sans crier sur un fond sombre.
class _Counter extends StatelessWidget {
  final int count;

  const _Counter({required this.count});

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 7),
    decoration: const BoxDecoration(
      color: AppColors.orDoux,
      shape: BoxShape.circle,
    ),
    child: Text(
      '$count',
      style: const TextStyle(
        color: AppColors.bleuProfond,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
