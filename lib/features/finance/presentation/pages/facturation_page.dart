import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/navigation/location_query.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:school_app_flutter/core/layout/master_detail_layout.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_level_labels.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_page_helpers.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_split_selection.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_search_form.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_split_detail_pane.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_student_table.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_top_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/tickets_to_print/tickets_to_print_banner.dart';

class FacturationPage extends StatefulWidget {
  /// Vrai quand l'écran est ouvert par sa ROUTE, hors de la coquille — poussé
  /// par le contrôle nominatif du Recouvrement (« Facturer »). Il n'a alors ni
  /// barre latérale ni TopBar, et porte sa propre barre, avec le retour.
  final bool standalone;

  /// Dans la coquille, dont la TopBar titre déjà l'écran.
  const FacturationPage({super.key}) : standalone = false;

  /// L'écran tel que sa route le construit : hors de la coquille, donc avec sa
  /// barre.
  const FacturationPage.fromRoute({super.key}) : standalone = true;

  @override
  State<FacturationPage> createState() => _FacturationPageState();
}

class _FacturationPageState extends State<FacturationPage> {
  /// Grand écran : la fiche ouverte à côté de la liste, tenue dans l'adresse.
  late final FacturationSplitSelection _selection;

  FacturationDetailIntent? get _selected => _selection.selected;

  /// La largeur reçue permet-elle la liste et la fiche côte à côte ? Relu à
  /// chaque rendu : c'est lui qui décide, au clic, d'ouvrir à côté ou de
  /// pousser la fiche.
  bool _split = false;

  /// La liste garde son état (critères saisis, tri) quand un redimensionnement
  /// la fait passer de la page entière à sa colonne, et retour.
  final _listKey = GlobalKey();

  bool _selectionBound = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectionBound) return;
    _selectionBound = true;
    // Dans l'adresse seulement quand la Facturation EST l'écran de base :
    // poussée depuis le Recouvrement, la sélection reste en mémoire.
    _selection = FacturationSplitSelection(LocationQuery.ownedBy(context))
      ..addListener(_onSelectionChanged);
  }

  void _onSelectionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _split = constraints.maxWidth >= AppBreakpoints.facturationSplitMin;
        // F5 relit la dernière recherche — une fois une recherche lancée.
        return PageActionShortcut(
          action: PageAction.refresh,
          onInvoke: () => context.read<EnrollmentLocalListBloc>().add(
            const LocalListRefreshRequested(),
          ),
          isAllowed: () =>
              context
                  .read<EnrollmentLocalListBloc>()
                  .state
                  .summariesQueryType ==
              EnrollmentSummaryQueryType.byAcademicInfo,
          child: _page(context),
        );
      },
    );
  }

  Widget _page(BuildContext context) {
    return AppPageBackground(
      width: PageContentWidth.wide,
      // Liste + fiche : chacune défile dans sa colonne, la page non.
      scrollable: !_split,
      // Posée hors du `BlocBuilder` : la sortie reste offerte même quand le
      // contexte académique charge ou échoue.
      appBar: widget.standalone ? const FacturationTopBar() : null,
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

          final academicOptions = FacturationPageHelpers.buildAcademicOptions(
            academicYearState.context?.schoolLevelGroups ?? const [],
          );

          final list = KeyedSubtree(
            key: _listKey,
            child: AnimatedSwitcher(
              duration: FinanceMotion.standard,
              child: Column(
                key: const ValueKey('facturation-content'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Là où le caissier encaisse : c'est lui qui a les tickets
                  // en file (continuité des tickets RC, lot D).
                  const TicketsToPrintBanner(
                    padding: EdgeInsets.only(bottom: AppDimensions.spacingM),
                  ),
                  BlocBuilder<
                    EnrollmentLocalListBloc,
                    EnrollmentLocalListState
                  >(
                    buildWhen: (prev, curr) =>
                        prev.summariesStatus != curr.summariesStatus,
                    builder: (context, enrollmentState) {
                      return FacturationSearchForm(
                        options: academicOptions,
                        isLoading:
                            enrollmentState.summariesStatus ==
                            EnrollmentLoadStatus.loading,
                        // Recherche 100 % locale des élèves FACTURABLES : ceux dont
                        // l'inscription de l'année courante est finalisée
                        // (SYNCED|PENDING_SYNC|SYNC_ERROR), et non le vivier de
                        // réinscription.
                        onSearch: (request) =>
                            context.read<EnrollmentLocalListBloc>().add(
                              LocalListByEnrolledAcademicInfoRequested(
                                academicYearId:
                                    academicYearState
                                        .context
                                        ?.academicYear
                                        .id ??
                                    '',
                                firstName: request.firstName,
                                lastName: request.lastName,
                                surname: request.surname,
                                schoolLevelGroupId: request.schoolLevelGroupId,
                                schoolLevelId: request.schoolLevelId,
                              ),
                            ),
                      );
                    },
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  FacturationStudentTable(
                    onViewRequested: _onViewChargesRequested,
                    selectedStudentId: _split ? _selected?.studentId : null,
                  ),
                ],
              ),
            ),
          );
          if (!_split) return list;
          return MasterDetailLayout(
            master: list,
            detail: FacturationSplitDetailPane(
              selected: _selectedThisYear(),
              onClose: _selection.clear,
            ),
            onCloseDetail: _selected == null ? null : _selection.clear,
          );
        },
      ),
    );
  }

  /// La fiche choisie, si elle est de l'année consultée : une fiche ouverte
  /// sur une autre année (contexte changé depuis) ne s'affiche pas — son
  /// grand-livre n'est plus celui qu'on consulte.
  FacturationDetailIntent? _selectedThisYear() {
    final yearId = context
        .read<AcademicYearContextBloc>()
        .state
        .context
        ?.academicYear
        .id;
    return _selected?.academicYearId == yearId ? _selected : null;
  }

  /// Navigue vers la page de détail facturation avec le contexte d'affichage.
  void _onViewChargesRequested(EnrollmentSummary summary, String levelId) {
    final l10n = AppLocalizations.of(context)!;
    final academicYearContext = context
        .read<AcademicYearContextBloc>()
        .state
        .context;
    final academicYearId = academicYearContext?.academicYear.id ?? '';

    if (academicYearId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bootstrapContextUnavailableMessage)),
      );
      return;
    }

    // La LIGNE d'abord, le critère de recherche ensuite : une recherche par
    // identité ne transporte aucun niveau, et le sur-titre affichait « · - »
    // là où le résumé sait de quel niveau est l'élève.
    final labels = resolveEnrollmentLevelLabels(
      summary,
      bundles: academicYearContext?.schoolLevelGroups ?? const [],
      searchedLevelId: levelId,
    );

    final intent = FacturationDetailIntent(
      studentId: summary.student.id,
      academicYearId: academicYearId,
      firstName: summary.student.firstName,
      lastName: summary.student.lastName,
      surname: summary.student.surname,
      levelName: labels.levelName,
      levelGroupName: labels.levelGroupName,
    );
    if (_split) {
      _selection.select(intent);
      return;
    }
    context.push(
      AppRoutesNames.facturationDetailPath(
        studentId: summary.student.id,
        academicYearId: academicYearId,
      ),
      extra: intent,
    );
  }
}
