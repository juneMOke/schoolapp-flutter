import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_listing_view_mode.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_search_command_handlers.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_current_year_bootstrap_builder.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_scaffold.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_results_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class PreRegistrationsPage extends StatefulWidget {
  const PreRegistrationsPage({super.key});

  @override
  State<PreRegistrationsPage> createState() => _PreRegistrationsPageState();
}

class _PreRegistrationsPageState extends State<PreRegistrationsPage> {
  EnrollmentListingViewMode _preferredViewMode = EnrollmentListingViewMode.auto;
  static const String _status = 'PRE_REGISTERED';
  // Scope PAR TYPE : la page ne montre que les vraies pré-inscriptions. Garde
  // explicite indépendante du status (RE_ENROLLMENT est désormais IN_PROGRESS
  // — cf. LocalDraftResumeDetailPolicy.draftStatus, dérivé du type et non lu
  // depuis un status persisté, donc un dossier RE legacy encore en
  // PRE_REGISTERED se recale de lui-même au prochain re-save).
  static const String _enrollmentType = 'PRE_ENROLLMENT';
  static const String _adminEmail = 'support@school.local';

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      scrollable: true,
      child: EnrollmentListingPageScaffold(
        readyKey: 'pre-reg-content',
        bootstrapBuilder: (context, onReady) =>
            EnrollmentCurrentYearBootstrapBuilder(
              status: _status,
              enrollmentType: _enrollmentType,
              onReady: (context, screenCtx) => onReady(
                context,
                EnrollmentScreenContext(
                  schoolId: screenCtx.schoolId,
                  academicYearId: screenCtx.academicYearId,
                  isLoading: screenCtx.isLoading,
                  onRefreshRequested: screenCtx.onRefreshRequested,
                  preferredViewMode: _preferredViewMode,
                  onSortToggled: _onSortToggled,
                  onViewModeChanged: _onViewModeChanged,
                  onResetSearchRequested: _onResetSearch,
                  onReconnectRequested: _onReconnect,
                  onContactAdminRequested: _contactAdmin,
                  enrollmentType: _enrollmentType,
                ),
              ),
            ),
        searchSectionBuilder: (context, screenCtx, dispatch) => SearchForm(
          academicYearId: screenCtx.academicYearId,
          status: _status,
          isLoading: screenCtx.isLoading,
          dispatch: dispatch,
          subtitle: AppLocalizations.of(
            context,
          )!.searchFormSubtitlePreRegistration,
        ),
        onSearchCommand:
            EnrollmentSearchCommandHandlers.dispatchThroughLocalListBloc,
        resultsSummaryBuilder: (context, state, screenCtx) =>
            EnrollmentResultsBar(
              count: state.summariesTotalElements,
              isLoading: state.summariesStatus == EnrollmentLoadStatus.loading,
              showStatusBadge: false,
              onRefresh: screenCtx.onRefreshRequested,
              onViewModeChanged: _onViewModeChanged,
              currentViewMode: _preferredViewMode,
            ),
        // Consultation locale d'une pré-inscription (parallèle au fix #19 de la
        // Première inscription). Le listing lit la table locale `enrollments` ;
        // le dossier affiché est donc directement lisible par
        // `LoadLocalEnrollmentDetail` (même table, même id). L'ancienne origine
        // `preRegistration` seedait un brouillon depuis `ref_pre_enrollments`
        // (snapshot du pull, DORMANT) → id non concordant → « Dossier introuvable
        // en local ». On route donc, comme la Réinscription le fait pour ses
        // dossiers finalisés (re_registrations_page), vers l'origine
        // `firstRegistration` = consultation LECTURE SEULE 100 % locale générique.
        // Le scaffold route en amont les brouillons DRAFT (`isLocalDraft`) vers
        // `localDraftResume` (reprise éditable). La conversion « pré → première »
        // reste différée jusqu'à l'activation du pull des préinscriptions
        // (machinerie seed conservée dormante).
        detailIntentFactory: (summary) => EnrollmentDetailIntent(
          origin: EnrollmentDetailOrigin.firstRegistration,
          enrollmentId: summary.enrollmentId,
          studentId: summary.student.id,
          status: summary.status,
        ),
      ),
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

  void _onResetSearch() {
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
