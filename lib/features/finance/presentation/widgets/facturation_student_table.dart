import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_data_table.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_search_invitation_card.dart';
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
        final isLoading =
            state.summariesStatus == EnrollmentLoadStatus.loading;
        final isError = state.summariesStatus == EnrollmentLoadStatus.failure;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
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
            onPreviousPage: () => context.read<EnrollmentBloc>().add(
              EnrollmentSummariesPageRequested(page: state.summariesPage - 1),
            ),
            onNextPage: () => context.read<EnrollmentBloc>().add(
              EnrollmentSummariesPageRequested(page: state.summariesPage + 1),
            ),
            pageLabelBuilder: (current, total) =>
                l10n.enrollmentPageIndicator(current, total),
            onViewRequested: (s) => onViewRequested(s, levelId),
          ),
        );
      },
    );
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
      prev.errorMessage != curr.errorMessage;
}
