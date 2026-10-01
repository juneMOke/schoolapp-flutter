import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_month.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_student.dart';
import 'package:school_app_flutter/features/attendances/domain/services/student_month_stats.dart';

/// Les filtres du récapitulatif.
enum ClassRecapFilter { all, toWatch, perfect }

/// Les critères du récapitulatif : un filtre et un texte, combinés.
class ClassRecapQuery extends Equatable {
  final ClassRecapFilter filter;
  final String text;

  const ClassRecapQuery({this.filter = ClassRecapFilter.all, this.text = ''});

  static const ClassRecapQuery none = ClassRecapQuery();

  ClassRecapQuery withFilter(ClassRecapFilter value) =>
      ClassRecapQuery(filter: value, text: text);

  ClassRecapQuery withText(String value) =>
      ClassRecapQuery(filter: filter, text: value);

  bool accepts(ClassRecapRow row) =>
      _matches(filter, row.stats) &&
      SearchNormalizationHelper.containsAllWords([
        row.student.lastName,
        row.student.middleName,
        row.student.firstName,
      ], text);

  static bool _matches(ClassRecapFilter filter, StudentMonthStats stats) =>
      switch (filter) {
        ClassRecapFilter.all => true,
        ClassRecapFilter.toWatch => stats.toWatch,
        ClassRecapFilter.perfect => stats.perfect,
      };

  @override
  List<Object?> get props => [filter, text];
}

/// Un élève et sa synthèse du mois.
class ClassRecapRow extends Equatable {
  final ClassPresenceStudent student;
  final StudentMonthStats stats;

  const ClassRecapRow({required this.student, required this.stats});

  @override
  List<Object?> get props => [student, stats];
}

/// Le récapitulatif du mois d'une classe : une ligne par élève et les totaux
/// que la clôture transmettra. Calcul pur, refait à chaque filtre.
class ClassMonthRecap extends Equatable {
  final ClassPresenceMonth month;
  final int schoolDays;
  final List<ClassRecapRow> all;
  final List<ClassRecapRow> rows;

  const ClassMonthRecap._({
    required this.month,
    required this.schoolDays,
    required this.all,
    required this.rows,
  });

  factory ClassMonthRecap.build(
    ClassPresenceMonth month, {
    required String today,
    required ClassRecapQuery query,
    SchoolYearBounds? year,
  }) {
    final days = month.schoolDays(today: today, year: year);
    final all = [
      for (final student in month.students)
        ClassRecapRow(
          student: student,
          stats: StudentMonthStats.of(month, student.id, schoolDays: days),
        ),
    ];
    return ClassMonthRecap._(
      month: month,
      schoolDays: days.length,
      all: all,
      rows: [
        for (final row in all)
          if (query.accepts(row)) row,
      ],
    );
  }

  int count(ClassRecapFilter filter) =>
      all.where((row) => ClassRecapQuery._matches(filter, row.stats)).length;

  bool get isHoliday => schoolDays == 0;

  bool get isEmpty => all.isEmpty;

  bool get isFilteredEmpty => all.isNotEmpty && rows.isEmpty;

  /// Présences sur jours de classe, toute la classe ; `null` sans jour.
  double? get rate {
    final days = _sum((s) => s.schoolDays);
    return days == 0 ? null : _sum((s) => s.presences) / days;
  }

  int get late => _sum((s) => s.late);
  int get lateMinutes => _sum((s) => s.lateMinutes);
  int get absentUnjustified => _sum((s) => s.absentUnjustified);

  /// Jours-élève sans appel — présents par défaut à la clôture.
  int get notMarked => _sum((s) => s.notMarked);

  int _sum(int Function(StudentMonthStats stats) pick) =>
      all.fold<int>(0, (sum, row) => sum + pick(row.stats));

  @override
  List<Object?> get props => [month, schoolDays, all, rows];
}
