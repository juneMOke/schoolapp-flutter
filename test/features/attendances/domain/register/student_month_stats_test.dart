import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/presence/domain/presence_justification.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_closure.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_line.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_month.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_student.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_month_recap.dart';
import 'package:school_app_flutter/features/attendances/domain/services/student_month_stats.dart';
import 'package:school_app_flutter/features/attendances/domain/services/student_presence_month.dart';

ClassPresenceStudent student(String id, String last) => ClassPresenceStudent(
  id: id,
  firstName: 'P$id',
  lastName: last,
  gender: StudentGender.female,
  number: 0,
);

ClassPresenceLine incident(
  ClassPresenceStudent s,
  PresenceStatus status, {
  int lateMinutes = 0,
  bool justified = false,
}) => ClassPresenceLine(
  student: s,
  mark: PresenceMark(
    status: status,
    lateMinutes: lateMinutes,
    justification: justified
        ? const PresenceJustification(reason: AbsenceReason.sickness)
        : null,
  ),
);

void main() {
  final a = student('a', 'Mbuyi');
  final b = student('b', 'Ilunga');
  final c = student('c', 'Zola');
  // Septembre 2026 : le 1er est un mardi. Aujourd'hui = vendredi 4.
  const today = '2026-09-04';
  const days = ['2026-09-01', '2026-09-02', '2026-09-03', '2026-09-04'];

  ClassPresenceMonth month({bool closed = false}) => ClassPresenceMonth(
    classroomId: 'c1',
    academicYearId: 'y1',
    month: '2026-09',
    students: [a, b, c],
    // Le 4 n'a pas d'appel.
    calledDays: const {'2026-09-01', '2026-09-02', '2026-09-03'},
    incidents:
        {
          '2026-09-01': {
            a: incident(a, PresenceStatus.absent),
            b: incident(b, PresenceStatus.late, lateMinutes: 18),
          },
          '2026-09-02': {a: incident(a, PresenceStatus.absent)},
          '2026-09-03': {
            a: incident(a, PresenceStatus.absent, justified: true),
          },
        }.map(
          (day, byStudent) => MapEntry(day, {
            for (final entry in byStudent.entries) entry.key.id: entry.value,
          }),
        ),
    closure: closed ? const ClassPresenceClosure() : null,
  );

  group('StudentMonthStats', () {
    test('jours de classe jusqu à aujourd hui, non pointés comptés à part', () {
      final stats = StudentMonthStats.of(month(), 'c', schoolDays: days);
      expect(stats.schoolDays, 4);
      expect(stats.presences, 3);
      expect(stats.notMarked, 1);
      expect(stats.rate, closeTo(0.75, 1e-9));
      // Taux < 85 % dès qu'un jour est pointé : à surveiller.
      expect(stats.toWatch, isTrue);
      expect(stats.perfect, isTrue);
    });

    test('un mois clos compte ses jours sans appel présents', () {
      final stats = StudentMonthStats.of(
        month(closed: true),
        'c',
        schoolDays: days,
      );
      expect(stats.notMarked, 0);
      expect(stats.presences, 4);
      expect(stats.toWatch, isFalse);
    });

    test('deux absences non justifiées : à surveiller', () {
      final stats = StudentMonthStats.of(
        month(closed: true),
        'a',
        schoolDays: days,
      );
      expect(stats.absentUnjustified, 2);
      expect(stats.absentJustified, 1);
      expect(stats.toWatch, isTrue);
      expect(stats.perfect, isFalse);
    });

    test('un retard est une présence, compté à part avec ses minutes', () {
      final stats = StudentMonthStats.of(
        month(closed: true),
        'b',
        schoolDays: days,
      );
      expect(stats.presences, 4);
      expect(stats.late, 1);
      expect(stats.lateMinutes, 18);
      expect(stats.lateUnjustified, 1);
      expect(stats.perfect, isFalse);
    });

    test('sans jour de classe, le taux vaut 1', () {
      final stats = StudentMonthStats.of(month(), 'c', schoolDays: const []);
      expect(stats.rate, 1);
      expect(stats.toWatch, isFalse);
    });
  });

  group('ClassMonthRecap', () {
    test('filtres, totaux et jours-élève non pointés', () {
      final recap = ClassMonthRecap.build(
        month(),
        today: today,
        query: ClassRecapQuery.none,
      );
      expect(recap.schoolDays, 4);
      expect(recap.count(ClassRecapFilter.toWatch), 3);
      expect(recap.notMarked, 3);
      expect(recap.late, 1);
      expect(recap.absentUnjustified, 2);

      final perfect = ClassMonthRecap.build(
        month(closed: true),
        today: today,
        query: const ClassRecapQuery(filter: ClassRecapFilter.perfect),
      );
      expect(perfect.rows.map((r) => r.student.id), ['c']);

      final searched = ClassMonthRecap.build(
        month(),
        today: today,
        query: const ClassRecapQuery(text: 'zol'),
      );
      expect(searched.rows.single.student, c);
    });
  });

  group('StudentPresenceMonth', () {
    test('calendrier : lundi en case vide, statut du jour, incidents', () {
      final sheet = StudentPresenceMonth.build(month(), a, today: today);
      // Le mois commence un mardi : une case vide avant.
      expect(sheet.calendar.first, isNull);
      expect(sheet.calendar[1]!.status, PresenceStatus.absent);
      // Le 4 n'a pas d'appel : à pointer.
      expect(sheet.calendar[4]!.status, PresenceStatus.none);
      // Le 7 est à venir.
      expect(sheet.calendar[5]!.upcoming, isTrue);
      expect(sheet.incidents.map((i) => i.day), [
        '2026-09-01',
        '2026-09-02',
        '2026-09-03',
      ]);
      expect(sheet.incidents.last.reason, AbsenceReason.sickness);
      expect(sheet.isHoliday, isFalse);
    });
  });
}
