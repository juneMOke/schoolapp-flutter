import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart'
    as core_avatar;
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Colonnes triables. `level` vient en dernier pour que l'ajout ou le retrait
/// de la colonne Niveau ne décale jamais l'index des trois autres.
enum _ClassesListSortColumn { lastName, surname, firstName, level }

class ClassesListStudentsTable extends StatefulWidget {
  /// **Tout** le corpus à afficher, jamais une page déjà découpée : quand la
  /// table pagine (cf. [totalPages]), c'est elle qui découpe, et seulement
  /// **après** avoir trié.
  ///
  /// Recevoir une page rendrait le tri page-local, c'est-à-dire faux : « trier
  /// par niveau » ne réordonnerait que les lignes sous les yeux, sans jamais
  /// faire remonter de la page suivante l'élève qui devrait être premier.
  final List<ClassesListStudentRow> rows;
  final ValueChanged<ClassesListStudentRow> onViewRequested;
  final bool isLoading;
  final bool isError;
  final String? loadingLabel;
  final String? errorLabel;
  final String? emptyLabel;

  /// Rend la colonne « Niveau ». Faux quand le niveau est le critère de la
  /// recherche : la colonne répéterait alors la même valeur sur toutes les
  /// lignes, sous un bandeau qui l'annonce déjà.
  final bool showLevelColumn;

  /// Décompte annoncé au pied du tableau. Vaut `rows.length` par défaut ;
  /// ne se renseigne que si la source connaît un total que le corpus reçu ne
  /// dit pas.
  final int? totalCount;

  /// Pagination, **1-based**. Absente (`totalPages <= 1`, `pageSize` nul ou
  /// callbacks nuls) quand la liste tient d'un bloc, comme le roster d'une
  /// classe : la table rend alors tout ce qu'elle a reçu.
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  /// Prévient qu'un tri vient de changer l'ordre du corpus **entier**. Le
  /// parent doit revenir à la première page : rester sur la page 3 après un
  /// changement de tri y afficherait le milieu d'un ordre que l'utilisateur
  /// vient à peine de demander. Sans pagination, jamais appelé.
  final VoidCallback? onSortChanged;

  const ClassesListStudentsTable({
    super.key,
    required this.rows,
    required this.onViewRequested,
    this.isLoading = false,
    this.isError = false,
    this.loadingLabel,
    this.errorLabel,
    this.emptyLabel,
    this.showLevelColumn = false,
    this.totalCount,
    this.currentPage = 1,
    this.totalPages = 1,
    this.pageSize = 0,
    this.onPreviousPage,
    this.onNextPage,
    this.onSortChanged,
  });

  @override
  State<ClassesListStudentsTable> createState() =>
      _ClassesListStudentsTableState();
}

class _ClassesListStudentsTableState extends State<ClassesListStudentsTable> {
  _ClassesListSortColumn _sortColumn = _ClassesListSortColumn.lastName;
  bool _sortAscending = true;

  /// Le tri par niveau ne survit pas au retrait de la colonne : sans ce repli,
  /// `sortColumnIndex` désignerait une colonne qui n'existe plus dès qu'on
  /// revient d'une recherche par identité vers une recherche par classe.
  _ClassesListSortColumn get _effectiveSortColumn =>
      _sortColumn == _ClassesListSortColumn.level && !widget.showLevelColumn
      ? _ClassesListSortColumn.lastName
      : _sortColumn;

  /// Vrai quand la table découpe elle-même : elle a reçu tout le corpus et
  /// n'en rend qu'une tranche.
  bool get _isPaginated =>
      widget.totalPages > 1 &&
      widget.pageSize > 0 &&
      widget.onPreviousPage != null &&
      widget.onNextPage != null;

  /// Les lignes réellement rendues : **le tri d'abord, la découpe ensuite**.
  /// L'inverse trierait une page, donc rien.
  List<ClassesListStudentRow> get _visibleRows {
    final sorted = _sortedRows;
    if (!_isPaginated) {
      return sorted;
    }

    final start = ((widget.currentPage - 1) * widget.pageSize).clamp(
      0,
      sorted.length,
    );
    final end = (start + widget.pageSize).clamp(0, sorted.length);
    return sorted.sublist(start, end);
  }

