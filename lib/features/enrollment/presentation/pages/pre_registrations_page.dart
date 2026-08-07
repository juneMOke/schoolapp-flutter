import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/constants/enrollment_page_layout.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_listing_view_mode.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_search_command_handlers.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/pre_registrations_page_helpers.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_scaffold.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/pre_registration/pre_registration_empty_before_search.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/pre_registration_search_form.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_results_bar.dart';

/// Écran Pré-inscriptions, en miroir de `ReRegistrationsPage` : recherche
/// bi-mode d'abord (rien avant une recherche), wizard identique (7 étapes
/// partagées), 2 statuts seulement (En cours / Pré-inscrit — pas de 3e état
/// "candidat non engagé" comme la Réinscription).
class PreRegistrationsPage extends StatefulWidget {
  const PreRegistrationsPage({super.key});

  @override
  State<PreRegistrationsPage> createState() => _PreRegistrationsPageState();
}

class _PreRegistrationsPageState extends State<PreRegistrationsPage> {
  EnrollmentListingViewMode _preferredViewMode = EnrollmentListingViewMode.auto;
  static const String _adminEmail = 'support@school.local';

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
    return AppPageBackground(
      scrollable: true,
      child: EnrollmentListingPageScaffold(
        readyKey: 'pre-reg-content',
        bootstrapBuilder: _buildCurrentYearBootstrap,
        searchSectionBuilder: _buildAcademicSearchSection,
        onSearchCommand: EnrollmentSearchCommandHandlers
            .dispatchPreEnrollmentThroughLocalListBloc,
        // Read-your-writes : au retour du détail, on rafraîchit le vivier — le
        // candidat qu'on vient de commencer à pré-inscrire réapparaît alors
        // comme son dossier, plus comme candidat frais.
        onDetailReturned: () => context.read<EnrollmentLocalListBloc>().add(
          const LocalListRefreshRequested(),
        ),
        resultsSummaryBuilder: (context, state, screenCtx) {
          if (state.summariesQueryType !=
              EnrollmentSummaryQueryType.byAcademicInfo) {
            return const SizedBox.shrink();
          }

          return EnrollmentResultsBar(
            count: state.summariesTotalElements,
            isLoading: state.summariesStatus == EnrollmentLoadStatus.loading,
            showStatusBadge: false,
            onRefresh: screenCtx.onRefreshRequested,
            onViewModeChanged: _onViewModeChanged,
            currentViewMode: _preferredViewMode,
          );
        },
        // Routage du tap, miroir exact de ReRegistrationsPage :
        //  - candidat brut (`enrollmentId` vide) → seed d'un brouillon PRE
        //    depuis le vivier `ref_pre_enrollments` (origine preRegistration) ;
        //  - dossier déjà existant (COMPLETED ou finalisé) → consultation
        //    local-first (origine firstRegistration, lecture seule).
        // Le cas DRAFT (reprise éditable) est routé en amont par le scaffold sur
        // `summary.isLocalDraft` → `localDraftResume`.
        detailIntentFactory: (summary) => summary.enrollmentId.isEmpty
            ? EnrollmentDetailIntent.preRegistration(
                enrollmentId: summary.enrollmentId,
                studentId: summary.student.id,
              )
            : EnrollmentDetailIntent(
                origin: EnrollmentDetailOrigin.firstRegistration,
                enrollmentId: summary.enrollmentId,
                studentId: summary.student.id,
                status: summary.status,
              ),
        showEmptyBeforeSearchWhen: (state) =>
            state.summariesQueryType !=
            EnrollmentSummaryQueryType.byAcademicInfo,
        emptyBeforeSearchBuilder: (_, _) =>
            const PreRegistrationEmptyBeforeSearch(),
      ),
    );
  }

  Widget _buildCurrentYearBootstrap(
    BuildContext context,
    Widget Function(BuildContext context, EnrollmentScreenContext ctx) onReady,
  ) {
    return BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
      builder: (context, academicYearState) {
        final schoolId = context.select(
          (AuthBloc bloc) => bloc.state.user?.schoolId ?? '',
        );

        if (academicYearState.status == AcademicYearContextLoadStatus.loading ||
            academicYearState.status == AcademicYearContextLoadStatus.initial) {
          return const Center(
            child: Padding(
              padding: EnrollmentPageLayout.loadingPadding,
              child: CircularProgressIndicator(),
            ),
          );
        }

        final academicYearId = academicYearState.context?.academicYear.id ?? '';
        if (academicYearState.status != AcademicYearContextLoadStatus.success ||
            schoolId.isEmpty ||
            academicYearId.isEmpty) {
          return BootstrapContextError(
            onLogout: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          );
        }

        final isLoading = context.select(
          (EnrollmentLocalListBloc bloc) =>
              bloc.state.summariesStatus == EnrollmentLoadStatus.loading,
        );

        return onReady(
          context,
          EnrollmentScreenContext(
            schoolId: schoolId,
            academicYearId: academicYearId,
            isLoading: isLoading,
            onRefreshRequested: _onResetSearch,
            preferredViewMode: _preferredViewMode,
            onSortToggled: _onSortToggled,
            onViewModeChanged: _onViewModeChanged,
            onResetSearchRequested: _onResetSearch,
            onReconnectRequested: _onReconnect,
            onContactAdminRequested: _contactAdmin,
          ),
        );
      },
    );
  }

  Widget _buildAcademicSearchSection(
    BuildContext context,
    EnrollmentScreenContext ctx,
    EnrollmentSearchDispatcher dispatch,
  ) {
    final academicYearState = context.read<AcademicYearContextBloc>().state;
    final academicOptions = PreRegistrationsPageHelpers.buildAcademicOptions(
      academicYearState.context?.schoolLevelGroups ?? const [],
    );

    return PreRegistrationSearchForm(
      options: academicOptions,
      isLoading: ctx.isLoading,
      dispatch: dispatch,
    );
  }

  void _onViewModeChanged(EnrollmentListingViewMode mode) {
    if (_preferredViewMode == mode) {
      return;
    }
    setState(() => _preferredViewMode = mode);
  }

  void _onSortToggled() {
    setState(() {});
  }

  Future<void> _onResetSearch() async {
    context.read<EnrollmentLocalListBloc>().add(
      const LocalListRefreshRequested(),
    );
  }

  void _onReconnect() {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  Future<void> _contactAdmin() async {
    final uri = Uri(scheme: 'mailto', path: _adminEmail);
    await launchUrl(uri);
  }
}
