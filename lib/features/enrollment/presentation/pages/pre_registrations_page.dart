import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_listing_view_mode.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
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
            EnrollmentSearchCommandHandlers.dispatchThroughEnrollmentBloc,
        resultsSummaryBuilder: (context, state, screenCtx) =>
            EnrollmentResultsBar(
              count: state.summariesTotalElements,
              isLoading: state.summariesStatus == EnrollmentLoadStatus.loading,
              showStatusBadge: false,
              onRefresh: screenCtx.onRefreshRequested,
              onViewModeChanged: _onViewModeChanged,
              currentViewMode: _preferredViewMode,
            ),
        detailIntentFactory: (summary) =>
            EnrollmentDetailIntent.preRegistration(
              enrollmentId: summary.enrollmentId,
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
    context.read<EnrollmentBloc>().add(
      const EnrollmentSummariesRefreshRequested(),
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
