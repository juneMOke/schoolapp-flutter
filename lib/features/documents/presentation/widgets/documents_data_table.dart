import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart'
    as core_avatar;
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

enum _DocumentsSortColumn { lastName, surname, firstName }

/// Tableau des élèves du module Documents (§03 de la spec).
///
/// Deux écarts assumés avec la spec, tous deux faute de source de vérité :
///
/// - **pas de colonne « Dossier »** ni de puce de comptage. Le back n'expose
///   aucun listing des pièces d'un élève ; un compteur dérivé du seul local
///   ignorerait tout ce qui a été émis depuis une autre tablette, et la spec
///   exige précisément que cette puce ne puisse **jamais** diverger de la
///   pastille du catalogue. Mieux vaut ne rien afficher qu'un chiffre faux.
/// - **le tri ne porte que sur la page courante**, comme partout ailleurs dans
///   l'application : le moteur de liste pagine avant de trier. Le corriger
///   suppose de toucher le projector partagé avec la Facturation, la
///   Réinscription et la Pré-inscription.
///
/// L'action de ligne est un chevron et non un œil : on n'ouvre pas une fiche en
/// lecture, on entre dans le catalogue des pièces de l'élève.
class DocumentsDataTable extends StatefulWidget {
  final List<EnrollmentSummary> summaries;
  final int? totalCount;
  final ValueChanged<EnrollmentSummary> onCatalogRequested;
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

  const DocumentsDataTable({
    super.key,
    required this.summaries,
    required this.onCatalogRequested,
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
  State<DocumentsDataTable> createState() => _DocumentsDataTableState();
}

class _DocumentsDataTableState extends State<DocumentsDataTable> {
  _DocumentsSortColumn _sortColumn = _DocumentsSortColumn.lastName;
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
        emptyLabel: widget.emptyLabel ?? l10n.documentsNoResultsDescription,
        footer: DataTableFooterConfig(
          label: l10n.paginationResultsCount(sorted.length),
          total: widget.totalCount,
          unit: l10n.unitStudents,
          pagination: _buildPaginationConfig(),
        ),
      ),
    );
  }

  DataTablePaginationConfig? _buildPaginationConfig() {
    if (!widget.showPagination || widget.totalPages <= 1) return null;
    if (widget.onPreviousPage == null || widget.onNextPage == null) return null;

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

  List<DataTableColumnDef> _buildColumns(AppLocalizations l10n) => [
    DataTableColumnDef(
      label: l10n.lastName,
      flex: 3,
      sortable: true,
      sortIndex: _DocumentsSortColumn.lastName.index,
    ),
    DataTableColumnDef(
      label: l10n.surname,
      flex: 3,
      sortable: true,
      sortIndex: _DocumentsSortColumn.surname.index,
    ),
    DataTableColumnDef(
      label: l10n.firstName,
      flex: 3,
      sortable: true,
      sortIndex: _DocumentsSortColumn.firstName.index,
    ),
  ];

  List<DataTableRowSpec> _buildRows(
    List<EnrollmentSummary> summaries,
    AppLocalizations l10n,
  ) => summaries
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
            type: DataTableTrailingType.chevronOpen,
            tooltip: l10n.documentsOpenCatalogLabel,
            onTap: () => widget.onCatalogRequested(summary),
          ),
        ),
      )
      .toList(growable: false);

  void _onSortChanged(int column, bool ascending) {
    if (column < 0 || column >= _DocumentsSortColumn.values.length) return;

    setState(() {
      _sortColumn = _DocumentsSortColumn.values[column];
      _sortAscending = ascending;
    });
  }

  List<EnrollmentSummary> _sortSummaries(List<EnrollmentSummary> summaries) {
    final list = [...summaries];
    list.sort((a, b) {
      final valA = switch (_sortColumn) {
        _DocumentsSortColumn.lastName => a.student.lastName,
        _DocumentsSortColumn.surname => a.student.surname,
        _DocumentsSortColumn.firstName => a.student.firstName,
      };
      final valB = switch (_sortColumn) {
        _DocumentsSortColumn.lastName => b.student.lastName,
        _DocumentsSortColumn.surname => b.student.surname,
        _DocumentsSortColumn.firstName => b.student.firstName,
      };
      final cmp = valA.compareTo(valB);
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }
}
