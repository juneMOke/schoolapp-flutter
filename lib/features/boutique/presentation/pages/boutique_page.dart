import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/boutique_bloc.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_cart_page.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_button.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_top_bar.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_line_tile.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_catalog_body.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_search_bar.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La caisse boutique : composer un panier depuis le catalogue, désigner le
/// payeur et les bénéficiaires, encaisser au comptant, remettre une preuve.
///
/// **Étanche à la scolarité** (ADR-020, invariant I-4) : une vente n'apparaît ni
/// sur la note de perception ni sur le relevé de compte de l'élève, et
/// n'alimente aucun poste dû.
///
/// Le gate du contexte académique est ici et non plus bas : le catalogue est
/// tarifé **par niveau**, et les niveaux appartiennent à une année. Sans année
/// courante, il n'y a pas de prix à résoudre — donc rien à vendre.
class BoutiquePage extends StatelessWidget {
  const BoutiquePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<BoutiqueBloc>(
    create: (_) => getIt<BoutiqueBloc>(),
    child: const _BoutiqueView(),
  );
}

class _BoutiqueView extends StatefulWidget {
  const _BoutiqueView();

  @override
  State<_BoutiqueView> createState() => _BoutiqueViewState();
}

class _BoutiqueViewState extends State<_BoutiqueView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AcademicYearContextBloc>().add(
        const AcademicYearContextRequested(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status || prev.context != curr.context,
      builder: (context, academicYearState) {
        if (academicYearState.status == AcademicYearContextLoadStatus.loading ||
            academicYearState.status == AcademicYearContextLoadStatus.initial) {
          return const AppPageBackground(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingXL),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (academicYearState.status != AcademicYearContextLoadStatus.success) {
          return AppPageBackground(
            child: BootstrapContextError(
              onLogout: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            ),
          );
        }

        final academicYearId = academicYearState.context?.academicYear.id ?? '';

        // Le fond et la barre appartiennent au catalogue, pas au gate : la
        // barre porte le panier, et un panier au-dessus d'un spinner ouvrirait
        // une page sur un bloc qui n'a pas encore d'année à tarifer.
        return _CatalogueScope(
          academicYearId: academicYearId,
          levels: _levelsOf(academicYearState),
          searchController: _searchController,
        );
      },
    );
  }

  /// Les niveaux de l'école, à plat, pour le sélecteur d'une ligne walk-in.
  ///
  /// **Liste fermée** : le walk-in choisit un niveau, jamais un prix
  /// (invariant I-2).
  ///
  /// Le type de la liste vide est explicite : un `?? const []` nu se laisse
  /// inférer en `List<dynamic>`, et l'accès aux membres cesse alors d'être
  /// vérifié — l'erreur se découvre à l'exécution, dans la main du guichet.
  List<BoutiqueLevelOption> _levelsOf(AcademicYearContextState state) => [
    for (final bundle
        in state.context?.schoolLevelGroups ?? const <SchoolLevelGroupBundle>[])
      for (final level in bundle.levels)
        BoutiqueLevelOption(id: level.id, label: level.name),
  ];
}

class _CatalogueScope extends StatefulWidget {
  final String academicYearId;
  final List<BoutiqueLevelOption> levels;
  final TextEditingController searchController;

  const _CatalogueScope({
    required this.academicYearId,
    required this.levels,
    required this.searchController,
  });

  @override
  State<_CatalogueScope> createState() => _CatalogueScopeState();
}

class _CatalogueScopeState extends State<_CatalogueScope> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BoutiqueBloc>().add(
        BoutiqueCatalogRequested(widget.academicYearId),
      );
    });
  }

  /// Ouvre le panier — sa propre page, et non une colonne ni une feuille.
  ///
  /// Le bloc est passé par valeur : la page s'ouvre **hors** de cet arbre, et
  /// sans cela `context.read` n'y trouverait rien. C'est aussi ce qui garantit
  /// qu'il n'existe qu'un seul panier — un second bloc en composerait un second,
  /// et la vente encaissée ne serait pas celle qu'on a vue à l'écran.
  Future<void> _openCart(BuildContext context) => BoutiqueCartPage.push(
    context,
    bloc: context.read<BoutiqueBloc>(),
    academicYearId: widget.academicYearId,
    levels: widget.levels,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<BoutiqueBloc, BoutiqueState>(
      builder: (context, state) {
        final bloc = context.read<BoutiqueBloc>();

        return AppPageBackground(
          // Le panier vit dans la barre, hors du défilement : une caisse dont
          // le panier disparaît sous le catalogue fait recompter le guichet.
          appBar: BoutiqueTopBar(
            eyebrow: l10n.boutiqueEyebrow,
            title: l10n.boutiqueTitle,
            action: BoutiqueCartButton(
              articleCount: state.cart.articleCount,
              onPressed: () => _openCart(context),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BoutiqueSearchBar(
                controller: widget.searchController,
                selectedFamily: state.familyFilter,
                // Inerte pendant le chargement : filtrer un squelette apprend au
                // guichet que la recherche ne marche pas.
                enabled: state.status == BoutiqueStatus.ready,
                onQueryChanged: (q) => bloc.add(BoutiqueQueryChanged(q)),
                onFamilyChanged: (f) =>
                    bloc.add(BoutiqueFamilyFilterChanged(f)),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              BoutiqueCatalogBody(
                state: state,
                onAddArticle: (article) =>
                    bloc.add(BoutiqueArticleAdded(article)),
                onRemoveArticle: (article) =>
                    bloc.add(BoutiqueArticleDecremented(article)),
                onResetFilters: () {
                  widget.searchController.clear();
                  bloc.add(const BoutiqueFiltersReset());
                },
                onRetry: () =>
                    bloc.add(BoutiqueCatalogRequested(widget.academicYearId)),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              const _GridReminderBanner(),
            ],
          ),
        );
      },
    );
  }
}

/// Le rappel des deux invariants, sous le catalogue.
///
/// **Il n'est pas décoratif** : c'est la formulation utilisateur de I-1 et I-2.
/// Le guichet doit savoir que le prix n'est pas négociable *avant* qu'une
/// famille le lui demande.
class _GridReminderBanner extends StatelessWidget {
  const _GridReminderBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.vertSavane.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.vertSavane.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 18,
            color: AppColors.vertSavane,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              l10n.boutiqueGridReminder,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
