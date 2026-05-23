import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/constants/enrollment_page_layout.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_data_table_container.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';

class EnrollmentListingPageScaffold extends StatelessWidget {
  final EnrollmentBootstrapBuilder bootstrapBuilder;
  final EnrollmentSearchSectionBuilder searchSectionBuilder;
  final EnrollmentSearchCommandHandler onSearchCommand;
  final EnrollmentDetailIntentFactory detailIntentFactory;
  final EnrollmentEmptyStateBuilder? emptyBeforeSearchBuilder;
  final EnrollmentResultsSummaryBuilder? resultsSummaryBuilder;
  final bool Function(EnrollmentState state)? showEmptyBeforeSearchWhen;
  final String readyKey;

  const EnrollmentListingPageScaffold({
    super.key,
    required this.bootstrapBuilder,
    required this.searchSectionBuilder,
    required this.onSearchCommand,
    required this.detailIntentFactory,
    this.emptyBeforeSearchBuilder,
    this.resultsSummaryBuilder,
    this.showEmptyBeforeSearchWhen,
    this.readyKey = 'enrollment-list-ready',
  });

  @override
  Widget build(BuildContext context) {
    return bootstrapBuilder(context, _buildReadyContent);
  }

  Widget _buildReadyContent(
    BuildContext context,
    EnrollmentScreenContext screenCtx,
  ) {
    return AnimatedSwitcher(
      duration: AppMotion.standard,
      switchInCurve: AppMotion.outCurve,
      switchOutCurve: AppMotion.inCurve,
      child: Column(
        key: ValueKey<String>(readyKey),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchSection(screenCtx),
          if (resultsSummaryBuilder != null) ...[
            const SizedBox(height: EnrollmentPageLayout.sectionSpacing),
            _buildResultsSummarySection(screenCtx),
          ],
          const SizedBox(height: EnrollmentPageLayout.sectionSpacing),
          _buildResultsSection(),
        ],
      ),
    );
  }

  Widget _buildSearchSection(
    EnrollmentScreenContext screenCtx,
  ) {
    return BlocBuilder<EnrollmentBloc, EnrollmentState>(
      buildWhen: (previous, current) =>
          previous.summariesStatus != current.summariesStatus,
      builder: (context, state) {
        final ctx = EnrollmentScreenContext(
          schoolId: screenCtx.schoolId,
          academicYearId: screenCtx.academicYearId,
          isLoading: state.summariesStatus == EnrollmentLoadStatus.loading,
        );

        return searchSectionBuilder(context, ctx, (command) {
          onSearchCommand(context, command, ctx);
        });
      },
    );
  }

  Widget _buildResultsSection() {
    return BlocBuilder<EnrollmentBloc, EnrollmentState>(
      builder: (context, state) {
        final shouldShowEmpty = showEmptyBeforeSearchWhen?.call(state) ?? false;
        if (shouldShowEmpty && emptyBeforeSearchBuilder != null) {
          return emptyBeforeSearchBuilder!(context, state);
        }

        return EnrollmentDataTableContainer(
          onViewRequested: (summary) {
            final intent = detailIntentFactory(summary);
            context.push(
              Uri(
                path:
                    '${EnrollmentConstants.enrollmentDetailRoute}/${summary.enrollmentId}',
                queryParameters: intent.toQueryParameters(),
              ).toString(),
              extra: intent,
            );
          },
        );
      },
    );
  }

  Widget _buildResultsSummarySection(
    EnrollmentScreenContext screenCtx,
  ) {
    return BlocBuilder<EnrollmentBloc, EnrollmentState>(
      builder: (context, state) {
        final builder = resultsSummaryBuilder;
        if (builder == null) {
          return const SizedBox.shrink();
        }
        return builder(context, state, screenCtx);
      },
    );
  }
}
