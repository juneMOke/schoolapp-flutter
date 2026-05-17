import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart'
    as core_avatar;
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_data_table_sorter.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_status_badge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentDataTable extends StatefulWidget {
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
  final bool showPagination;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final String Function(int current, int total)? pageLabelBuilder;

  const EnrollmentDataTable({
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
    this.showPagination = true,
    this.onPreviousPage,
    this.onNextPage,
    this.pageLabelBuilder,
  });

  @override
  State<EnrollmentDataTable> createState() => _EnrollmentDataTableState();
}

class _EnrollmentDataTableState extends State<EnrollmentDataTable> {
  EnrollmentSortColumn _sortColumn = EnrollmentSortColumn.lastName;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = EnrollmentDataTableSorter.sort(
      widget.enrollments,
      _sortColumn,
      _sortAscending,
    );

    return DataTableView(
      rows: _buildRows(sorted, l10n),
      config: DataTableViewConfig(
        columns: _buildColumns(l10n),
        isLoading: widget.isLoading,
        isError: widget.isError,
        loadingLabel: widget.loadingLabel ?? l10n.loadingStudents,
        errorLabel: widget.errorLabel ?? l10n.noResultsFound,
        sortColumnIndex: _sortColumn.index,
        sortAscending: _sortAscending,
        onSortChanged: _onSortChanged,
        emptyLabel: widget.emptyLabel ?? l10n.enrollmentNoResultsDescription,
        footer: DataTableFooterConfig(
          label: _buildFooterLabel(l10n, sorted.length),
          pagination: _buildPaginationConfig(),
        ),
      ),
    );
  }

  DataTablePaginationConfig? _buildPaginationConfig() {
    if (!widget.showPagination || widget.totalPages <= 1) {
      return null;
    }
    if (widget.onPreviousPage == null || widget.onNextPage == null) {
      return null;
    }

    return DataTablePaginationConfig(
      currentPage: widget.currentPage,
      totalPages: widget.totalPages,
      onPrevious: widget.onPreviousPage!,
      onNext: widget.onNextPage!,
      pageLabel: widget.pageLabelBuilder,
    );
  }

  List<DataTableColumnDef> _buildColumns(AppLocalizations l10n) {
    return [
      DataTableColumnDef(
        label: l10n.lastName,
        flex: 3,
        sortable: true,
        sortIndex: EnrollmentSortColumn.lastName.index,
      ),
      DataTableColumnDef(
        label: l10n.surname,
        flex: 3,
        sortable: true,
        sortIndex: EnrollmentSortColumn.surname.index,
      ),
      DataTableColumnDef(
        label: l10n.firstName,
        flex: 3,
        sortable: true,
        sortIndex: EnrollmentSortColumn.firstName.index,
      ),
      DataTableColumnDef(
        label: l10n.dateOfBirth,
        flex: 2,
        sortable: true,
        sortIndex: EnrollmentSortColumn.dateOfBirth.index,
      ),
      DataTableColumnDef(label: l10n.enrollmentStatusFilterLabel, flex: 2),
    ];
  }

  List<DataTableRowSpec> _buildRows(
    List<EnrollmentSummary> enrollments,
    AppLocalizations l10n,
  ) {
    return enrollments
        .map(
          (enrollment) => DataTableRowSpec(
            id: enrollment.enrollmentId,
            displayName:
                '${enrollment.student.lastName} ${enrollment.student.firstName}',
            leading: core_avatar.StudentAvatar(
              firstName: enrollment.student.firstName,
              lastName: enrollment.student.lastName,
              size: 28,
              variant: _avatarVariantForStatus(
                EnrollmentStatus.fromString(enrollment.status),
              ),
            ),
            cells: [
              DataTableCellSpec(
                text: enrollment.student.lastName,
                variant: DataTableCellTextVariant.strong,
              ),
              DataTableCellSpec(text: enrollment.student.surname),
              DataTableCellSpec(text: enrollment.student.firstName),
              DataTableCellSpec(
                text: _formatDate(enrollment.student.dateOfBirth),
                variant: DataTableCellTextVariant.mono,
              ),
              DataTableCellSpec(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 122),
                  child: EnrollmentStatusBadge(
                    status: EnrollmentStatus.fromString(enrollment.status),
                  ),
                ),
              ),
            ],
            trailing: DataTableTrailingSpec(
              type: DataTableTrailingType.eye,
              tooltip: l10n.viewDetails,
              onTap: () => widget.onViewRequested(enrollment),
            ),
          ),
        )
        .toList(growable: false);
  }

  void _onSortChanged(int column, bool ascending) {
    if (column < 0 || column >= EnrollmentSortColumn.values.length) return;

    setState(() {
      _sortColumn = EnrollmentSortColumn.values[column];
      _sortAscending = ascending;
    });
  }

  String _buildFooterLabel(AppLocalizations l10n, int pageCount) {
    final total = widget.totalCount;
    if (total != null && total > pageCount) {
      return l10n.enrollmentPageFooter(pageCount, total);
    }
    return l10n.enrollmentResultsCount(pageCount);
  }

  core_avatar.AvatarVariant _avatarVariantForStatus(EnrollmentStatus status) {
    return switch (status) {
      EnrollmentStatus.completed ||
      EnrollmentStatus.validated => core_avatar.AvatarVariant.solid,
      _ => core_avatar.AvatarVariant.outlined,
    };
  }

  String _formatDate(String raw) {
    final parts = raw.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return raw;
  }
}
