import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/finance/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/fee_control_table_layout.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Tableau du Contrôle des frais : identité de l'élève **et** sa position sur
/// le frais contrôlé (attendu / payé / reste / statut).
///
/// Ne porte que l'état de tri et le câblage de pagination ; colonnes et lignes,
/// dans leurs deux dispositions, vivent dans [FeeControlTableLayout].
class FeeControlDataTable extends StatefulWidget {
  final List<FeeControlRow> rows;
  final int? totalCount;
  final ValueChanged<FeeControlRow> onViewRequested;
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
  final int pageSize;

  const FeeControlDataTable({
    super.key,
    required this.rows,
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
    this.pageSize = AppConstants.enrollmentDefaultPageSize,
  });

  @override
  State<FeeControlDataTable> createState() => _FeeControlDataTableState();
}

class _FeeControlDataTableState extends State<FeeControlDataTable> {
  FeeControlSortColumn _sortColumn = FeeControlSortColumn.lastName;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = _sortRows(widget.rows);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= AppBreakpoints.feeControlTableWideMin;
        return DataTableView(
          rows: FeeControlTableLayout.rows(
            sorted,
            l10n,
            wide: wide,
            onViewRequested: widget.onViewRequested,
          ),
          config: DataTableViewConfig(
            columns: FeeControlTableLayout.columns(l10n, wide: wide),
            isLoading: widget.isLoading,
            isError: widget.isError,
            loadingLabel: widget.loadingLabel ?? l10n.loadingStudents,
            errorLabel: widget.errorLabel ?? l10n.noResultsFound,
            sortColumnIndex: _sortColumn.index,
            sortAscending: _sortAscending,
            onSortChanged: _onSortChanged,
            emptyLabel:
                widget.emptyLabel ?? l10n.feeControlNoResultsDescription,
            footer: DataTableFooterConfig(
              label: l10n.paginationResultsCount(sorted.length),
              total: widget.totalCount,
              unit: l10n.unitStudents,
              pagination: _buildPaginationConfig(),
            ),
          ),
        );
      },
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

  void _onSortChanged(int column, bool ascending) {
    if (column < 0 || column >= FeeControlSortColumn.values.length) return;

    setState(() {
      _sortColumn = FeeControlSortColumn.values[column];
      _sortAscending = ascending;
    });
  }

  /// Tri de la **page courante**, comme le tableau de la Facturation : la
  /// liste complète vit dans le BLoC, la table n'en voit qu'une tranche.
  List<FeeControlRow> _sortRows(List<FeeControlRow> rows) {
    final list = [...rows];
    list.sort((a, b) {
      final cmp = switch (_sortColumn) {
        FeeControlSortColumn.lastName => a.summary.student.lastName.compareTo(
          b.summary.student.lastName,
        ),
        FeeControlSortColumn.surname => a.summary.student.surname.compareTo(
          b.summary.student.surname,
        ),
        FeeControlSortColumn.firstName => a.summary.student.firstName.compareTo(
          b.summary.student.firstName,
        ),
        FeeControlSortColumn.remaining =>
          a.aggregate.sortableRemainingInCents.compareTo(
            b.aggregate.sortableRemainingInCents,
          ),
        FeeControlSortColumn.status => a.status.index.compareTo(b.status.index),
      };
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }
}
