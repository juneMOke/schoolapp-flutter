import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_data_table.dart';

class EnrollmentResultsTableView extends StatelessWidget {
  final List<EnrollmentSummary> enrollments;
  final int? totalCount;
  final ValueChanged<EnrollmentSummary> onViewRequested;
  final bool isLoading;
  final bool isError;
  final String? loadingLabel;
  final String? errorLabel;
  final String? emptyLabel;
  final int currentPage;
  final int totalPages;
  final DataTableDensity density;
  final bool showPagination;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final String Function(int current, int total)? pageLabelBuilder;

  const EnrollmentResultsTableView({
    super.key,
    required this.enrollments,
    required this.onViewRequested,
    this.totalCount,
    this.isLoading = false,
    this.isError = false,
    this.loadingLabel,
    this.errorLabel,
    this.emptyLabel,
    this.currentPage = 1,
    this.totalPages = 1,
    this.density = DataTableDensity.comfortable,
    this.showPagination = true,
    this.onPreviousPage,
    this.onNextPage,
    this.pageLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return EnrollmentDataTable(
      enrollments: enrollments,
      totalCount: totalCount,
      onViewRequested: onViewRequested,
      isLoading: isLoading,
      isError: isError,
      loadingLabel: loadingLabel,
      errorLabel: errorLabel,
      emptyLabel: emptyLabel,
      currentPage: currentPage,
      totalPages: totalPages,
      density: density,
      showPagination: showPagination,
      onPreviousPage: onPreviousPage,
      onNextPage: onNextPage,
      pageLabelBuilder: pageLabelBuilder,
    );
  }
}
