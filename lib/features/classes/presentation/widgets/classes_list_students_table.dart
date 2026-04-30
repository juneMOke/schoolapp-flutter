import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_students_table_components.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesListStudentsTable extends StatefulWidget {
  final List<ClassesListStudentRow> rows;
  final ValueChanged<ClassesListStudentRow> onViewRequested;

  const ClassesListStudentsTable({
    super.key,
    required this.rows,
    required this.onViewRequested,
  });

  @override
  State<ClassesListStudentsTable> createState() => _ClassesListStudentsTableState();
}

class _ClassesListStudentsTableState extends State<ClassesListStudentsTable> {
  ClassesListStudentsSortColumn _sortColumn =
      ClassesListStudentsSortColumn.lastName;
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.financeDetailShadow,
            blurRadius: AppDimensions.classesOrganisationShadowBlur,
            offset: Offset(0, AppDimensions.spacingS),
          ),
        ],
      ),
      child: Column(
        children: [
          ClassesListStudentsTableHeader(
            l10n: l10n,
            sortColumn: _sortColumn,
            sortAscending: _sortAscending,
            onSortChanged: _onSortChanged,
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (_, index) =>
                const Divider(height: 1, thickness: 1, color: AppColors.border),
            itemBuilder: (context, index) {
              final row = rows[index];
              return ClassesListStudentsDataRow(
                key: ValueKey<String>('student-row-${rows[index].id}'),
                row: row,
                isEven: index.isEven,
                onViewRequested: widget.onViewRequested,
              );
            },
          ),
        ],
      ),
    );
  }

  void _onSortChanged(ClassesListStudentsSortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
        return;
      }

      _sortColumn = column;
      _sortAscending = true;
    });
  }

  String _valueFor(
    ClassesListStudentRow row,
    ClassesListStudentsSortColumn column,
  ) {
    return switch (column) {
      ClassesListStudentsSortColumn.lastName => row.lastName.toLowerCase(),
      ClassesListStudentsSortColumn.surname => row.surname.toLowerCase(),
      ClassesListStudentsSortColumn.firstName => row.firstName.toLowerCase(),
    };
  }
}
