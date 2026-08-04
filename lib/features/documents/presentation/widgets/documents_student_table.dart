import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/search/search_invitation_card.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/documents_data_table.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/states/documents_results_empty_state.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Zone de résultats de la liste Documents.
///
/// Responsabilité unique : lire [EnrollmentLocalListBloc] et router vers le bon
/// état — invite, chargement, vide, erreur, tableau. Aucun rendu propre : tout
/// passe par les widgets partagés imposés par la règle #10.
class DocumentsStudentTable extends StatelessWidget {
  final ValueChanged<EnrollmentSummary> onCatalogRequested;

  const DocumentsStudentTable({super.key, required this.onCatalogRequested});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<EnrollmentLocalListBloc, EnrollmentLocalListState>(
      buildWhen: _shouldBuild,
      builder: (context, state) {
        // Aucune recherche lancée : on invite plutôt que d'afficher un tableau
        // vide, qui se lirait comme « cet élève n'a rien ».
        if (state.summariesQueryType !=
            EnrollmentSummaryQueryType.byAcademicInfo) {
          return SearchInvitationCard(
            icon: Icons.folder_shared_outlined,
            title: l10n.documentsSearchInvitationTitle,
            message: l10n.documentsSearchInvitationMessage,
          );
        }

        final isLoading = state.summariesStatus == EnrollmentLoadStatus.loading;
        final isError = state.summariesStatus == EnrollmentLoadStatus.failure;
        final isEmpty =
            state.summariesStatus == EnrollmentLoadStatus.success &&
            state.summaries.isEmpty;

        if (isError) {
          return AnimatedSwitcher(
            duration: AppMotion.layout,
            switchInCurve: AppMotion.outCurve,
            switchOutCurve: AppMotion.inCurve,
            child: EnrollmentResultsErrorState(
              key: const ValueKey('documents-results-error'),
              type: state.summariesErrorType ?? EnrollmentErrorType.unknown,
              message: state.errorMessage,
              onRetry: () => context.read<EnrollmentLocalListBloc>().add(
                const LocalListRefreshRequested(),
              ),
              onReconnect: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            ),
          );
        }

        if (isEmpty) {
          return AnimatedSwitcher(
            duration: AppMotion.layout,
            switchInCurve: AppMotion.outCurve,
            switchOutCurve: AppMotion.inCurve,
            child: DocumentsResultsEmptyState(
              key: const ValueKey('documents-results-empty'),
              criteria: _buildCriteria(state, l10n),
            ),
          );
        }

        return AnimatedSwitcher(
          duration: AppMotion.layout,
          switchInCurve: AppMotion.outCurve,
          switchOutCurve: AppMotion.inCurve,
          child: DocumentsDataTable(
            key: ValueKey(state.summariesStatus),
            summaries: state.summaries,
            totalCount: state.summariesTotalElements,
            isLoading: isLoading,
            isError: isError,
            loadingLabel: l10n.loadingStudents,
            errorLabel: state.errorMessage,
            emptyLabel: l10n.documentsNoResultsDescription,
            showPagination: true,
            currentPage: state.summariesPage + 1,
            totalPages: state.summariesTotalPages,
            pageSize: state.summariesSize,
            onPreviousPage: () => context.read<EnrollmentLocalListBloc>().add(
              LocalListPageRequested(page: state.summariesPage - 1),
            ),
            onNextPage: () => context.read<EnrollmentLocalListBloc>().add(
              LocalListPageRequested(page: state.summariesPage + 1),
            ),
            pageLabelBuilder: (current, total) =>
                l10n.paginationPageIndicator(current, total),
            onCatalogRequested: onCatalogRequested,
          ),
        );
      },
    );
  }

  /// Puces rappelant ce qui a été cherché, pour que l'état vide soit lisible.
  List<String> _buildCriteria(
    EnrollmentLocalListState state,
    AppLocalizations l10n,
  ) {
    final query = state.lastSummariesQuery;
    if (query == null) return const <String>[];

    final chips = <String>[];
    void addIfNotEmpty(String label, String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) chips.add('$label: $trimmed');
    }

    addIfNotEmpty(l10n.lastName, query.lastName);
    addIfNotEmpty(l10n.surname, query.surname);
    addIfNotEmpty(l10n.firstName, query.firstName);
    return chips;
  }

  static bool _shouldBuild(
    EnrollmentLocalListState prev,
    EnrollmentLocalListState curr,
  ) =>
      prev.summariesQueryType != curr.summariesQueryType ||
      prev.summariesStatus != curr.summariesStatus ||
      prev.summaries != curr.summaries ||
      prev.summariesTotalElements != curr.summariesTotalElements ||
      prev.summariesTotalPages != curr.summariesTotalPages ||
      prev.summariesPage != curr.summariesPage ||
      prev.summariesErrorType != curr.summariesErrorType ||
      prev.errorMessage != curr.errorMessage;
}
