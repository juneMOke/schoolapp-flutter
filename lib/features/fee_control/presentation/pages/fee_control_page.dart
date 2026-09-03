import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_level_labels.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/fee_control/presentation/contracts/fee_control_dashboard_contracts.dart';
import 'package:school_app_flutter/features/fee_control/presentation/helpers/fee_control_fee_options.dart';
import 'package:school_app_flutter/features/fee_control/presentation/helpers/fee_control_page_helpers.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/fee_control_results_view.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/fee_control_search_form.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/fee_control_summary_band.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

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
    return BlocProvider<FeeControlBloc>(
      create: (_) => getIt<FeeControlBloc>(),
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
    final option = feeControlFeeOptionFor(state.tariffs, intent.feeCode);
    // La nature n'est pas dans la grille de ce niveau : il n'y a rien à
    // chercher, et forcer une requête afficherait un vide inexplicable. Le
    // formulaire reste pré-rempli, l'utilisateur voit ce qui manque.
    _pendingIntentSearch = false;
    if (option == null) return;

    context.read<FeeControlBloc>().add(
      FeeControlSearchRequested(
        academicYearId: academicYearId,
        request: FeeControlSearchRequest(
          schoolLevelGroupId: intent.schoolLevelGroupId,
          schoolLevelId: intent.schoolLevelId,
          classroomId: intent.classroomId,
          feeCode: intent.feeCode,
          // Mêmes champs que le formulaire construit lui-même : la puce de
          // critère nomme le frais comme le sélecteur l'aurait nommé.
          feeLabel: option.tariffLabel,
          feeTariffCode: option.tariffCode,
          statusFilter: FeeControlPaymentFilter.all,
          firstName: '',
          lastName: '',
          surname: '',
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

          return AnimatedSwitcher(
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
                    return FeeControlSearchForm(
                      initial: widget.intent,
                      options: options,
                      tariffs: state.tariffs,
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
                      onSearch: (request) => bloc.add(
                        FeeControlSearchRequested(
                          academicYearId: academicYearId,
                          request: request,
                        ),
                      ),
                      onClear: () => bloc.add(const FeeControlResetRequested()),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.spacingM),
                const FeeControlSummaryBand(),
                FeeControlResultsView(
                  onViewRequested: (row) =>
                      _openFinancialRecord(context, row, academicYearId),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Ouvre la fiche financière de l'élève — la page de détail de la
  /// Facturation, réutilisée telle quelle. Le retour revient ici : la page est
  /// **poussée**, et `StudentDetailAppBar` dépile avant de retomber sur sa
  /// route de repli.
  void _openFinancialRecord(
    BuildContext context,
    FeeControlRow row,
    String academicYearId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (academicYearId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bootstrapContextUnavailableMessage)),
      );
      return;
    }

    final levelId =
        context.read<FeeControlBloc>().state.lastQuery?.schoolLevelId ?? '';
    final academicYearContext = context
        .read<AcademicYearContextBloc>()
        .state
        .context;

    // Troisième porte sur la MÊME fiche que Facturation et son sur-titre : le
    // frais contrôlé impose déjà une classe, mais la ligne reste la source la
    // plus sûre quand le référentiel n'est pas encore descendu.
    final labels = resolveEnrollmentLevelLabels(
      row.summary,
      bundles: academicYearContext?.schoolLevelGroups ?? const [],
      searchedLevelId: levelId,
    );

    final student = row.summary.student;
    context.push(
      AppRoutesNames.facturationDetailPath(
        studentId: student.id,
        academicYearId: academicYearId,
      ),
      extra: FacturationDetailIntent(
        studentId: student.id,
        academicYearId: academicYearId,
        firstName: student.firstName,
        lastName: student.lastName,
        surname: student.surname,
        levelName: labels.levelName,
        levelGroupName: labels.levelGroupName,
      ),
    );
  }
}
