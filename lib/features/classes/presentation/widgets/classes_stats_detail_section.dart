import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_stats_chart_card.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_stats_empty_chart_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesStatsDetailSection extends StatelessWidget {
  final ClassroomStats stats;

  const ClassesStatsDetailSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = _flattenRows(stats.detail.school);

    return ClassesStatsChartCard(
      title: l10n.classesStatsSectionClassroomDetail,
      child: Semantics(
        container: true,
        label: l10n.classesStatsDetailA11yLabel,
        child: rows.isEmpty
            ? ClassesStatsEmptyChartState(message: l10n.classesStatsNoData)
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(
                      label: Text(l10n.classesStatsDetailColumnClassroom),
                    ),
                    DataColumn(label: Text(l10n.classesStatsDetailColumnCycle)),
                    DataColumn(label: Text(l10n.classesStatsDetailColumnLevel)),
                    DataColumn(label: Text(l10n.classesStatsDetailColumnTotal)),
                    DataColumn(label: Text(l10n.classesStatsDetailColumnGirls)),
                    DataColumn(label: Text(l10n.classesStatsDetailColumnBoys)),
                  ],
                  rows: rows
                      .map(
                        (row) => DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Text(
                                  row.classroomName,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body,
                                ),
                              ),
                            ),
                            DataCell(Text(row.cycleCode)),
                            DataCell(Text(row.levelCode)),
                            DataCell(Text('${row.totalStudents}')),
                            DataCell(Text('${row.girls}')),
                            DataCell(Text('${row.boys}')),
                          ],
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
      ),
    );
  }

  List<_ClassroomDetailRow> _flattenRows(SchoolDetail school) {
    final rows = <_ClassroomDetailRow>[];
    for (final cycle in school.cycles) {
      for (final level in cycle.levels) {
        for (final classroom in level.classrooms) {
          rows.add(
            _ClassroomDetailRow(
              cycleCode: cycle.cycleCode,
              levelCode: level.levelCode,
              classroomName: classroom.name,
              totalStudents: classroom.totalStudents,
              girls: classroom.girls,
              boys: classroom.boys,
            ),
          );
        }
      }
    }

    rows.sort((a, b) => b.totalStudents.compareTo(a.totalStudents));
    return rows;
  }
}

class _ClassroomDetailRow {
  final String cycleCode;
  final String levelCode;
  final String classroomName;
  final int totalStudents;
  final int girls;
  final int boys;

  const _ClassroomDetailRow({
    required this.cycleCode,
    required this.levelCode,
    required this.classroomName,
    required this.totalStudents,
    required this.girls,
    required this.boys,
  });
}
