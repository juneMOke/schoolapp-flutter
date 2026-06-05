import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/core/components/buttons/eteelo_fab.dart';
import 'package:school_app_flutter/core/components/buttons/eteelo_fab_location.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_search_command_handlers.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_listing_view_mode.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_current_year_bootstrap_builder.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_scaffold.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_results_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class FirstRegistrationPage extends StatefulWidget {
  const FirstRegistrationPage({super.key});

  @override
  State<FirstRegistrationPage> createState() => _FirstRegistrationPageState();
}

class _FirstRegistrationPageState extends State<FirstRegistrationPage> {
  String _effectiveStatus = 'IN_PROGRESS';
  EnrollmentListingViewMode _preferredViewMode = EnrollmentListingViewMode.auto;
  static const String _adminEmail = 'support@school.local';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPageBackground(
      style: AppPageBackgroundStyle.flat,
      flatBackgroundColor: AppColors.surface,
      scrollable: true,
      floatingActionButton: EteeloFab(
        label: l10n.firstRegistrationNewEnrollmentAction,
        icon: Icons.add,
        onPressed: () => _openNewEnrollment(context),
      ),
      floatingActionButtonLocation: const EndFloatEdgeOffsetFabLocation(),
      child: EnrollmentListingPageScaffold(
        readyKey: 'first-reg-content',
        bootstrapBuilder: (context, onReady) =>
            EnrollmentCurrentYearBootstrapBuilder(
              status: _effectiveStatus,
              onReady: (context, screenCtx) => onReady(
                context,
                EnrollmentScreenContext(
                  schoolId: screenCtx.schoolId,
                  academicYearId: screenCtx.academicYearId,
                  isLoading: screenCtx.isLoading,
                  onRefreshRequested: screenCtx.onRefreshRequested,
                  layout: screenCtx.layout,
                  preferredViewMode: _preferredViewMode,
                  onSortToggled: _onSortToggled,
                  onViewModeChanged: _onViewModeChanged,
                  onResetSearchRequested: _onResetSearch,
                  onCreateEnrollmentRequested: () =>
                      _openNewEnrollment(context),
                  onReconnectRequested: () {
                    context.read<AuthBloc>().add(const AuthLogoutRequested());
                  },
                  onContactAdminRequested: _contactAdmin,
                ),
              ),
            ),
        searchSectionBuilder: (context, screenCtx, dispatch) => SearchForm(
          academicYearId: screenCtx.academicYearId,
          status: _effectiveStatus,
          isLoading: screenCtx.isLoading,
          dispatch: dispatch,
          subtitle: l10n.searchFormSubtitleFirstRegistration,
          showStatusFilter: true,
          onStatusChanged: (newStatus) {
            setState(() => _effectiveStatus = newStatus);
            dispatch(StandardSearchCommand(status: newStatus));
          },
        ),
        onSearchCommand:
            EnrollmentSearchCommandHandlers.dispatchThroughEnrollmentBloc,
        resultsSummaryBuilder: (context, state, screenCtx) =>
            EnrollmentResultsBar(
              count: state.summariesTotalElements,
              isLoading: state.summariesStatus == EnrollmentLoadStatus.loading,
              statusLabel: _effectiveStatus,
              showStatusBadge: true,
              onRefresh: screenCtx.onRefreshRequested,
              onViewModeChanged: _onViewModeChanged,
              currentViewMode: _preferredViewMode,
            ),
        detailIntentFactory: (summary) => EnrollmentDetailIntent(
          origin: EnrollmentDetailOrigin.firstRegistration,
          enrollmentId: summary.enrollmentId,
          status: summary.status,
        ),
      ),
    );
  }

  void _openNewEnrollment(BuildContext context) {
    context.go(
      '${EnrollmentConstants.enrollmentDetailRoute}/new',
      extra: const EnrollmentDetailIntent.newFirstRegistration(),
    );
  }

  void _onResetSearch() {
    context.read<EnrollmentBloc>().add(
      const EnrollmentSummariesRefreshRequested(),
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

  Future<void> _contactAdmin() async {
    final uri = Uri(scheme: 'mailto', path: _adminEmail);
    await launchUrl(uri);
  }
}
