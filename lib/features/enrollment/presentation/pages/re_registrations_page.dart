import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_previous_year_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_listing_view_mode.dart';
import 'package:school_app_flutter/features/enrollment/presentation/constants/enrollment_page_layout.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_search_command_handlers.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/re_registrations_page_helpers.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_scaffold.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/re_registration_search_form.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/re_registration/re_registration_empty_before_search.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_results_bar.dart';

class ReRegistrationsPage extends StatefulWidget {
  const ReRegistrationsPage({super.key});

  @override
  State<ReRegistrationsPage> createState() => _ReRegistrationsPageState();
}

class _ReRegistrationsPageState extends State<ReRegistrationsPage> {
  EnrollmentListingViewMode _preferredViewMode = EnrollmentListingViewMode.auto;
  static const String _adminEmail = 'support@school.local';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BootstrapPreviousYearBloc>().add(
        const BootstrapContextLocalRequested(
          key: AppConstants.bootstrapPreviousYearPayloadKey,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      scrollable: true,
      child: EnrollmentListingPageScaffold(
        readyKey: 're-reg-content',
        bootstrapBuilder: _buildPreviousYearBootstrap,
        searchSectionBuilder: _buildAcademicSearchSection,
        onSearchCommand:
            EnrollmentSearchCommandHandlers.dispatchThroughLocalListBloc,
        // Read-your-writes : au retour du détail, on rafraîchit le vivier — le
        // candidat qu'on vient de commencer à réinscrire réapparaît alors comme
        // son dossier (repris au tap), plus comme candidat frais.
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
            onRefresh: screenCtx.onRefreshRequested,
            showStatusBadge: false,
            onViewModeChanged: _onViewModeChanged,
            currentViewMode: _preferredViewMode,
          );
        },
        // Routage du tap (option b : éditable ⟺ brouillon DRAFT) :
        //  - candidat brut (`enrollmentId` vide) → seed d'un brouillon RE depuis
        //    la cohorte N-1 (origine reRegistration) ;
        //  - dossier FINALISÉ → consultation local-first (origine
        //    firstRegistration : lecture seule si non synchronisé / terminé).
        // Le cas DRAFT (reprise éditable) est routé en amont par le scaffold sur
        // `summary.isLocalDraft` → `localDraftResume`.
        detailIntentFactory: (summary) => summary.enrollmentId.isEmpty
            ? EnrollmentDetailIntent.reRegistration(
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
            const ReRegistrationEmptyBeforeSearch(),
      ),
    );
  }

  Widget _buildPreviousYearBootstrap(
    BuildContext context,
    Widget Function(BuildContext context, EnrollmentScreenContext ctx) onReady,
  ) {
    return BlocBuilder<BootstrapPreviousYearBloc, BootstrapContextState>(
      builder: (context, bootstrapState) {
        final schoolId = context.select(
          (AuthBloc bloc) => bloc.state.user?.schoolId ?? '',
        );

        if (bootstrapState.status == BootstrapContextLoadStatus.loading ||
            bootstrapState.status == BootstrapContextLoadStatus.initial) {
          return const Center(
            child: Padding(
              padding: EnrollmentPageLayout.loadingPadding,
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (bootstrapState.status != BootstrapContextLoadStatus.success ||
            schoolId.isEmpty) {
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
            academicYearId: '',
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
    final bootstrapState = context.read<BootstrapPreviousYearBloc>().state;
    final academicOptions = ReRegistrationsPageHelpers.buildAcademicOptions(
      bootstrapState.bootstrap?.schoolLevelGroups ?? const [],
    );

    return ReRegistrationSearchForm(
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
