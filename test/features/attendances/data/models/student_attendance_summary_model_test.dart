import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/features/attendances/data/models/student_attendance_summary_model.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';

void main() {
  Map<String, dynamic> buildJson() => {
    'studentId': '98f5',
    'firstName': 'John',
    'lastName': 'Doe',
    'academicYearName': '2025-2026',
    'period': 'month',
    'windowStart': '2026-02-01',
    'windowEnd': '2026-02-28',
    'presenceRate': 86.4,
    'presentDays': 19,
    'justifiedAbsenceDays': 2,
    'unjustifiedAbsenceDays': 1,
    'absences': [
      {'date': '2026-02-05', 'reason': 'SICKNESS', 'reasonNote': 'Flu'},
      {'date': '2026-02-12', 'reason': 'UNKNOWN', 'reasonNote': null},
    ],
  };

  test('fromJson -> toEntity mappe tout le resume (dont reasons et dates)', () {
    final entity = StudentAttendanceSummaryModel.fromJson(
      buildJson(),
    ).toEntity();

    expect(entity.studentId, '98f5');
    expect(entity.firstName, 'John');
    expect(entity.lastName, 'Doe');
    expect(entity.academicYearName, '2025-2026');
    expect(entity.period, StatsPeriod.month);
    expect(entity.windowStart, DateTime(2026, 2, 1));
    expect(entity.windowEnd, DateTime(2026, 2, 28));
    expect(entity.presenceRate, 86.4);
    expect(entity.presentDays, 19);
    expect(entity.justifiedAbsenceDays, 2);
    expect(entity.unjustifiedAbsenceDays, 1);

    expect(entity.absences, hasLength(2));
    expect(entity.absences[0].date, DateTime(2026, 2, 5));
    expect(entity.absences[0].reason, AbsenceReason.sickness);
    expect(entity.absences[0].reasonNote, 'Flu');
    expect(entity.absences[1].date, DateTime(2026, 2, 12));
    expect(entity.absences[1].reason, AbsenceReason.unknown);
    expect(entity.absences[1].reasonNote, isNull);
  });

  test('presenceRate entier (num) est converti en double', () {
    final entity = StudentAttendanceSummaryModel.fromJson({
      ...buildJson(),
      'presenceRate': 100,
    }).toEntity();

    expect(entity.presenceRate, 100.0);
  });

  test('absences vides -> liste vide', () {
    final entity = StudentAttendanceSummaryModel.fromJson({
      ...buildJson(),
      'absences': const <dynamic>[],
    }).toEntity();

    expect(entity.absences, isEmpty);
  });

  test('period inconnu -> year (fallback)', () {
    final entity = StudentAttendanceSummaryModel.fromJson({
      ...buildJson(),
      'period': 'decade',
    }).toEntity();

    expect(entity.period, StatsPeriod.year);
  });
}
