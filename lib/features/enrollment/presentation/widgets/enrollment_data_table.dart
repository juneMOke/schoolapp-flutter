import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
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
  final DataTableDensity density;
  final bool showPagination;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final String Function(int current, int total)? pageLabelBuilder;
  final int pageSize;

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
    this.density = DataTableDensity.comfortable,
    this.showPagination = true,
    this.onPreviousPage,
    this.onNextPage,
    this.pageLabelBuilder,
    this.pageSize = AppConstants.enrollmentDefaultPageSize,
  });

  @override
  State<EnrollmentDataTable> createState() => _EnrollmentDataTableState();
}

class _EnrollmentDataTableState extends State<EnrollmentDataTable> {
  EnrollmentSortColumn _sortColumn = EnrollmentSortColumn.student;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = EnrollmentDataTableSorter.sort(
      widget.enrollments,
      _sortColumn,
      _sortAscending,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Rendu étroit (téléphone) : la colonne Date fusionne en sous-texte du
        // nom → 2 colonnes (Élève | Statut) au lieu de 3, pour rester lisible.
        final isCompact =
            constraints.maxWidth < AppBreakpoints.dataTableCardsMax;
        return _buildTable(l10n, sorted, isCompact);
      },
    );
  }

  Widget _buildTable(
    AppLocalizations l10n,
    List<EnrollmentSummary> sorted,
    bool isCompact,
  ) {
    return DataTableView(
      rows: _buildRows(sorted, l10n, isCompact),
      config: DataTableViewConfig(
        columns: _buildColumns(l10n, isCompact),
        isLoading: widget.isLoading,
        isError: widget.isError,
        loadingLabel: widget.loadingLabel ?? l10n.loadingStudents,
        errorLabel: widget.errorLabel ?? l10n.noResultsFound,
        sortColumnIndex: _sortColumn.index,
        sortAscending: _sortAscending,
        onSortChanged: _onSortChanged,
        emptyLabel: widget.emptyLabel ?? l10n.enrollmentNoResultsDescription,
        footer: DataTableFooterConfig(
          label: l10n.paginationResultsCount(sorted.length),
          total: widget.totalCount,
          unit: l10n.unitStudents,
          pagination: _buildPaginationConfig(),
        ),
        density: widget.density,
        semanticsLabel: l10n.enrollmentResultsA11yLabel,
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
      pageSize: widget.pageSize,
      onPrevious: widget.onPreviousPage!,
      onNext: widget.onNextPage!,
      isLoading: widget.isLoading,
      pageLabel: widget.pageLabelBuilder,
    );
  }

  List<DataTableColumnDef> _buildColumns(
    AppLocalizations l10n,
    bool isCompact,
  ) {
    if (isCompact) {
      return [
        DataTableColumnDef(
          label: l10n.enrollmentStudentColumnLabel,
          flex: 3,
          sortable: true,
          sortIndex: EnrollmentSortColumn.student.index,
        ),
        DataTableColumnDef(label: l10n.enrollmentStatusFilterLabel, flex: 2),
      ];
    }

    return [
      DataTableColumnDef(
        label: l10n.enrollmentStudentColumnLabel,
        flex: 7,
        sortable: true,
        sortIndex: EnrollmentSortColumn.student.index,
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
    bool isCompact,
  ) {
    return enrollments
        .map(
          (enrollment) => DataTableRowSpec(
            id: enrollment.enrollmentId,
            displayName: _studentFullName(enrollment),
            leading: core_avatar.StudentAvatar(
              firstName: enrollment.student.firstName,
              lastName: enrollment.student.lastName,
              studentId: enrollment.student.id,
              size: core_avatar.AvatarSize.sm,
              variant: _avatarVariantForStatus(
                EnrollmentStatus.fromString(enrollment.status),
              ),
            ),
            cells: _buildCells(enrollment, isCompact),
            trailing: DataTableTrailingSpec(
              type: DataTableTrailingType.eye,
              tooltip: l10n.viewDetails,
              semanticLabel: l10n.openDetailsForStudent(
                _studentFullName(enrollment),
              ),
              onTap: () => widget.onViewRequested(enrollment),
            ),
          ),
        )
        .toList(growable: false);
  }

  List<DataTableCellSpec> _buildCells(
    EnrollmentSummary enrollment,
    bool isCompact,
  ) {
    final formattedDate = _formatDate(enrollment.student.dateOfBirth);

    // Téléphone : nom + date de naissance en sous-texte → 1 seule colonne Élève.
    if (isCompact) {
      return [
        DataTableCellSpec(
          text: _studentFullName(enrollment),
          variant: DataTableCellTextVariant.strong,
          secondaryText: formattedDate,
          secondaryVariant: DataTableCellTextVariant.mono,
        ),
        _statusCell(enrollment),
      ];
    }

    return [
      DataTableCellSpec(
        text: _studentFullName(enrollment),
        variant: DataTableCellTextVariant.strong,
      ),
      DataTableCellSpec(
        text: formattedDate,
        variant: DataTableCellTextVariant.mono,
      ),
      _statusCell(enrollment),
    ];
  }

  DataTableCellSpec _statusCell(EnrollmentSummary enrollment) {
    return DataTableCellSpec(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 122),
        child: EnrollmentStatusBadge(
          status: EnrollmentStatus.fromString(enrollment.status),
        ),
      ),
    );
  }

  void _onSortChanged(int column, bool ascending) {
    if (column < 0 || column >= EnrollmentSortColumn.values.length) return;

    setState(() {
      _sortColumn = EnrollmentSortColumn.values[column];
      _sortAscending = ascending;
    });
  }

  String _studentFullName(EnrollmentSummary enrollment) {
    final parts = <String>[
      enrollment.student.lastName,
      enrollment.student.surname,
      enrollment.student.firstName,
    ].where((value) => value.trim().isNotEmpty);

    return parts.join(' ');
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
