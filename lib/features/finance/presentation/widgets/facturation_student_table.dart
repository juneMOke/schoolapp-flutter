import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_error_state.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_data_table.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_search_invitation_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/states/facturation_results_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Adapte l'état BLoC vers la config de [FacturationDataTable].
///
/// Responsabilité unique : écouter [EnrollmentBloc] et router vers le bon
/// widget selon l'état courant. Tout rendu est déléguée à [FacturationDataTable].
class FacturationStudentTable extends StatelessWidget {
  /// Appelé quand l'icône "œil" est tapée.
  /// [levelId] provient du dernier critère de recherche stocké dans l'état BLoC.
  final void Function(EnrollmentSummary summary, String levelId)
  onViewRequested;

  const FacturationStudentTable({super.key, required this.onViewRequested});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<EnrollmentBloc, EnrollmentState>(
      buildWhen: _shouldBuild,
      builder: (context, state) {
        // Aucune recherche byAcademicInfo lancée → invitation à chercher
        if (state.summariesQueryType !=
            EnrollmentSummaryQueryType.byAcademicInfo) {
          return const FacturationSearchInvitationCard();
        }

        final levelId = state.lastSummariesQuery?.schoolLevelId ?? '';
        final isLoading = state.summariesStatus == EnrollmentLoadStatus.loading;
        final isError = state.summariesStatus == EnrollmentLoadStatus.failure;
        final isEmpty =
            state.summariesStatus == EnrollmentLoadStatus.success &&
            state.summaries.isEmpty;

        // Échec de la recherche → carte d'erreur Eteelo (même composant commun
        // que la liste des inscriptions ; messages génériques i18n).
        if (isError) {
          return AnimatedSwitcher(
            duration: AppMotion.layout,
            switchInCurve: AppMotion.outCurve,
            switchOutCurve: AppMotion.inCurve,
            child: EnrollmentResultsErrorState(
              key: const ValueKey('facturation-results-error'),
              type: state.summariesErrorType ?? EnrollmentErrorType.unknown,
              message: state.errorMessage,
              onRetry: () => context.read<EnrollmentBloc>().add(
                const EnrollmentSummariesRefreshRequested(),
              ),
              onReconnect: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            ),
          );
        }

        // Recherche aboutie mais sans résultat → carte « aucun résultat »
        // (même composant commun que la liste des inscriptions).
        if (isEmpty) {
          return AnimatedSwitcher(
            duration: AppMotion.layout,
            switchInCurve: AppMotion.outCurve,
            switchOutCurve: AppMotion.inCurve,
            child: FacturationResultsEmptyState(
              key: const ValueKey('facturation-results-empty'),
              criteria: _buildCriteria(state, l10n),
            ),
          );
        }

        return AnimatedSwitcher(
          duration: AppMotion.layout,
          switchInCurve: AppMotion.outCurve,
          switchOutCurve: AppMotion.inCurve,
          child: FacturationDataTable(
            key: ValueKey(state.summariesStatus),
            summaries: state.summaries,
            totalCount: state.summariesTotalElements,
            isLoading: isLoading,
            isError: isError,
            loadingLabel: l10n.loadingStudents,
            errorLabel: state.errorMessage,
            emptyLabel: _buildEmptyLabel(state, l10n),
            showPagination: true,
            currentPage: state.summariesPage + 1,
            totalPages: state.summariesTotalPages,
            pageSize: state.summariesSize,
            onPreviousPage: () => context.read<EnrollmentBloc>().add(
              EnrollmentSummariesPageRequested(page: state.summariesPage - 1),
            ),
            onNextPage: () => context.read<EnrollmentBloc>().add(
              EnrollmentSummariesPageRequested(page: state.summariesPage + 1),
            ),
            pageLabelBuilder: (current, total) =>
                l10n.paginationPageIndicator(current, total),
            onViewRequested: (s) => onViewRequested(s, levelId),
          ),
        );
      },
    );
  }

  /// Construit les puces de critères (nom / post-nom / prénom) à partir de la
  /// dernière requête, pour rappeler à l'utilisateur ce qui a été recherché.
  List<String> _buildCriteria(EnrollmentState state, AppLocalizations l10n) {
    final query = state.lastSummariesQuery;
    if (query == null) {
      return const <String>[];
    }

    final chips = <String>[];
    void addIfNotEmpty(String label, String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        chips.add('$label: $trimmed');
      }
    }

    addIfNotEmpty(l10n.lastName, query.lastName);
    addIfNotEmpty(l10n.surname, query.surname);
    addIfNotEmpty(l10n.firstName, query.firstName);
    return chips;
  }

  String _buildEmptyLabel(EnrollmentState state, AppLocalizations l10n) {
    return switch (state.summariesStatus) {
      EnrollmentLoadStatus.initial => l10n.noResultsFound,
      EnrollmentLoadStatus.success => l10n.facturationNoResultsDescription,
      _ => l10n.facturationNoResultsDescription,
    };
  }

  static bool _shouldBuild(EnrollmentState prev, EnrollmentState curr) =>
      prev.summariesQueryType != curr.summariesQueryType ||
      prev.summariesStatus != curr.summariesStatus ||
      prev.summaries != curr.summaries ||
      prev.summariesTotalElements != curr.summariesTotalElements ||
      prev.summariesTotalPages != curr.summariesTotalPages ||
      prev.summariesPage != curr.summariesPage ||
      prev.summariesErrorType != curr.summariesErrorType ||
      prev.errorMessage != curr.errorMessage;
}
