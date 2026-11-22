import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/components/tables/data_table_pagination_bar.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_dashboard_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_students_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/states/recovery_results_error_state.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_student_row.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_list_head.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_texts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le cadre de la liste nominative (`RecStudentList`) et ses états : lignes
/// fantômes avant la première page, liste gardée pendant une relecture,
/// message propre à l'onglet ou à la recherche, erreur en place (403 : le
/// droit manque, sans « Réessayer »).
class RecoveryStudentsList extends StatelessWidget {
  final RecoveryStudentsState students;
  final RecoveryTab tab;
  final String search;
  final List<String> currencies;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<RecoveryStudentRow> onStudentTapped;
  final VoidCallback onRetry;

  /// La disposition des lignes, d'après la largeur reçue par le bloc.
  final RecoveryStudentRowLayout layout;

  const RecoveryStudentsList({
    super.key,
    required this.students,
    required this.tab,
    required this.search,
    required this.currencies,
    required this.onPageChanged,
    required this.onStudentTapped,
    required this.onRetry,
    required this.layout,
  });

  /// Sous 600 reçus : cartes ; de 600 à 760 : repliée ; au-delà : large.
  static RecoveryStudentRowLayout layoutFor(double width) =>
      width < AppBreakpoints.dataTableCardsMax
      ? RecoveryStudentRowLayout.card
      : width < AppBreakpoints.detailCompactMax
      ? RecoveryStudentRowLayout.compact
      : RecoveryStudentRowLayout.wide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final page = students.page;
    final failure = students.failure;
    if (students.status == RecoveryLoadStatus.failure && failure != null) {
      return RecoveryResultsErrorState(
        failure: failure,
        onRetry: onRetry,
        nominative: true,
      );
    }
    if (page == null) {
      return EteeloListSkeleton(
        rowCount: 5,
        pillCount: 2,
        semanticsLabel: l10n.recoveryStudentsLoading,
      );
    }
    final loading = students.status == RecoveryLoadStatus.loading;
    return Builder(
      builder: (context) {
        final pageCurrencies = page.currencies.isEmpty
            ? currencies
            : page.currencies;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: AppRadius.brMd,
                border: Border.all(
                  color: ColorMix.tint(
                    AppColors.border,
                    AppColors.terreCuite,
                    RecoveryStudentsTones.listBorderPercent,
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: AppRadius.brMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (layout != RecoveryStudentRowLayout.card)
                      RecoveryStudentsListHead(layout: layout),
                    if (page.content.isEmpty)
                      EteeloEmptyResult(
                        label: recoveryEmptyText(l10n, tab, search),
                        medallionIcon: search.trim().isEmpty
                            ? Icons.groups_outlined
                            : Icons.search_rounded,
                        accentColor: RecoveryStudentsTones.of(tab),
                        minHeight: 0,
                        cardPadding: const EdgeInsets.all(AppSpacing.xl),
                      )
                    else
                      for (final (i, row) in page.content.indexed)
                        RecoveryStudentRowTile(
                          key: ValueKey(row.studentId),
                          row: row,
                          layout: layout,
                          currencies: pageCurrencies,
                          first: i == 0,
                          onTap: () => onStudentTapped(row),
                        ),
                  ],
                ),
              ),
            ),
            if (page.totalPages > 1)
              _Pager(
                page: page,
                loading: loading,
                onPageChanged: onPageChanged,
              ),
          ],
        );
      },
    );
  }
}

/// « {a}–{b} sur {n} élèves », puis la pagination du socle (`RecPager`).
class _Pager extends StatelessWidget {
  final RecoveryStudentsPage page;
  final bool loading;
  final ValueChanged<int> onPageChanged;

  const _Pager({
    required this.page,
    required this.loading,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final from = page.page * page.size + 1;
    final to = (from + page.content.length - 1).clamp(from, page.totalElements);
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.recoverySpace10),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: AppSpacing.xs,
        spacing: AppSpacing.sm,
        children: [
          Text(
            l10n.recoveryStudentsRange(from, to, page.totalElements),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          // Sans largeur intrinsèque, l'indicateur s'étire sur toute la
          // rangée : la pagination garde sa taille.
          IntrinsicWidth(
            child: DataTablePaginationBar(
              currentPage: page.page + 1,
              totalPages: page.totalPages,
              isLoading: loading,
              pageLabel: (current, total) =>
                  l10n.recoveryStudentsPage(current, total),
              onPrevious: () => onPageChanged(page.page - 1),
              onNext: () => onPageChanged(page.page + 1),
            ),
          ),
        ],
      ),
    );
  }
}
