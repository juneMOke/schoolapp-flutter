import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/core/components/buttons/eteelo_fab.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_search_command_handlers.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_current_year_bootstrap_builder.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_scaffold.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_results_info_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FirstRegistrationPage extends StatefulWidget {
  const FirstRegistrationPage({super.key});

  @override
  State<FirstRegistrationPage> createState() => _FirstRegistrationPageState();
}

class _FirstRegistrationPageState extends State<FirstRegistrationPage> {
  String _effectiveStatus = 'IN_PROGRESS';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPageBackground(
      scrollable: true,
      floatingActionButton: EteeloFab(
        label: l10n.firstRegistrationNewEnrollmentAction,
        icon: Icons.add,
        onPressed: () {
          context.go(
            '${EnrollmentConstants.enrollmentDetailRoute}/new',
            extra: const EnrollmentDetailIntent.newFirstRegistration(),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      child: EnrollmentListingPageScaffold(
        readyKey: 'first-reg-content',
        bootstrapBuilder: (context, onReady) =>
            EnrollmentCurrentYearBootstrapBuilder(
              status: _effectiveStatus,
              onReady: onReady,
            ),
        searchSectionBuilder: (context, screenCtx, dispatch) => SearchForm(
          academicYearId: screenCtx.academicYearId,
          status: _effectiveStatus,
          isLoading: screenCtx.isLoading,
          dispatch: dispatch,
          showStatusFilter: true,
          onStatusChanged: (newStatus) {
            setState(() => _effectiveStatus = newStatus);
          },
        ),
        onSearchCommand:
            EnrollmentSearchCommandHandlers.dispatchThroughEnrollmentBloc,
        resultsSummaryBuilder: (context, state, screenCtx) =>
            EnrollmentResultsInfoBar(
              count: state.summariesTotalElements,
              isLoading: state.summariesStatus == EnrollmentLoadStatus.loading,
              onRefresh: screenCtx.onRefreshRequested,
              statusLabel: _effectiveStatus,
              showStatusBadge: false,
            ),
        detailIntentFactory: (summary) => EnrollmentDetailIntent(
          origin: EnrollmentDetailOrigin.firstRegistration,
          enrollmentId: summary.enrollmentId,
          status: summary.status,
        ),
      ),
    );
  }
}
