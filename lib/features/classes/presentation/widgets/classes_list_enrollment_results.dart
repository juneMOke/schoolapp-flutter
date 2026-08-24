import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_results_toolbar.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_students_table.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesListEnrollmentResults extends StatelessWidget {
  final ClassesListSearchRequest request;
  final EnrollmentLocalListState state;

  /// **Tous** les résultats de la recherche, pages confondues — et non
  /// `state.summaries`, qui n'en est que la page courante. C'est la table qui
  /// découpe, une fois le tri appliqué : lui donner la page rendrait le tri
  /// page-local (« trier par niveau » ne réordonnerait que les lignes déjà à
  /// l'écran). Le décompte et la pagination, eux, restent ceux de l'état.
  final List<EnrollmentSummary> summaries;
  final VoidCallback onExportPressed;
  final ValueChanged<int> onPageRequested;
  final ValueChanged<EnrollmentSummary> onViewRequested;

  const ClassesListEnrollmentResults({
    super.key,
    required this.request,
    required this.state,
    required this.summaries,
    required this.onExportPressed,
    required this.onPageRequested,
    required this.onViewRequested,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final byId = {for (final summary in summaries) summary.student.id: summary};
    final rows = summaries
        .map(
          (summary) => ClassesListStudentRow(
            id: summary.student.id,
            studentId: summary.student.id,
            lastName: summary.student.lastName,
            surname: summary.student.surname,
            firstName: summary.student.firstName,
            classroomLabel: request.selectedClassroom?.name ?? '',
            // Le niveau vient de la LIGNE, pas des critères : c'est ce qui
            // permet à une recherche par identité de le rendre.
            levelLabel: summary.schoolLevelName ?? '',
          ),
        )
        .toList(growable: false);

    final criteria = [
      request.selectedCycle?.label,
      request.selectedLevel?.label,
      request.selectedClassroom?.name,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');

    // Le décompte annoncé est celui de TOUS les résultats, pas de la page
    // affichée : sur une liste paginée, `summaries.length` plafonnerait à la
    // taille de page et annoncerait « 10 élèves trouvés » pour une classe de
    // quarante.
    final total = state.summariesTotalElements;
    final summary = criteria.isEmpty
        ? l10n.classesListResultsSummaryWithoutCriteria(total)
        : l10n.classesListResultsSummary(total, criteria);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClassesListResultsToolbar(
          summary: summary,
          canExport:
              state.summariesStatus == EnrollmentLoadStatus.success &&
              rows.isNotEmpty,
          onExportPressed: onExportPressed,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        AnimatedSwitcher(
          duration: AppMotion.standard,
          switchInCurve: AppMotion.outCurve,
          switchOutCurve: AppMotion.inCurve,
          child: _buildBody(l10n, rows, byId),
        ),
      ],
    );
  }

  Widget _buildBody(
    AppLocalizations l10n,
    List<ClassesListStudentRow> rows,
    Map<String, EnrollmentSummary> byId,
  ) {
    return ClassesListStudentsTable(
      key: ValueKey(state.summariesStatus),
      rows: rows,
      // Le niveau n'est une information de ligne que lorsqu'il n'est pas le
      // critère : en mode classe il est déjà annoncé au-dessus du tableau.
      showLevelColumn: request.isIdentityMode,
      totalCount: state.summariesTotalElements,
      // Le bloc pagine en 0-based, la table s'affiche en 1-based.
      currentPage: state.summariesPage + 1,
      totalPages: state.summariesTotalPages,
      pageSize: state.summariesSize,
      // Les deux callbacks partent toujours : c'est la barre de pagination qui
      // éteint le bouton en bout de course. Les retirer ici ferait disparaître
      // la pagination entière dès la première page.
      onPreviousPage: () => onPageRequested(state.summariesPage - 1),
      onNextPage: () => onPageRequested(state.summariesPage + 1),
      // Un tri réordonne tout le corpus : rester sur la page courante y
      // montrerait le milieu d'un ordre qu'on vient de demander.
      onSortChanged: () => onPageRequested(0),
      isLoading: state.summariesStatus == EnrollmentLoadStatus.loading,
      isError: state.summariesStatus == EnrollmentLoadStatus.failure,
      loadingLabel: l10n.loadingStudents,
      errorLabel: state.errorMessage ?? l10n.classesOrganisationErrorUnknown,
      emptyLabel: state.summariesStatus == EnrollmentLoadStatus.initial
          ? l10n.classesListInitialEmptyMessage
          : l10n.classesListNoMatchMessage,
      onViewRequested: (row) {
        final summary = byId[row.id];
        if (summary != null) {
          onViewRequested(summary);
        }
      },
    );
  }
}
