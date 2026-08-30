import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/boutique_bloc.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_family_style.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_catalog_view.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/states/boutique_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le corps du catalogue et ses états.
///
/// **Quatre vides distincts**, et les confondre enverrait le guichet corriger la
/// mauvaise chose :
///
///  - *catalogue retenu* — il manque un droit, pas un article ;
///  - *catalogue vide* — l'école n'a rien créé ;
///  - *aucun résultat* — les critères sont trop étroits ;
///  - *erreur* — la lecture a échoué.
class BoutiqueCatalogBody extends StatelessWidget {
  final BoutiqueState state;
  final void Function(BoutiqueArticle article) onAddArticle;
  final void Function(BoutiqueArticle article) onRemoveArticle;
  final VoidCallback onResetFilters;
  final VoidCallback onRetry;

  const BoutiqueCatalogBody({
    super.key,
    required this.state,
    required this.onAddArticle,
    required this.onRemoveArticle,
    required this.onResetFilters,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (state.status == BoutiqueStatus.loading ||
        state.status == BoutiqueStatus.initial) {
      return const _CatalogSkeleton();
    }

    if (state.status == BoutiqueStatus.failure) {
      // L'écran ENTIER passe en erreur : il n'y a rien à vendre sans catalogue.
      return BoutiqueResultsErrorState(
        failure: state.failure!,
        onRetry: onRetry,
      );
    }

    if (state.catalog.withheld) {
      // Ce n'est PAS « la boutique n'a pas d'article » : c'est « on ne vous a
      // pas communiqué le catalogue ». Aucune action de création ici — il n'y a
      // rien à créer, il manque un droit.
      return EteeloEmptyResult(
        label: l10n.boutiqueWithheldCatalogTitle,
        description: l10n.boutiqueWithheldCatalogMessage,
        medallionIcon: Icons.lock_outline,
      );
    }

    if (state.catalog.isEmpty) {
      return EteeloEmptyResult(
        label: l10n.boutiqueEmptyCatalogTitle,
        description: l10n.boutiqueEmptyCatalogMessage,
        medallionIcon: Icons.storefront_outlined,
      );
    }

    if (state.hasNoMatch) {
      final family = state.familyFilter;
      return EteeloEmptyResult(
        label: l10n.boutiqueNoMatchTitle,
        // Le message CITE la requête et le filtre : « aucun résultat » tout
        // court laisse chercher lequel des deux critères a vidé la liste.
        description: family == null
            ? l10n.boutiqueNoMatchMessageAll(state.query)
            : l10n.boutiqueNoMatchMessage(
                state.query,
                BoutiqueFamilyStyle.labelOf(family, l10n),
              ),
        medallionIcon: Icons.search_off,
        primaryAction: EteeloButton.secondary(
          label: l10n.boutiqueResetFilters,
          onPressed: onResetFilters,
          fullWidth: false,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Les articles que ce client ne sait pas vendre ne sont pas jetés en
        // silence : sans cette mention, le guichet chercherait un article que
        // la direction jure avoir créé.
        if (state.catalog.unsellable.isNotEmpty)
          _UnsellableNotice(count: state.catalog.unsellable.length),
        BoutiqueCatalogView(
          groups: state.visibleByFamily,
          quantityOf: state.cart.quantityOfArticle,
          cartCountOfFamily: (family) => state.cart.lines
              .where((line) => line.article.family == family)
              .fold(0, (sum, line) => sum + line.quantity),
          canRemoveOne: state.cart.hasBareLineOfArticle,
          onAddArticle: onAddArticle,
          onRemoveArticle: onRemoveArticle,
        ),
      ],
    );
  }
}

/// Huit cartes fantômes, dans **la même grille** que les vraies.
///
/// Jamais un spinner centré : la mise en page sauterait à l'arrivée des
/// données, et le guichet perdrait le repère qu'il venait de prendre.
class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton();

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
    itemCount: 8,
    itemBuilder: (context, index) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Même géométrie que la carte réelle : médaillon, deux barres de
          // titre, une barre de prix poussée en bas.
          EteeloSkeletonBox(
            width: 38,
            height: 38,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          SizedBox(height: 10),
          EteeloSkeletonBox(width: double.infinity, height: 12),
          SizedBox(height: 6),
          EteeloSkeletonBox(width: 80, height: 12),
          Spacer(),
          EteeloSkeletonBox(width: 72, height: 17),
        ],
      ),
    ),
  );
}

class _UnsellableNotice extends StatelessWidget {
  final int count;

  const _UnsellableNotice({required this.count});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n.boutiqueUnsellableNotice(count),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