  List<ClassesListStudentRow> get _sortedRows {
    final column = _effectiveSortColumn;
    final rows = [...widget.rows];
    rows.sort((left, right) {
      final leftValue = _valueFor(left, column);
      final rightValue = _valueFor(right, column);
      final result = leftValue.compareTo(rightValue);
      return _sortAscending ? result : -result;
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = _visibleRows;

    return DataTableView(
      rows: _buildRows(rows, l10n),
      config: DataTableViewConfig(
        columns: _buildColumns(l10n),
        isLoading: widget.isLoading,
        isError: widget.isError,
        loadingLabel: widget.loadingLabel ?? l10n.loadingStudents,
        errorLabel: widget.errorLabel ?? l10n.classesOrganisationErrorUnknown,
        sortColumnIndex: _effectiveSortColumn.index,
        sortAscending: _sortAscending,
        onSortChanged: _onSortChanged,
        emptyLabel: widget.emptyLabel ?? l10n.classesListNoMatchMessage,
        footer: DataTableFooterConfig(
          label: l10n.paginationResultsCount(rows.length),
          total: widget.totalCount ?? widget.rows.length,
          unit: l10n.unitStudents,
          pagination: _buildPaginationConfig(),
        ),
      ),
    );
  }

  // Le même prédicat gouverne la barre de pagination et la découpe : les
  // dissocier ferait rendre tout le corpus sous une barre qui promet des pages,
  // ou l'inverse.
  DataTablePaginationConfig? _buildPaginationConfig() {
    if (!_isPaginated) {
      return null;
    }

    return DataTablePaginationConfig(
      currentPage: widget.currentPage,
      totalPages: widget.totalPages,
      pageSize: widget.pageSize,
      onPrevious: widget.onPreviousPage!,
      onNext: widget.onNextPage!,
      isLoading: widget.isLoading,
    );
  }

  List<DataTableColumnDef> _buildColumns(AppLocalizations l10n) {
    return [
      DataTableColumnDef(
        label: l10n.lastName,
        flex: 3,
        sortable: true,
        sortIndex: _ClassesListSortColumn.lastName.index,
      ),
      DataTableColumnDef(
        label: l10n.surname,
        flex: 3,
        sortable: true,
        sortIndex: _ClassesListSortColumn.surname.index,
      ),
      DataTableColumnDef(
        label: l10n.firstName,
        flex: 3,
        sortable: true,
        sortIndex: _ClassesListSortColumn.firstName.index,
      ),
      if (widget.showLevelColumn)
        DataTableColumnDef(
          label: l10n.classesListLevelColumnLabel,
          flex: 2,
          sortable: true,
          sortIndex: _ClassesListSortColumn.level.index,
        ),
    ];
  }

  List<DataTableRowSpec> _buildRows(
    List<ClassesListStudentRow> rows,
    AppLocalizations l10n,
  ) {
    return rows
        .map(
          (row) => DataTableRowSpec(
            id: row.id,
            displayName: '${row.lastName} ${row.firstName}',
            leading: core_avatar.StudentAvatar(
              firstName: row.firstName,
              lastName: row.lastName,
              studentId: row.studentId,
              size: core_avatar.AvatarSize.sm,
            ),
            cells: [
              DataTableCellSpec(
                text: row.lastName,
                variant: DataTableCellTextVariant.strong,
              ),
              DataTableCellSpec(text: row.surname),
              DataTableCellSpec(text: row.firstName),
              if (widget.showLevelColumn)
                DataTableCellSpec(
                  // Un niveau que la ligne ne sait pas dire (référentiel pas
                  // encore descendu) se montre comme tel plutôt que comme une
                  // cellule vide, qu'on lirait comme « pas de niveau ».
                  text: row.levelLabel.trim().isEmpty
                      ? l10n.classesListLevelUnknown
                      : row.levelLabel,
                ),
            ],
            trailing: DataTableTrailingSpec(
              type: DataTableTrailingType.eye,
              tooltip: l10n.viewDetails,
              onTap: () => widget.onViewRequested(row),
            ),
          ),
        )
        .toList(growable: false);
  }

  void _onSortChanged(int column, bool ascending) {
    if (column < 0 || column >= _ClassesListSortColumn.values.length) return;
    final requested = _ClassesListSortColumn.values[column];
    if (requested == _ClassesListSortColumn.level && !widget.showLevelColumn) {
      return;
    }

    if (requested == _sortColumn && ascending == _sortAscending) {
      return;
    }

    setState(() {
      _sortColumn = requested;
      _sortAscending = ascending;
    });

    // L'ordre a changé pour TOUT le corpus : la page 1 n'est plus la même.
    if (_isPaginated) {
      widget.onSortChanged?.call();
    }
  }

  String _valueFor(ClassesListStudentRow row, _ClassesListSortColumn column) {
    return switch (column) {
      _ClassesListSortColumn.lastName => row.lastName.toLowerCase(),
      _ClassesListSortColumn.surname => row.surname.toLowerCase(),
      _ClassesListSortColumn.firstName => row.firstName.toLowerCase(),
      _ClassesListSortColumn.level => row.levelLabel.toLowerCase(),
    };
  }
}
