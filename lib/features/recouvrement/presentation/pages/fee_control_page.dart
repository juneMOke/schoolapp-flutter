import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/fee_control_page_actions.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/actions/fee_control_action_bar.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/actions/fee_control_marked_card.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/exchange_rates_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_selection_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_pivot.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_page_helpers.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/fee_control_results_view.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/perimeter/fee_control_perimeter_card.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/fee_control_summary_band.dart';

/// Contrôle des frais : pour un frais d'une classe, qui est soldé, qui est
/// partiel, qui n'a rien versé.
///
/// Même anatomie que la Facturation (gate du contexte académique, formulaire
/// puis résultats), et l'œil rouvre **la fiche financière de la Facturation** —
/// aucune duplication du détail.
class FeeControlPage extends StatelessWidget {
  /// Critères posés par le tableau de bord, quand l'écran est ouvert depuis
  /// lui. `null` à l'ouverture par le menu : l'écran est alors vierge.
  final FeeControlIntent? intent;

  const FeeControlPage({super.key, this.intent});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FeeControlBloc>(create: (_) => getIt<FeeControlBloc>()),
        // Le cours du jour n'est lu QUE pour arbitrer : ordonner les lignes et
        // comparer un plancher à un sac mixte. Aucun montant affiché n'est
        // converti (doctrine bi-devise, règle 6).
        BlocProvider<ExchangeRatesCubit>(
          create: (_) => getIt<ExchangeRatesCubit>()..load(),
        ),
        // Le titre que l'école donne à chaque nature — celui que le tableau de
        // bord et la liste de relance écrivent aussi. Local d'abord, une
        // relecture par session ensuite, muette en échec : un nom d'hier vaut
        // mieux qu'un écran qui attend le réseau pour nommer un frais.
        BlocProvider<FeeSectionTitlesCubit>(
          create: (_) => getIt<FeeSectionTitlesCubit>()..load(),
        ),
        // Brouillon de séance : les cochés et les marqués « à renvoyer ». Rien
        // n'en sort tant qu'on ne le demande pas, rien n'y survit à la sortie
        // du module.
        BlocProvider<FeeControlSelectionCubit>(
          create: (_) => FeeControlSelectionCubit(),
        ),
      ],
      child: _FeeControlView(intent: intent),
    );
  }
}

class _FeeControlView extends StatefulWidget {
  final FeeControlIntent? intent;

  const _FeeControlView({this.intent});

  @override
  State<_FeeControlView> createState() => _FeeControlViewState();
}

class _FeeControlViewState extends State<_FeeControlView> {
  /// Vrai tant que la recherche d'ouverture n'a pas été lancée.
  ///
  /// Elle attend la grille : la requête porte le libellé et le code de la ligne
  /// tarifaire, que seule la grille chargée peut donner. La lancer plus tôt
  /// enverrait une désignation vide, et la puce de critère mentirait sur ce qui
  /// est contrôlé.
  bool _pendingIntentSearch = false;

  /// Vrai tant que la grille du niveau visé n'a pas été demandée.
  bool _pendingIntentPrime = false;

