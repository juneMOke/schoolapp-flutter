import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart'
    as core_avatar;
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

// ─── Enum de tri (privé au fichier) ───────────────────────────────────────────

enum _FacturationSortColumn { lastName, surname, firstName }

// ─── Widget public ────────────────────────────────────────────────────────────

/// Tableau des élèves pour la facturation — utilise [DataTableView] + [DataTableViewConfig].
///
/// Gère le tri local des colonnes ainsi que les états chargement, vide et erreur.
/// Signature alignée sur [EnrollmentDataTable] pour uniformiser les tables du projet.
class FacturationDataTable extends StatefulWidget {
  final List<EnrollmentSummary> summaries;
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

  const FacturationDataTable({
    super.key,
    required this.summaries,
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
  State<FacturationDataTable> createState() => _FacturationDataTableState();
}

class _FacturationDataTableState extends State<FacturationDataTable> {
  _FacturationSortColumn _sortColumn = _FacturationSortColumn.lastName;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = _sortSummaries(widget.summaries);

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
        emptyLabel: widget.emptyLabel ?? l10n.facturationNoResultsDescription,
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
      isLoading: widget.isLoading,
      pageLabel: widget.pageLabelBuilder,
    );
  }

  List<DataTableColumnDef> _buildColumns(AppLocalizations l10n) {
    return [
      DataTableColumnDef(
        label: l10n.lastName,
        flex: 3,
        sortable: true,
        sortIndex: _FacturationSortColumn.lastName.index,
      ),
      DataTableColumnDef(
        label: l10n.surname,
        flex: 3,
        sortable: true,
        sortIndex: _FacturationSortColumn.surname.index,
      ),
      DataTableColumnDef(
        label: l10n.firstName,
        flex: 3,
        sortable: true,
        sortIndex: _FacturationSortColumn.firstName.index,
      ),
    ];
  }

  List<DataTableRowSpec> _buildRows(
    List<EnrollmentSummary> summaries,
    AppLocalizations l10n,
  ) {
    return summaries
        .map(
          (summary) => DataTableRowSpec(
            id: summary.enrollmentId,
            displayName:
                '${summary.student.lastName} ${summary.student.firstName}',
            leading: core_avatar.StudentAvatar(
              firstName: summary.student.firstName,
              lastName: summary.student.lastName,
              studentId: summary.student.id,
              size: core_avatar.AvatarSize.sm,
            ),
            cells: [
              DataTableCellSpec(
                text: summary.student.lastName,
                variant: DataTableCellTextVariant.strong,
              ),
              DataTableCellSpec(text: summary.student.surname),
              DataTableCellSpec(text: summary.student.firstName),
            ],
            trailing: DataTableTrailingSpec(
              type: DataTableTrailingType.eye,
              tooltip: l10n.facturationViewChargesLabel,
              onTap: () => widget.onViewRequested(summary),
            ),
          ),
        )
        .toList(growable: false);
  }

  void _onSortChanged(int column, bool ascending) {
    if (column < 0 || column >= _FacturationSortColumn.values.length) return;

    setState(() {
      _sortColumn = _FacturationSortColumn.values[column];
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

  List<EnrollmentSummary> _sortSummaries(List<EnrollmentSummary> summaries) {
    final list = [...summaries];
    list.sort((a, b) {
      final valA = switch (_sortColumn) {
        _FacturationSortColumn.lastName => a.student.lastName,
        _FacturationSortColumn.surname => a.student.surname,
        _FacturationSortColumn.firstName => a.student.firstName,
      };
      final valB = switch (_sortColumn) {
        _FacturationSortColumn.lastName => b.student.lastName,
        _FacturationSortColumn.surname => b.student.surname,
        _FacturationSortColumn.firstName => b.student.firstName,
      };
      final cmp = valA.compareTo(valB);
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }
}
