import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
import 'package:school_app_flutter/core/components/tables/data_table_pagination_bar.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_result_card.dart';

class EnrollmentResultsGridView extends StatelessWidget {
  final List<EnrollmentSummary> enrollments;
  final ValueChanged<EnrollmentSummary> onViewRequested;
  final bool showPagination;
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final String Function(int current, int total)? pageLabelBuilder;

  const EnrollmentResultsGridView({
    super.key,
    required this.enrollments,
    required this.onViewRequested,
    this.showPagination = true,
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.onPreviousPage,
    this.onNextPage,
    this.pageLabelBuilder,
  });

  // Mêmes garde-fous que la table : pagination affichée uniquement si plus
  // d'une page et si les deux callbacks de navigation sont fournis.
  bool get _hasPagination =>
      showPagination &&
      totalPages > 1 &&
      onPreviousPage != null &&
      onNextPage != null;

  @override
  Widget build(BuildContext context) {
    final grid = EteeloGridView(
      itemCount: enrollments.length,
      itemBuilder: (context, index) {
        final enrollment = enrollments[index];
        return EnrollmentResultCard(
          enrollment: enrollment,
          onTap: () => onViewRequested(enrollment),
        );
      },
    );

    if (!_hasPagination) {
      return grid;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        grid,
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: DataTablePaginationBar(
            currentPage: currentPage,
            totalPages: totalPages,
            onPrevious: onPreviousPage!,
            onNext: onNextPage!,
            isLoading: isLoading,
            pageLabel: pageLabelBuilder,
          ),
        ),
      ],
    );
  }
}
