import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_tender_section.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_footer.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_line_tile.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le panier : en-tête et pied fixes, corps défilant.
///
/// **Toujours visible** — collant sur poste fixe, sous le catalogue en tablette.
/// Une caisse dont le panier disparaît au défilement fait recompter le guichet.
class BoutiqueCartPanel extends StatelessWidget {
  final BoutiqueCart cart;
  final List<BoutiqueLevelOption> levels;

  /// Le bloc payeur, injecté plutôt que construit ici : il porte sa propre
  /// saisie et son propre répertoire, et le panier n'a pas à les connaître.
  final Widget payerSection;

  final void Function(String lineKey) onRemoveLine;
  final void Function(String lineKey, int quantity) onQuantityChanged;
  final void Function(String lineKey, String? levelId) onLevelChanged;
  final void Function(String lineKey) onPickBeneficiary;
  final void Function(String lineKey) onClearBeneficiary;
  final VoidCallback? onCollect;

  /// `null` une fois la vente encaissée — cf. [BoutiqueCartFooter.onClear].
  final VoidCallback? onClear;

  /// La série de taux de l'école. Vide = aucun taux paramétré : le panneau
  /// n'offre aucun choix de devise, et l'écran est celui d'avant.
  final List<ExchangeRate> rates;

  final void Function(String catalogCurrency, String currency)?
  onTenderCurrencyChanged;
  final void Function(String catalogCurrency, int? tenderedCents)?
  onTenderedChanged;

  const BoutiqueCartPanel({
    super.key,
    required this.cart,
    required this.levels,
    required this.payerSection,
    required this.onRemoveLine,
    required this.onQuantityChanged,
    required this.onLevelChanged,
    required this.onPickBeneficiary,
    required this.onClearBeneficiary,
    required this.onCollect,
    required this.onClear,
    this.rates = const [],
    this.onTenderCurrencyChanged,
    this.onTenderedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                size: 18,
                color: AppColors.terreCuite,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                l10n.boutiqueCartTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                // La SOMME DES QUANTITÉS, pas le nombre de lignes : trois polos
                // sur une ligne font « 3 articles », et c'est ce que le client
                // compte en les recevant.
                l10n.boutiqueArticleCount(cart.articleCount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          payerSection,
          const SizedBox(height: AppDimensions.spacingM),
          // Une `Column` et non un `ListView` : le panier passe « hauteur
          // libre » sous le catalogue en tablette, donc dans une contrainte de
          // hauteur NON bornée — où `Flexible` et les vues défilantes lèvent.
          // Le défilement est celui de la page, et il suffit : un panier de
          // caisse compte des lignes, pas des milliers.
          if (cart.isEmpty)
            const _EmptyCartBody()
          else
            Column(
              children: [
                for (final line in cart.lines) ...[
                  BoutiqueCartLineTile(
                    line: line,
                    levels: levels,
                    onRemove: () => onRemoveLine(line.key),
                    onQuantityChanged: (q) => onQuantityChanged(line.key, q),
                    onLevelChanged: (levelId) =>
                        onLevelChanged(line.key, levelId),
                    onPickBeneficiary: () => onPickBeneficiary(line.key),
                    onClearBeneficiary: () => onClearBeneficiary(line.key),
                  ),
                  if (line != cart.lines.last)
                    const SizedBox(height: AppDimensions.spacingS),
                ],
              ],
            ),
          const SizedBox(height: AppDimensions.spacingM),
          // « Le client règle en… » — juste avant le total, dans l'ordre où la
          // question se pose au comptoir : on sait ce qui est dû, on demande
          // comment il paie, puis on encaisse.
          BoutiqueTenderSection(
            cart: cart,
            rates: rates,
            onCurrencyChanged: onTenderCurrencyChanged,
            onTenderedChanged: onTenderedChanged,
          ),
          // Le pied reste en place même sur un panier vide, avec « 0.00 $ » :
          // il montre où sera le bouton, plutôt que d'apparaître d'un coup sous
          // le doigt au premier article.
          BoutiqueCartFooter(
            cart: cart,
            onCollect: onCollect,
            onClear: onClear,
          ),
        ],
      ),
    );
  }
}

class _EmptyCartBody extends StatelessWidget {
  const _EmptyCartBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 30,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            l10n.boutiqueCartEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
