import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_line.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/beneficiary_picker_cubit.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/boutique_bloc.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_payer.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_beneficiary_dialog.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/presentation/ticket/sale_ticket_print_flow.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_payer_section.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_receipt_bar.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_line_tile.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_confirm_dialog.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_panel.dart';
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

  /// Au-dessus : deux colonnes, panier collant. En dessous : une colonne, le
  /// panier sous le catalogue.
  ///
  /// ⚠️ Un seul seuil, et il doit rester **sous** le plafond de largeur de
  /// `AppPageBackground` (1180 dp) : au-dessus, la disposition large serait
  /// inatteignable — la page ne s'élargirait jamais assez pour la déclencher.
  static const double _twoColumnBreakpoint = 1080;

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
    return AppPageBackground(
      child: BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status || prev.context != curr.context,
        builder: (context, academicYearState) {
          if (academicYearState.status ==
                  AcademicYearContextLoadStatus.loading ||
              academicYearState.status ==
                  AcademicYearContextLoadStatus.initial) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingXL),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (academicYearState.status !=
              AcademicYearContextLoadStatus.success) {
            return BootstrapContextError(
              onLogout: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            );
          }

          final academicYearId =
              academicYearState.context?.academicYear.id ?? '';
          final levels = _levelsOf(academicYearState);

          return _CatalogueScope(
            academicYearId: academicYearId,
            levels: levels,
            searchController: _searchController,
            breakpoint: _twoColumnBreakpoint,
          );
        },
      ),
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
  final double breakpoint;

  const _CatalogueScope({
    required this.academicYearId,
    required this.levels,
    required this.searchController,
    required this.breakpoint,
  });

  @override
  State<_CatalogueScope> createState() => _CatalogueScopeState();
}

