import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_search_command_handlers.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_current_year_bootstrap_builder.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_scaffold.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_results_info_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form.dart';

class PreRegistrationsPage extends StatelessWidget {
  const PreRegistrationsPage({super.key});

  static const String _status = 'PRE_REGISTERED';

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      scrollable: true,
      child: EnrollmentListingPageScaffold(
        readyKey: 'pre-reg-content',
        bootstrapBuilder: (context, onReady) =>
            EnrollmentCurrentYearBootstrapBuilder(
              status: _status,
              onReady: onReady,
            ),
        searchSectionBuilder: (context, screenCtx, dispatch) => SearchForm(
          academicYearId: screenCtx.academicYearId,
          status: _status,
          isLoading: screenCtx.isLoading,
          dispatch: dispatch,
        ),
        onSearchCommand:
            EnrollmentSearchCommandHandlers.dispatchThroughEnrollmentBloc,
        resultsSummaryBuilder: (context, state, screenCtx) =>
            EnrollmentResultsInfoBar(
              count: state.summariesTotalElements,
              isLoading: state.summariesStatus == EnrollmentLoadStatus.loading,
              onRefresh: screenCtx.onRefreshRequested,
              statusLabel: _status,
              showStatusBadge: false,
            ),
        detailIntentFactory: (summary) =>
            EnrollmentDetailIntent.preRegistration(
              enrollmentId: summary.enrollmentId,
            ),
      ),
    );
  }
}
