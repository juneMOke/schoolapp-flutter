import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart'
    as core_avatar;
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

enum _ClassesListSortColumn { lastName, surname, firstName }

class ClassesListStudentsTable extends StatefulWidget {
  final List<ClassesListStudentRow> rows;
  final ValueChanged<ClassesListStudentRow> onViewRequested;
  final bool isLoading;
  final bool isError;
  final String? loadingLabel;
  final String? errorLabel;
  final String? emptyLabel;

  const ClassesListStudentsTable({
    super.key,
    required this.rows,
    required this.onViewRequested,
    this.isLoading = false,
    this.isError = false,
    this.loadingLabel,
    this.errorLabel,
    this.emptyLabel,
  });

  @override
  State<ClassesListStudentsTable> createState() => _ClassesListStudentsTableState();
}

class _ClassesListStudentsTableState extends State<ClassesListStudentsTable> {
  _ClassesListSortColumn _sortColumn = _ClassesListSortColumn.lastName;
  bool _sortAscending = true;

  List<ClassesListStudentRow> get _sortedRows {
    final rows = [...widget.rows];
    rows.sort((left, right) {
      final leftValue = _valueFor(left, _sortColumn);
      final rightValue = _valueFor(right, _sortColumn);
      final result = leftValue.compareTo(rightValue);
      return _sortAscending ? result : -result;
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = _sortedRows;

    return DataTableView(
      rows: _buildRows(rows, l10n),
      config: DataTableViewConfig(
        columns: _buildColumns(l10n),
        isLoading: widget.isLoading,
        isError: widget.isError,
        loadingLabel: widget.loadingLabel ?? l10n.loadingStudents,
        errorLabel: widget.errorLabel ?? l10n.classesOrganisationErrorUnknown,
        sortColumnIndex: _sortColumn.index,
        sortAscending: _sortAscending,
        onSortChanged: _onSortChanged,
        emptyLabel: widget.emptyLabel ?? l10n.classesListNoMatchMessage,
        footer: DataTableFooterConfig(
          label: l10n.enrollmentResultsCount(rows.length),
        ),
      ),
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
              size: 28,
            ),
            cells: [
              DataTableCellSpec(
                text: row.lastName,
                variant: DataTableCellTextVariant.strong,
              ),
              DataTableCellSpec(text: row.surname),
              DataTableCellSpec(text: row.firstName),
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

    setState(() {
      _sortColumn = _ClassesListSortColumn.values[column];
      _sortAscending = ascending;
    });
  }

  String _valueFor(
    ClassesListStudentRow row,
    _ClassesListSortColumn column,
  ) {
    return switch (column) {
      _ClassesListSortColumn.lastName => row.lastName.toLowerCase(),
      _ClassesListSortColumn.surname => row.surname.toLowerCase(),
      _ClassesListSortColumn.firstName => row.firstName.toLowerCase(),
    };
  }
}