class _CatalogueScopeState extends State<_CatalogueScope> {
  /// Les contrôleurs du bloc payeur vivent ICI et non dans le widget de saisie :
  /// celui-ci est reconstruit à chaque frappe (le panier change), et des
  /// contrôleurs recréés à chaque build perdraient le curseur au milieu d'un
  /// nom.
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _firstNameController.dispose();
    super.dispose();
  }

  /// Recopie l'identité retenue au répertoire dans les champs.
  ///
  /// Les contrôleurs ne sont pas pilotés par l'état — les réécrire à chaque
  /// build replacerait le curseur en tête à la deuxième lettre. Ils ne sont
  /// donc poussés QUE sur ce geste, où l'utilisateur ne tape pas.
  void _fillFromDirectory(BoutiquePayer payer) {
    final filled = payer.toCartPayer();
    _phoneController.text = filled.phoneNumber;
    _lastNameController.text = filled.lastName;
    _middleNameController.text = filled.middleName;
    _firstNameController.text = filled.firstName;
    context.read<BoutiqueBloc>().add(BoutiquePayerFromDirectoryUsed(payer));
  }

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

  /// Ouvre la modale de désignation et pose l'élève choisi sur la ligne.
  ///
  /// Le cubit est créé **par ouverture** et refermé après : le laisser vivre
  /// entre deux lignes garderait la recherche de la précédente, et le guichet
  /// verrait des résultats qu'il n'a pas demandés.
  Future<void> _pickBeneficiary(BuildContext context, String lineKey) async {
    final bloc = context.read<BoutiqueBloc>();
    final cubit = getIt<BeneficiaryPickerCubit>(param1: widget.academicYearId);
    try {
      final candidate = await BoutiqueBeneficiaryDialog.show(
        context,
        cubit: cubit,
        levels: widget.levels,
      );
      if (candidate == null) return;
      bloc.add(
        BoutiqueLineBeneficiaryAssigned(
          lineKey,
          CartBeneficiary(
            studentId: candidate.studentId,
            fullName: candidate.fullName,
            schoolLevelId: candidate.schoolLevelId,
            classroomLabel: candidate.schoolLevelName,
            knownToServer: candidate.enrollmentSynced,
          ),
        ),
      );
    } finally {
      await cubit.close();
    }
  }

  /// Vrai pendant l'envoi à l'imprimante — le bouton se neutralise plutôt que
  /// de laisser empiler deux envois vers la même machine.
  bool _isPrinting = false;

  /// Imprime le ticket de la vente qui vient d'être encaissée.
  ///
  /// ⚠️ **Aucun échec ici n'est un échec d'encaissement** : la vente est déjà
  /// écrite, et le papier ne coûte que du papier.
  Future<void> _print(BuildContext context, RecordedSale sale) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _isPrinting = true);
    try {
      await printSaleTicket(
        context,
        sale: sale,
        levelLabels: {for (final level in widget.levels) level.id: level.label},
        messenger: messenger,
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  /// L'appareil est-il hors ligne ?
  ///
  /// ⚠️ **Ne lève jamais.** L'état du réseau ne décide que d'une PHRASE dans la
  /// confirmation ; il ne conditionne pas l'encaissement, qui est local-first.
  /// Or `isOnline()` traverse un canal natif, qui peut échouer — et laisser
  /// l'exception remonter ferait perdre une vente pour un renseignement de
  /// confort, sur un client qui a déjà payé.
  ///
  /// En cas de doute on annonce **hors ligne** : c'est la formulation la plus
  /// prudente, puisqu'elle promet un ticket provisoire — ce qui est de toute
  /// façon vrai à cet instant, le reçu n'étant scellé qu'au push.
  Future<bool> _isOffline() async {
    try {
      return !await getIt<ConnectivityService>().isOnline();
    } catch (_) {
      return true;
    }
  }

  /// Vide les champs du bloc payeur — ils ne sont pas pilotés par l'état, donc
  /// « Nouvelle vente » doit les effacer explicitement.
  void _clearPayerFields() {
    _phoneController.clear();
    _lastNameController.clear();
    _middleNameController.clear();
    _firstNameController.clear();
  }

  /// Confirme puis encaisse.
  ///
  /// La confirmation est un **récapitulatif non modifiable** : c'est là que le
  /// comptant intégral se voit à l'œil nu. Refuser ferme la modale et ne touche
  /// à rien.
  Future<void> _collect(BuildContext context, BoutiqueState state) async {
    final bloc = context.read<BoutiqueBloc>();
    final isOffline = await _isOffline();
    if (!context.mounted) return;

    final confirmed = await BoutiqueConfirmDialog.show(
      context,
      cart: state.cart,
      // « Nouveau » se lit sur l'absence de reconnaissance au répertoire : c'est
      // exactement ce que la phrase annonce au guichet.
      payerIsNew: state.payerMatch == null,
      isOffline: isOffline,
    );
    if (!confirmed) return;

    bloc.add(BoutiqueSaleSubmitted(academicYearId: widget.academicYearId));
  }

  @override
  Widget build(BuildContext context) {
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
              onArticleTap: (article) =>
                  bloc.add(BoutiqueArticleAdded(article)),
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
        );

        final recorded = state.recordedSale;
        final cart = BoutiqueCartPanel(
          cart: state.cart,
          levels: widget.levels,
          payerSection: BoutiquePayerSection(
            payer: state.cart.payer,
            match: state.payerMatch,
            phoneController: _phoneController,
            lastNameController: _lastNameController,
            middleNameController: _middleNameController,
            firstNameController: _firstNameController,
            onPhoneChanged: (value) => bloc.add(
              BoutiquePayerChanged(
                state.cart.payer.copyWith(phoneNumber: value),
              ),
            ),
            onLastNameChanged: (value) => bloc.add(
              BoutiquePayerChanged(state.cart.payer.copyWith(lastName: value)),
            ),
            onMiddleNameChanged: (value) => bloc.add(
              BoutiquePayerChanged(
                state.cart.payer.copyWith(middleName: value),
              ),
            ),
            onFirstNameChanged: (value) => bloc.add(
              BoutiquePayerChanged(state.cart.payer.copyWith(firstName: value)),
            ),
            onUseMatch: _fillFromDirectory,
          ),
          onRemoveLine: (key) => bloc.add(BoutiqueLineRemoved(key)),
          onQuantityChanged: (key, quantity) =>
              bloc.add(BoutiqueLineQuantityChanged(key, quantity)),
          onLevelChanged: (key, levelId) =>
              bloc.add(BoutiqueLineLevelChanged(key, levelId)),
          onPickBeneficiary: (key) => _pickBeneficiary(context, key),
          onClearBeneficiary: (key) =>
              bloc.add(BoutiqueLineBeneficiaryCleared(key)),
          // ⚠️ `recordedSale != null` neutralise le bouton : le panier reste
          // intact après l'encaissement (pour réimprimer), donc `canCollect`
          // reste vrai. Sans cette condition, le guichet appuierait sur
          // « Encaisser » et RIEN ne se produirait — le bloc refuse en silence.
          // Un bouton actif qui ne fait rien est pire qu'un bouton inactif.
          onCollect:
              state.cart.canCollect &&
                  !state.isCollecting &&
                  state.recordedSale == null
              ? () => _collect(context, state)
              : null,
          // Vider effacerait ce que la barre de reçu sert justement à
          // réimprimer : le geste disparaît, « Nouvelle vente » le remplace.
          onClear: state.recordedSale != null
              ? null
              : () {
                  // « Vider le panier » emporte le payeur : les champs doivent
                  // suivre, sinon l'identité de la vente précédente resterait
                  // affichée sur la suivante.
                  _clearPayerFields();
                  bloc.add(const BoutiqueCartCleared());
                },
        );

        // Une fois la vente encaissée, le pied du panier cède la place à la
        // barre de reçu. Le panier RESTE derrière : il permet de réimprimer
        // sans recomposer, et seul « Nouvelle vente » le vide.
        final rightColumn = recorded == null
            ? cart
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BoutiqueReceiptBar(
                    sale: recorded,
                    isPrinting: _isPrinting,
                    onPrint: () => _print(context, recorded),
                    onNewSale: () {
                      _clearPayerFields();
                      bloc.add(const BoutiqueNewSaleStarted());
                    },
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  cart,
                ],
              );

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= widget.breakpoint;
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  catalogue,
                  const SizedBox(height: AppDimensions.spacingL),
                  rightColumn,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: catalogue),
                const SizedBox(width: 14),
                SizedBox(width: 396, child: rightColumn),
              ],
            );
          },
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
