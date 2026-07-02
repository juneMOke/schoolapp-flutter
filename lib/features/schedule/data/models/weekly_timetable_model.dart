import 'package:school_app_flutter/features/schedule/data/models/timetable_row_model.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';

/// Modèle du `WeeklyTimetableDto` : matrice créneau × jour.
///
/// Parsing **manuel** (pas de `@JsonSerializable`) : `days` (liste de valeurs
/// wire) est mappé en [Weekday] et `rows` délègue à [TimetableRowModel.fromJson]
/// (dont la map `cells` est à valeurs nullables). Lecture seule (pas de
/// `toJson`). Défensif : listes absentes -> vides.
class WeeklyTimetableModel {
  final String academicYearId;
  final String? teacherId;
  final String? classroomId;

  /// Jours de la matrice, en valeur wire (`MON`..`SAT`).
  final List<String> days;
  final List<TimetableRowModel> rows;

  const WeeklyTimetableModel({
    required this.academicYearId,
    this.teacherId,
    this.classroomId,
    required this.days,
    required this.rows,
  });

  factory WeeklyTimetableModel.fromJson(Map<String, dynamic> json) =>
      WeeklyTimetableModel(
        academicYearId: (json['academicYearId'] ?? '').toString(),
        teacherId: json['teacherId'] as String?,
        classroomId: json['classroomId'] as String?,
        days: ((json['days'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        rows: ((json['rows'] as List?) ?? const [])
            .map((e) => TimetableRowModel.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  WeeklyTimetable toEntity() => WeeklyTimetable(
    academicYearId: academicYearId,
    teacherId: teacherId,
    classroomId: classroomId,
    days: days.map(WeekdayX.fromWire).toList(growable: false),
    rows: rows.map((r) => r.toEntity()).toList(growable: false),
  );
}
