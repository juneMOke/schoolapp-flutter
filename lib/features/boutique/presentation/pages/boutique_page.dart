import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/layout/shell_chrome.dart';
import 'package:school_app_flutter/core/components/buttons/eteelo_fab.dart';
import 'package:school_app_flutter/core/components/buttons/eteelo_fab_location.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/navigation/bloc_exit_guard.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/boutique_bloc.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_cart_page.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_grid_reminder_banner.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_button.dart';
import 'package:school_app_flutter/core/components/app_bars/module_top_bar.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_line_tile.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_view.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_catalog_body.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_search_bar.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_academic_year_gate.dart';
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
    // Le panier ne vit que dans ce bloc : quitter l'écran (Précédent, F5,
    // autre écran du menu) le viderait sans un mot. Une vente encaissée
    // n'est plus une saisie — le panier reste affiché jusqu'à la suivante.
    child: BlocExitGuard<BoutiqueBloc, BoutiqueState>(
      hasUnsavedWork: (state) =>
          !state.cart.isEmpty && state.recordedSale == null,
      isBusy: (state) => state.isCollecting,
      discardMessage: AppLocalizations.of(context)!.boutiqueCartDiscardMessage,
      child: const _BoutiqueView(),
    ),
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BoutiqueAcademicYearGate(
      // Le fond et la barre appartiennent au catalogue, pas au gate : la barre
      // porte le panier, et un panier au-dessus d'un spinner ouvrirait une page
      // sur un bloc qui n'a pas encore d'année à tarifer.
      builder: (context, year) => _CatalogueScope(
        academicYearId: year?.academicYear.id ?? '',
        levels: _levelsOf(year),
        academicYearStart: year?.academicYear.startDate,
        searchController: _searchController,
      ),
    );
  }

  List<BoutiqueLevelOption> _levelsOf(AcademicYearContext? year) => [
    for (final bundle
        in year?.schoolLevelGroups ?? const <SchoolLevelGroupBundle>[])
      for (final level in bundle.levels)
        BoutiqueLevelOption(id: level.id, label: level.name),
  ];
}

class _CatalogueScope extends StatefulWidget {
  final String academicYearId;
  final List<BoutiqueLevelOption> levels;
  final DateTime? academicYearStart;
  final TextEditingController searchController;

  const _CatalogueScope({
    required this.academicYearId,
    required this.levels,
    required this.academicYearStart,
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
    academicYearStart: widget.academicYearStart,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<BoutiqueBloc, BoutiqueState>(
      builder: (context, state) {
        final bloc = context.read<BoutiqueBloc>();

        final catalogue = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BoutiqueSearchBar(
              controller: widget.searchController,
              selectedFamily: state.familyFilter,
              // Inerte pendant le chargement : filtrer un squelette apprend au
              // guichet que la recherche ne marche pas.
              enabled: state.status == BoutiqueStatus.ready,
              onQueryChanged: (q) => bloc.add(BoutiqueQueryChanged(q)),
              onFamilyChanged: (f) => bloc.add(BoutiqueFamilyFilterChanged(f)),
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
            const BoutiqueGridReminderBanner(),
          ],
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            // Grand écran : le panier à côté du catalogue, chacun son
            // défilement — le total reste sous les yeux pendant qu'on ajoute.
            final sideCart =
                constraints.maxWidth >= AppBreakpoints.boutiqueSideCartMin;
            // Dans la coquille, sa barre d'en-tête nomme déjà l'écran : pas
            // de seconde barre, et le panier passe en bouton flottant — il
            // reste hors du défilement, compte compris.
            final inShell = ShellChrome.wraps(context);
            return AppPageBackground(
              width: sideCart
                  ? PageContentWidth.wide
                  : PageContentWidth.reading,
              scrollable: !sideCart,
              // Le panier vit dans la barre, hors du défilement : une caisse
              // dont le panier disparaît sous le catalogue fait recompter le
              // guichet. En colonne, il est déjà là.
              appBar: inShell
                  ? null
                  : ModuleTopBar(
                      eyebrow: l10n.boutiqueEyebrow,
                      title: l10n.boutiqueTitle,
                      action: sideCart
                          ? null
                          : BoutiqueCartButton(
                              articleCount: state.cart.articleCount,
                              onPressed: () => _openCart(context),
                            ),
                    ),
              floatingActionButton: inShell && !sideCart
                  ? EteeloFab(
                      label: l10n.boutiqueOpenCart,
                      tooltip: state.cart.articleCount == 0
                          ? null
                          : l10n.boutiqueOpenCartWithCount(
                              state.cart.articleCount,
                            ),
                      icon: Icons.shopping_bag_outlined,
                      badgeCount: state.cart.articleCount,
                      onPressed: () => _openCart(context),
                    )
                  : null,
              floatingActionButtonLocation:
                  const EndFloatEdgeOffsetFabLocation(),
              child: sideCart
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(child: catalogue),
                        ),
                        const SizedBox(width: AppDimensions.spacingL),
                        // Hauteur bornée : le panier défile en lui-même,
                        // son pied (total, « Encaisser ») reste en bas.
                        SizedBox(
                          width: AppDimensions.boutiqueCartColumnWidth,
                          child: BoutiqueCartView(
                            academicYearId: widget.academicYearId,
                            levels: widget.levels,
                            academicYearStart: widget.academicYearStart,
                            embedded: true,
                          ),
                        ),
                      ],
                    )
                  : catalogue,
            );
          },
        );
      },
    );
  }
}