  @override
  void initState() {
    super.initState();
    _pendingIntentSearch = widget.intent != null;
    _pendingIntentPrime = widget.intent != null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AcademicYearContextBloc>().add(
        const AcademicYearContextRequested(),
      );
    });
  }

  /// Charge la grille et les classes du niveau visé, puis arme la recherche.
  void _primeFromIntent(String academicYearId) {
    final intent = widget.intent;
    if (intent == null) return;
    final bloc = context.read<FeeControlBloc>();
    bloc.add(
      FeeControlTariffsRequested(
        academicYearId: academicYearId,
        schoolLevelGroupId: intent.schoolLevelGroupId,
        schoolLevelId: intent.schoolLevelId,
      ),
    );
    bloc.add(
      FeeControlClassroomsRequested(
        academicYearId: academicYearId,
        schoolLevelId: intent.schoolLevelId,
      ),
    );
  }

  /// Lance **une seule fois** la recherche d'ouverture, la grille arrivée.
  void _searchFromIntent(String academicYearId, FeeControlState state) {
    final intent = widget.intent;
    if (!_pendingIntentSearch || intent == null) return;
    if (state.tariffsStatus != EnrollmentLoadStatus.success) return;
    // La nature n'est pas dans la grille de ce niveau : il n'y a rien à
    // chercher, et forcer une requête afficherait un vide inexplicable. La
    // carte reste pré-remplie, l'utilisateur voit ce qui manque.
    _pendingIntentSearch = false;
    if (!state.tariffs.any((t) => t.feeCode == intent.feeCode)) return;

    _search(
      academicYearId,
      FeeControlSearchRequest(
        schoolLevelGroupId: intent.schoolLevelGroupId,
        schoolLevelId: intent.schoolLevelId,
        classroomId: intent.classroomId,
        feeCodes: [intent.feeCode],
        statusFilter: FeeControlPaymentFilter.all,
      ),
    );
  }

  /// Le seul canal de recherche : il attache le cours du jour à la requête.
  ///
  /// Attaché ICI et non lu par le BLoC : la requête est une **photo**, et le
  /// réessai comme la pagination doivent rejouer le même classement. Un cours
  /// qui bouge entre deux pages réordonnerait la liste sous les doigts.
  void _search(String academicYearId, FeeControlSearchRequest request) {
    context.read<FeeControlBloc>().add(
      FeeControlSearchRequested(
        academicYearId: academicYearId,
        request: request,
        rate: RecouvrementPivot.dollarInFrancs(
          context.read<ExchangeRatesCubit>().state.rates,
        ),
      ),
    );
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
          final options = FeeControlPageHelpers.buildAcademicOptions(
            academicYearState.context?.schoolLevelGroups ?? const [],
          );

          // Le contexte académique connu, l'intention peut charger la grille et
          // les classes de son niveau. Hors frame de build : émettre un
          // événement pendant la construction ferait rebâtir sous soi-même.
          if (_pendingIntentPrime) {
            _pendingIntentPrime = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _primeFromIntent(academicYearId);
            });
          }

          return BlocListener<FeeControlBloc, FeeControlState>(
            // Une sélection n'a de sens que dans son périmètre : changer de
            // frais, de classe, de situation ou de plancher la vide. Les
            // marques « à renvoyer », elles, traversent — on les constitue
            // justement en parcourant les classes.
            listenWhen: (prev, curr) => prev.lastQuery != curr.lastQuery,
            listener: (context, _) =>
                context.read<FeeControlSelectionCubit>().clearSelection(),
            child: AnimatedSwitcher(
              duration: FinanceMotion.standard,
              child: Column(
                key: const ValueKey('fee-control-content'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocConsumer<FeeControlBloc, FeeControlState>(
                    listenWhen: (prev, curr) =>
                        prev.tariffsStatus != curr.tariffsStatus,
                    listener: (context, state) =>
                        _searchFromIntent(academicYearId, state),
                    buildWhen: (prev, curr) =>
                        prev.status != curr.status ||
                        prev.tariffsStatus != curr.tariffsStatus ||
                        prev.tariffs != curr.tariffs ||
                        prev.classroomsStatus != curr.classroomsStatus ||
                        prev.classrooms != curr.classrooms ||
                        prev.feeGridMissing != curr.feeGridMissing,
                    builder: (context, state) {
                      final bloc = context.read<FeeControlBloc>();
                      return FeeControlPerimeterCard(
                        initial: widget.intent,
                        options: options,
                        tariffs: state.tariffs,
                        // Abonné : le titre d'une nature peut arriver après la
                        // grille — la relecture réseau rend plus tard que le
                        // cache —, et la pastille doit alors se renommer.
                        sectionTitles: context
                            .watch<FeeSectionTitlesCubit>()
                            .state,
                        classrooms: state.classrooms,
                        isTariffsLoading:
                            state.tariffsStatus == EnrollmentLoadStatus.loading,
                        isClassroomsLoading:
                            state.classroomsStatus ==
                            EnrollmentLoadStatus.loading,
                        feeGridMissing: state.feeGridMissing,
                        // `tariffsStatus: failure` était stocké et lu par
                        // personne : le sélecteur de frais retombait alors sur
                        // « aucun frais défini pour ce niveau », qui affirme sur
                        // l'école ce qui n'est vrai que de cet appareil.
                        tariffsFailed:
                            state.tariffsStatus == EnrollmentLoadStatus.failure,
                        isLoading: state.status == EnrollmentLoadStatus.loading,
                        // Un niveau choisi ouvre deux lectures locales : sa grille
                        // tarifaire et ses classes.
                        onLevelSelected: (groupId, levelId) {
                          bloc.add(
                            FeeControlTariffsRequested(
                              academicYearId: academicYearId,
                              schoolLevelGroupId: groupId,
                              schoolLevelId: levelId,
                            ),
                          );
                          bloc.add(
                            FeeControlClassroomsRequested(
                              academicYearId: academicYearId,
                              schoolLevelId: levelId,
                            ),
                          );
                        },
                        onSearch: (request) => _search(academicYearId, request),
                        onClear: () =>
                            bloc.add(const FeeControlResetRequested()),
                      );
                    },
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  const FeeControlSummaryBand(),
                  FeeControlActionBar(
                    onCallList: () => printCallSheet(context),
                    onMark: () => markSelection(context),
                  ),
                  FeeControlResultsView(
                    titles: context.watch<FeeSectionTitlesCubit>().state,
                    onViewRequested: (row) =>
                        openFinancialRecord(context, row, academicYearId),
                    onRowTapped: (row) =>
                        openStudentSheet(context, row, academicYearId),
                    onBilling: () => openBilling(context),
                  ),
                  const FeeControlMarkedCard(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
