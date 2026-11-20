import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';
import 'package:school_app_flutter/features/schedule/domain/services/timetable_metrics.dart';

TeacherBooking booking(
  String teacher,
  Weekday day,
  int s,
  int e, {
  String classroom = 'C7B',
}) => TeacherBooking(
  teacherId: teacher,
  day: day,
  range: MinuteRange(s, e),
  classroomId: classroom,
  classroomLabel: '7e B',
);

void main() {
  group('SlotOverlap (R4, A11, A25)', () {
    test('chevauchement sur les minutes, bornes jointives exclues', () {
      expect(
        SlotOverlap.overlaps(
          const MinuteRange(450, 500),
          const MinuteRange(465, 515),
        ),
        isTrue,
      );
      expect(
        SlotOverlap.overlaps(
          const MinuteRange(450, 500),
          const MinuteRange(500, 550),
        ),
        isFalse,
      );
      expect(
        SlotOverlap.overlaps(
          const MinuteRange(500, 550),
          const MinuteRange(450, 500),
        ),
        isFalse,
      );
    });

    test('A25 : 07:45-08:35 au primaire bloque 07:30-08:20 au secondaire', () {
      final conflicts = SlotOverlap.conflictsFor(
        teacherId: 'kalala',
        classroomId: 'C8B',
        day: Weekday.mon,
        range: MinuteRange.fromClocks('07:30', '08:20')!,
        bookings: [booking('kalala', Weekday.mon, 465, 515, classroom: 'P6A')],
      );
      expect(conflicts, hasLength(1));
    });

    test('sans enseignant, autre jour, ou même classe : aucun conflit', () {
      final bookings = [booking('kalala', Weekday.mon, 450, 500)];
      MinuteRange r() => const MinuteRange(450, 500);
      expect(
        SlotOverlap.conflictsFor(
          teacherId: null,
          classroomId: 'X',
          day: Weekday.mon,
          range: r(),
          bookings: bookings,
        ),
        isEmpty,
      );
      expect(
        SlotOverlap.conflictsFor(
          teacherId: 'kalala',
          classroomId: 'X',
          day: Weekday.tue,
          range: r(),
          bookings: bookings,
        ),
        isEmpty,
      );
      expect(
        SlotOverlap.conflictsFor(
          teacherId: 'kalala',
          classroomId: 'C7B',
          day: Weekday.mon,
          range: r(),
          bookings: bookings,
        ),
        isEmpty,
      );
    });

    test('lit HH:mm et HH:mm:ss', () {
      expect(MinuteRange.parseClock('07:30:00'), 450);
      expect(MinuteRange.parseClock('x'), isNull);
    });
  });

  group('PlacedHours (R5)', () {
    test('placé / prévu, cours à 0 h exclu, volume inconnu propagé', () {
      final volumes = PlacedHours.volumes(
        plannedByCours: const {'math': 6, 'fr': 2, 'eps': 0, 'art': null},
        placedCoursIds: const ['math', 'math', 'fr', 'fr', 'fr', null],
      );
      expect(volumes.map((v) => v.coursId), ['math', 'fr', 'art']);
      expect(volumes[0].remaining, 4);
      expect(volumes[1].isOver, isTrue);
      expect(volumes[2].remaining, isNull);
      expect(PlacedHours.totals(volumes), (5, null));
      expect(PlacedHours.totals(volumes.sublist(0, 2)), (5, 8));
    });
  });

  group('CurrentSession (R11)', () {
    const sessions = [
      DaySession(id: 'b', range: MinuteRange(550, 600)),
      DaySession(id: 'a', range: MinuteRange(500, 550)),
    ];

    test('en cours puis ensuite', () {
      final state = CurrentSession.at(minuteOfDay: 510, sessions: sessions);
      expect(state.current!.id, 'a');
      expect(state.next!.id, 'b');
    });
    test('avant la journée, puis après', () {
      expect(
        CurrentSession.at(minuteOfDay: 400, sessions: sessions).next!.id,
        'a',
      );
      expect(
        CurrentSession.at(minuteOfDay: 700, sessions: sessions).isOver,
        isTrue,
      );
    });
    test('dimanche : aucun jour de cours', () {
      expect(CurrentSession.weekdayOf(DateTime(2026, 6, 14)), isNull);
      expect(CurrentSession.weekdayOf(DateTime(2026, 6, 13)), Weekday.sat);
    });
  });
}
