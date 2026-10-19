import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_detail_page.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
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
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_search_form.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_student_table.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_top_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

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
  /// Grand écran : la fiche ouverte à côté de la liste ; `null` = aucune.
  FacturationDetailIntent? _selected;

  /// La largeur reçue permet-elle la liste et la fiche côte à côte ? Relu à
  /// chaque rendu : c'est lui qui décide, au clic, d'ouvrir à côté ou de
  /// pousser la fiche.
  bool _split = false;

  /// La liste garde son état (critères saisis, tri) quand un redimensionnement
  /// la fait passer de la page entière à sa colonne, et retour.
  final _listKey = GlobalKey();

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
        return _page(context);
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
          return MasterDetailLayout(master: list, detail: _detailPane());
        },
      ),
    );
  }

  /// La fiche choisie, ou l'invitation à en choisir une. Une clé par élève :
  /// changer d'élève recrée ses BLoCs au lieu de nourrir ceux du précédent.
  Widget _detailPane() {
    final yearId = context
        .read<AcademicYearContextBloc>()
        .state
        .context
        ?.academicYear
        .id;
    // Une fiche ouverte sur une autre année (contexte changé depuis) ne
    // s'affiche pas : son grand-livre n'est plus celui qu'on consulte.
    final selected = _selected?.academicYearId == yearId ? _selected : null;
    if (selected == null) {
      final l10n = AppLocalizations.of(context)!;
      return SingleChildScrollView(
        child: EteeloEmptyResult(
          label: l10n.facturationPickStudentTitle,
          description: l10n.facturationPickStudentMessage,
          medallionIcon: Icons.receipt_long_outlined,
        ),
      );
    }
    return FacturationDetailPage(
      key: ValueKey('${selected.academicYearId}/${selected.studentId}'),
      intent: selected,
      embedded: true,
      onClose: () => setState(() => _selected = null),
    );
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
      setState(() => _selected = intent);
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
