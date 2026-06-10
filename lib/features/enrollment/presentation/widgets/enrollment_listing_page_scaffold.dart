import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/constants/enrollment_page_layout.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_listing_layout.dart';
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

  /// Slot optionnel rendu sous le tableau, dans le flux scrollable de la page.
  /// Utilisé p. ex. par la première inscription pour poser l'action de création
  /// en bouton inline (vue tablette) plutôt qu'en FAB flottant masquant la
  /// pagination. N'apparaît qu'une fois le bootstrap prêt (pas en loading/erreur).
  final Widget Function(
    BuildContext context,
    EnrollmentScreenContext screenCtx,
  )?
  resultsFooterBuilder;
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
    this.resultsFooterBuilder,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveCtx = EnrollmentScreenContext(
          schoolId: screenCtx.schoolId,
          academicYearId: screenCtx.academicYearId,
          isLoading: screenCtx.isLoading,
          onRefreshRequested: screenCtx.onRefreshRequested,
          layout: EnrollmentListingLayout.fromWidth(constraints.maxWidth),
          preferredViewMode: screenCtx.preferredViewMode,
          onSortToggled: screenCtx.onSortToggled,
          onViewModeChanged: screenCtx.onViewModeChanged,
          onResetSearchRequested: screenCtx.onResetSearchRequested,
          onCreateEnrollmentRequested: screenCtx.onCreateEnrollmentRequested,
          onReconnectRequested: screenCtx.onReconnectRequested,
          onContactAdminRequested: screenCtx.onContactAdminRequested,
        );

        return AnimatedSwitcher(
          duration: AppMotion.standard,
          switchInCurve: AppMotion.outCurve,
          switchOutCurve: AppMotion.inCurve,
          child: Column(
            key: ValueKey<String>(readyKey),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchSection(effectiveCtx),
              if (resultsSummaryBuilder != null) ...[
                const SizedBox(
                  height: EnrollmentPageLayout.searchToSummarySpacing,
                ),
                _buildResultsSummarySection(effectiveCtx),
                const SizedBox(
                  height: EnrollmentPageLayout.summaryToResultsSpacing,
                ),
              ] else ...[
                const SizedBox(
                  height: EnrollmentPageLayout.searchToSummarySpacing,
                ),
              ],
              _buildResultsSection(effectiveCtx),
              if (resultsFooterBuilder != null) ...[
                const SizedBox(
                  height: EnrollmentPageLayout.resultsToFooterSpacing,
                ),
                resultsFooterBuilder!(context, effectiveCtx),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchSection(EnrollmentScreenContext screenCtx) {
    return BlocBuilder<EnrollmentBloc, EnrollmentState>(
      buildWhen: (previous, current) =>
          previous.summariesStatus != current.summariesStatus,
      builder: (context, state) {
        final ctx = EnrollmentScreenContext(
          schoolId: screenCtx.schoolId,
          academicYearId: screenCtx.academicYearId,
          isLoading: state.summariesStatus == EnrollmentLoadStatus.loading,
          onRefreshRequested: screenCtx.onRefreshRequested,
          layout: screenCtx.layout,
          preferredViewMode: screenCtx.preferredViewMode,
          onSortToggled: screenCtx.onSortToggled,
          onViewModeChanged: screenCtx.onViewModeChanged,
          onResetSearchRequested: screenCtx.onResetSearchRequested,
          onCreateEnrollmentRequested: screenCtx.onCreateEnrollmentRequested,
          onReconnectRequested: screenCtx.onReconnectRequested,
          onContactAdminRequested: screenCtx.onContactAdminRequested,
        );

        return searchSectionBuilder(context, ctx, (command) {
          onSearchCommand(context, command, ctx);
        });
      },
    );
  }

  Widget _buildResultsSection(EnrollmentScreenContext screenCtx) {
    return BlocBuilder<EnrollmentBloc, EnrollmentState>(
      builder: (context, state) {
        final shouldShowEmpty = showEmptyBeforeSearchWhen?.call(state) ?? false;
        if (shouldShowEmpty && emptyBeforeSearchBuilder != null) {
          return emptyBeforeSearchBuilder!(context, state);
        }

        return EnrollmentDataTableContainer(
          layout: screenCtx.layout,
          preferredViewMode: screenCtx.preferredViewMode,
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
          onRefresh: screenCtx.onRefreshRequested,
          onSortToggled: screenCtx.onSortToggled,
          onViewModeChanged: screenCtx.onViewModeChanged,
          onResetSearchRequested: screenCtx.onResetSearchRequested,
          onCreateEnrollmentRequested: screenCtx.onCreateEnrollmentRequested,
          onReconnectRequested: screenCtx.onReconnectRequested,
          onContactAdminRequested: screenCtx.onContactAdminRequested,
        );
      },
    );
  }

  Widget _buildResultsSummarySection(EnrollmentScreenContext screenCtx) {
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
