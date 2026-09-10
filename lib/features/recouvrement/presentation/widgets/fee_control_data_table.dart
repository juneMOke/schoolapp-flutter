import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/fee_control_table_layout.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Tableau du Contrôle des frais : l'élève **et** sa position sur les frais
/// retenus (attendu / payé / reste / situation).
///
/// Ne porte plus aucun état : l'ordre vient du projecteur — du moins avancé au
/// plus avancé — et n'est pas réordonnable. Colonnes et lignes, dans leurs deux
/// dispositions, vivent dans [FeeControlTableLayout].
class FeeControlDataTable extends StatelessWidget {
  final List<FeeControlRow> rows;
  final int? totalCount;

  /// Cours du jour, pour le taux affiché en regard de la pastille. Le même que
  /// celui qui a ordonné la liste.
  final ExchangeRate? rate;

  final Set<String> selected;
  final Set<String> marked;

  final ValueChanged<FeeControlRow> onViewRequested;
  final ValueChanged<FeeControlRow> onRowTapped;
  final ValueChanged<FeeControlRow> onSelectionToggled;

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
    required this.rate,
    required this.selected,
    required this.marked,
    required this.onViewRequested,
    required this.onRowTapped,
    required this.onSelectionToggled,
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= AppBreakpoints.feeControlTableWideMin;
        return DataTableView(
          rows: FeeControlTableLayout.rows(
            rows,
            l10n,
            wide: wide,
            rate: rate,
            selected: selected,
            marked: marked,
            onViewRequested: onViewRequested,
            onRowTapped: onRowTapped,
            onSelectionToggled: onSelectionToggled,
          ),
          config: DataTableViewConfig(
            columns: FeeControlTableLayout.columns(l10n, wide: wide),
            isLoading: isLoading,
            isError: isError,
            loadingLabel: loadingLabel ?? l10n.loadingStudents,
            errorLabel: errorLabel ?? l10n.noResultsFound,
            emptyLabel: emptyLabel ?? l10n.feeControlNoResultsDescription,
            footer: DataTableFooterConfig(
              label: l10n.paginationResultsCount(rows.length),
              total: totalCount,
              unit: l10n.unitStudents,
              pagination: _pagination(),
            ),
          ),
        );
      },
    );
  }

  DataTablePaginationConfig? _pagination() {
    if (!showPagination || totalPages <= 1) return null;
    if (onPreviousPage == null || onNextPage == null) return null;

    return DataTablePaginationConfig(
      currentPage: currentPage,
      totalPages: totalPages,
      pageSize: pageSize,
      onPrevious: onPreviousPage!,
      onNext: onNextPage!,
      isLoading: isLoading,
      pageLabel: pageLabelBuilder,
    );
  }
}
