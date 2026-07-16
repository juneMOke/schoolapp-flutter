import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/constants/enrollment_page_layout.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_data_table_container.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';

class EnrollmentListingPageScaffold extends StatelessWidget {
  final EnrollmentBootstrapBuilder bootstrapBuilder;
  final EnrollmentSearchSectionBuilder searchSectionBuilder;
  final EnrollmentSearchCommandHandler onSearchCommand;
  final EnrollmentDetailIntentFactory detailIntentFactory;
  final EnrollmentEmptyStateBuilder? emptyBeforeSearchBuilder;
  final EnrollmentResultsSummaryBuilder? resultsSummaryBuilder;
  final bool Function(EnrollmentLocalListState state)?
  showEmptyBeforeSearchWhen;

  /// Rappel optionnel invoqué **au retour** du détail (pop). Utilisé par la
  /// réinscription pour rafraîchir la liste (read-your-writes) : un candidat
  /// qu'on vient de commencer à réinscrire réapparaît alors sous forme de son
  /// dossier (repris au tap), jamais comme candidat frais.
  final VoidCallback? onDetailReturned;

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
    this.onDetailReturned,
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
            const SizedBox(height: EnrollmentPageLayout.searchToSummarySpacing),
            _buildResultsSummarySection(screenCtx),
            const SizedBox(
              height: EnrollmentPageLayout.summaryToResultsSpacing,
            ),
          ] else ...[
            const SizedBox(height: EnrollmentPageLayout.searchToSummarySpacing),
          ],
          _buildResultsSection(screenCtx),
          if (resultsFooterBuilder != null) ...[
            const SizedBox(height: EnrollmentPageLayout.resultsToFooterSpacing),
            resultsFooterBuilder!(context, screenCtx),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchSection(EnrollmentScreenContext screenCtx) {
    return BlocBuilder<EnrollmentLocalListBloc, EnrollmentLocalListState>(
      buildWhen: (previous, current) =>
          previous.summariesStatus != current.summariesStatus,
      builder: (context, state) {
        final ctx = EnrollmentScreenContext(
          schoolId: screenCtx.schoolId,
          academicYearId: screenCtx.academicYearId,
          isLoading: state.summariesStatus == EnrollmentLoadStatus.loading,
          onRefreshRequested: screenCtx.onRefreshRequested,
          preferredViewMode: screenCtx.preferredViewMode,
          onSortToggled: screenCtx.onSortToggled,
          onViewModeChanged: screenCtx.onViewModeChanged,
          onResetSearchRequested: screenCtx.onResetSearchRequested,
          onCreateEnrollmentRequested: screenCtx.onCreateEnrollmentRequested,
          onReconnectRequested: screenCtx.onReconnectRequested,
          onContactAdminRequested: screenCtx.onContactAdminRequested,
          // Conservé pour que les recherches nom/DOB restent bornées au type de
          // la page (ex. Pré-inscriptions → PRE_ENROLLMENT).
          enrollmentType: screenCtx.enrollmentType,
        );

        return searchSectionBuilder(context, ctx, (command) {
          onSearchCommand(context, command, ctx);
        });
      },
    );
  }

  Widget _buildResultsSection(EnrollmentScreenContext screenCtx) {
    return BlocBuilder<EnrollmentLocalListBloc, EnrollmentLocalListState>(
      builder: (context, state) {
        final shouldShowEmpty = showEmptyBeforeSearchWhen?.call(state) ?? false;
        if (shouldShowEmpty && emptyBeforeSearchBuilder != null) {
          return emptyBeforeSearchBuilder!(context, state);
        }

        return EnrollmentDataTableContainer(
          preferredViewMode: screenCtx.preferredViewMode,
          onViewRequested: (summary) {
            // Brouillon local (DRAFT) → reprise du wizard, chargé depuis la base
            // locale par id (aucun GET serveur). Sinon comportement d'origine
            // (consultation / reprise serveur) fourni par la page-listing.
            final intent = summary.isLocalDraft
                ? EnrollmentDetailIntent.localDraftResume(
                    enrollmentId: summary.enrollmentId,
                    studentId: summary.student.id,
                  )
                : detailIntentFactory(summary);
            // Un candidat de réinscription n'a pas encore de dossier
            // (`enrollmentId` vide) : la route `:enrollmentId` exige un segment
            // NON vide (sinon go_router normalise `/detail/` → `/detail`, aucune
            // route → page d'erreur). Placeholder `new` (comme la primo-
            // inscription) ; l'intent porté par `extra` garde l'id réel et le
            // flux RE seede par `studentId`.
            final routeSegment = summary.enrollmentId.isEmpty
                ? 'new'
                : summary.enrollmentId;
            context
                .push(
                  Uri(
                    path:
                        '${EnrollmentConstants.enrollmentDetailRoute}/$routeSegment',
                    queryParameters: intent.toQueryParameters(),
                  ).toString(),
                  extra: intent,
                )
                .then((_) {
                  // Au retour du détail : rafraîchit la liste (read-your-writes).
                  if (context.mounted) onDetailReturned?.call();
                });
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
    return BlocBuilder<EnrollmentLocalListBloc, EnrollmentLocalListState>(
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
