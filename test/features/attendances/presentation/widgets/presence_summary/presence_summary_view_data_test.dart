import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/student_attendance_stats.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_absence_entry.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_status.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_summary_view_data.dart';

StudentAttendanceStats _stats({
  int daysCalled = 88,
  List<StudentAbsenceEntry> entries = const [],
  bool bootstrapComplete = true,
}) => StudentAttendanceStats(
  period: StatsPeriod.year,
  from: DateTime(2025, 9, 1),
  to: DateTime(2026, 6, 30),
  daysCalled: daysCalled,
  entries: entries,
  bootstrapComplete: bootstrapComplete,
);

List<StudentAbsenceEntry> _absences({int justified = 0, int unjustified = 0}) =>
    [
      for (var i = 0; i < justified; i++)
        StudentAbsenceEntry(
          date: DateTime(2026, 2, i + 1),
          reason: AbsenceReason.sickness,
        ),
      for (var i = 0; i < unjustified; i++)
        StudentAbsenceEntry(
          date: DateTime(2026, 3, i + 1),
          reason: AbsenceReason.unjustified,
        ),
    ];

void main() {
  test('total = jours reellement appeles (daysCalled)', () {
    expect(PresenceSummaryViewData(_stats(daysCalled: 88)).total, 88);
  });

  test('present = daysCalled - absences', () {
    final vm = PresenceSummaryViewData(
      _stats(daysCalled: 88, entries: _absences(justified: 5, unjustified: 3)),
    );
    expect(vm.present, 80);
  });

  test('ratePercent arrondit le taux local (present/daysCalled)', () {
    // 76/88 = 86.36...% -> 86
    final vm = PresenceSummaryViewData(
      _stats(daysCalled: 88, entries: _absences(justified: 8, unjustified: 4)),
    );
    expect(vm.ratePercent, 86);
  });

  test('rateColor : seuils 95 (vert) / 88 (ambre) / sinon rouge', () {
    Color colorFor(int daysCalled, int absences) => PresenceSummaryViewData(
      _stats(
        daysCalled: daysCalled,
        entries: _absences(justified: absences),
      ),
    ).rateColor;

    expect(colorFor(100, 4), AppColors.vertSavane); // 96%
    expect(colorFor(100, 5), AppColors.vertSavane); // 95%
    expect(colorFor(100, 10), AppColors.warning); // 90%
    expect(colorFor(100, 12), AppColors.warning); // 88%
    expect(colorFor(100, 20), AppColors.error); // 80%
  });

  test('isPerfect ssi des jours scolaires et zero absence', () {
    expect(PresenceSummaryViewData(_stats(daysCalled: 10)).isPerfect, isTrue);
    expect(
      PresenceSummaryViewData(
        _stats(daysCalled: 10, entries: _absences(justified: 1)),
      ).isPerfect,
      isFalse,
    );
    expect(PresenceSummaryViewData(_stats(daysCalled: 0)).isPerfect, isFalse);
  });

  test('hasSchoolDays false quand daysCalled == 0 (aucun appel fait)', () {
    expect(
      PresenceSummaryViewData(_stats(daysCalled: 0)).hasSchoolDays,
      isFalse,
    );
  });

  test('rate/ratePercent nuls proprement si daysCalled == 0', () {
    final vm = PresenceSummaryViewData(_stats(daysCalled: 0));
    expect(vm.rate, isNull);
    expect(vm.ratePercent, 0);
  });

  test('sortedAbsences : du plus recent au plus ancien', () {
    final older = StudentAbsenceEntry(
      date: DateTime(2026, 2, 5),
      reason: AbsenceReason.sickness,
    );
    final newer = StudentAbsenceEntry(
      date: DateTime(2026, 2, 12),
      reason: AbsenceReason.unjustified,
    );
    final vm = PresenceSummaryViewData(_stats(entries: [older, newer]));

    expect(vm.sortedAbsences.first.date, DateTime(2026, 2, 12));
    expect(vm.sortedAbsences.last.date, DateTime(2026, 2, 5));
  });

  test(
    'forAbsenceReason : injustifiee si unjustified, unknown, ou sans motif',
    () {
      expect(
        AttendanceDayStatusX.forAbsenceReason(AbsenceReason.unjustified),
        AttendanceDayStatus.unjustified,
      );
      expect(
        AttendanceDayStatusX.forAbsenceReason(AbsenceReason.unknown),
        AttendanceDayStatus.unjustified,
      );
      expect(
        AttendanceDayStatusX.forAbsenceReason(AbsenceReason.sickness),
        AttendanceDayStatus.justified,
      );
      // Renversé : une absence sans motif est injustifiée. Elle était comptée
      // justifiée ici et dans le calcul offline, alors que le tableau de bord la
      // rangeait déjà du côté injustifié — deux écrans, deux réponses.
      expect(
        AttendanceDayStatusX.forAbsenceReason(null),
        AttendanceDayStatus.unjustified,
      );
    },
  );
}
