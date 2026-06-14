import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_absence_entry.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_attendance_summary.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_status.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_summary_view_data.dart';

StudentAttendanceSummary _summary({
  double rate = 90,
  int present = 80,
  int justified = 5,
  int unjustified = 3,
  List<StudentAbsenceEntry> absences = const [],
}) => StudentAttendanceSummary(
  studentId: 's',
  firstName: 'J',
  lastName: 'D',
  academicYearName: '2025-2026',
  period: StatsPeriod.year,
  windowStart: DateTime(2025, 9, 1),
  windowEnd: DateTime(2026, 6, 30),
  presenceRate: rate,
  presentDays: present,
  justifiedAbsenceDays: justified,
  unjustifiedAbsenceDays: unjustified,
  absences: absences,
);

void main() {
  test('total = present + justifiees + injustifiees', () {
    expect(PresenceSummaryViewData(_summary()).total, 88);
  });

  test('ratePercent arrondit le taux backend (non recalcule)', () {
    expect(PresenceSummaryViewData(_summary(rate: 86.4)).ratePercent, 86);
  });

  test('rateColor : seuils 95 (vert) / 88 (ambre) / sinon rouge', () {
    expect(
      PresenceSummaryViewData(_summary(rate: 96)).rateColor,
      AppColors.vertSavane,
    );
    expect(
      PresenceSummaryViewData(_summary(rate: 95)).rateColor,
      AppColors.vertSavane,
    );
    expect(
      PresenceSummaryViewData(_summary(rate: 90)).rateColor,
      AppColors.warning,
    );
    expect(
      PresenceSummaryViewData(_summary(rate: 88)).rateColor,
      AppColors.warning,
    );
    expect(
      PresenceSummaryViewData(_summary(rate: 80)).rateColor,
      AppColors.error,
    );
  });

  test('isPerfect ssi des jours scolaires et zero absence', () {
    expect(
      PresenceSummaryViewData(_summary(justified: 0, unjustified: 0)).isPerfect,
      isTrue,
    );
    expect(
      PresenceSummaryViewData(_summary(justified: 1, unjustified: 0)).isPerfect,
      isFalse,
    );
    expect(
      PresenceSummaryViewData(
        _summary(present: 0, justified: 0, unjustified: 0),
      ).isPerfect,
      isFalse,
    );
  });

  test('hasSchoolDays false quand total == 0', () {
    expect(
      PresenceSummaryViewData(
        _summary(present: 0, justified: 0, unjustified: 0),
      ).hasSchoolDays,
      isFalse,
    );
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
    final vm = PresenceSummaryViewData(_summary(absences: [older, newer]));

    expect(vm.sortedAbsences.first.date, DateTime(2026, 2, 12));
    expect(vm.sortedAbsences.last.date, DateTime(2026, 2, 5));
  });

  test('forAbsenceReason : injustifiee si unjustified ou unknown', () {
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
    expect(
      AttendanceDayStatusX.forAbsenceReason(null),
      AttendanceDayStatus.justified,
    );
  });
}
