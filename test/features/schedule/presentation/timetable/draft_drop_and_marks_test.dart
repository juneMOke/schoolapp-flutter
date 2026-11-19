import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/class_calendar_reader.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/draft_drop.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/timetable_marks.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_grid_marks.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/days_between.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

const _s1 = TimeSlot(
  id: 's1',
  order: 1,
  startTime: '07:30:00',
  endTime: '08:20:00',
);
const _s2 = TimeSlot(
  id: 's2',
  order: 2,
  startTime: '08:20:00',
  endTime: '09:10:00',
);
const _math = TimetableCourse(
  coursId: 'math',
  classroomId: 'c',
  branchId: 'b1',
  branchLabel: 'Maths',
  teacherId: 'kashala',
  teacherLabel: 'Kashala',
);
const _fr = TimetableCourse(
  coursId: 'fr',
  classroomId: 'c',
  branchId: 'b2',
  branchLabel: 'Français',
  teacherId: 'mavinga',
  teacherLabel: 'Mavinga',
);

ClassTimetableCell _cell(
  String id,
  Weekday day,
  TimeSlot slot,
  String? cours, {
  TimetableCellStatus status = TimetableCellStatus.draft,
  RecordSyncState sync = RecordSyncState.synced,
}) => ClassTimetableCell(
  id: id,
  classroomId: 'c',
  classroomLabel: '7e A',
  status: status,
  draftId: status == TimetableCellStatus.draft ? 'd' : null,
  day: day,
  slotId: slot.id,
  range: MinuteRange.fromClocks(slot.startTime, slot.endTime)!,
  coursId: cours,
  teacherId: const {'math': 'kashala', 'fr': 'mavinga'}[cours],
  subjectLabel: cours,
  syncState: sync,
);

ClassTimetableView _view({
  List<ClassTimetableCell> draft = const [],
  List<ClassTimetableCell> published = const [],
  List<TeacherBooking> bookings = const [],
  List<TimetableCourse> programme = const [_math, _fr],
}) => ClassTimetableView(
  classroom: const TimetableClassOption(
    classroomId: 'c',
    name: '7e A',
    cycleCode: 'SEC',
    cycleName: 'Sec',
    levelCode: 'L7',
    levelName: '7e',
  ),
  grid: null,
  slots: const [_s1, _s2],
  header: null,
  published: published,
  draft: draft,
  programme: programme,
  othersKnown: true,
  bookings: bookings,
);

TimetableCell _gridCell(String id, String cours) => TimetableCell(
  sessionId: id,
  coursId: cours,
  classroomId: 'c',
  classroomLabel: '',
  teacherId: cours,
  teacherLabel: cours,
  subjectLabel: cours,
);

void main() {
  final l10n = AppLocalizationsFr();
  const busyKashala = TeacherBooking(
    teacherId: 'kashala',
    day: Weekday.mon,
    range: MinuteRange(460, 510),
    classroomId: 'c7b',
    classroomLabel: '7e B',
  );

  group('déposer (I9 à I11)', () {
    test('un cours de la réserve se pose', () {
      final out = DraftDrop.onSlot(
        _view(),
        const CourseDragData('math'),
        Weekday.tue,
        _s1,
      );
      expect(out, isA<DropAccepted>());
      final change = (out as DropAccepted).changes.single;
      expect(
        (change.day, change.slot.id, change.course?.coursId),
        (Weekday.tue, 's1', 'math'),
      );
    });

    test('un cours en conflit est refusé avant tout enregistrement (A5)', () {
      final out = DraftDrop.onSlot(
        _view(bookings: const [busyKashala]),
        const CourseDragData('math'),
        Weekday.mon,
        _s1,
      );
      expect(out, isA<DropRefused>());
      expect((out as DropRefused).booking.classroomLabel, '7e B');
    });

    test('une séance se déplace vers un créneau libre', () {
      final view = _view(draft: [_cell('a', Weekday.mon, _s1, 'math')]);
      final out = DraftDrop.onSlot(
        view,
        SessionDragData(_gridCell('a', 'math'), Weekday.mon, _s1),
        Weekday.wed,
        _s2,
      );
      final changes = (out as DropAccepted).changes;
      expect(
        [for (final c in changes) (c.day, c.slot.id, c.course?.coursId)],
        [(Weekday.mon, 's1', null), (Weekday.wed, 's2', 'math')],
      );
    });

    test('déposée sur une séance, les deux s’échangent (A6)', () {
      final view = _view(
        draft: [
          _cell('a', Weekday.tue, _s1, 'math'),
          _cell('b', Weekday.tue, _s2, 'fr'),
        ],
      );
      final out = DraftDrop.onSlot(
        view,
        SessionDragData(_gridCell('a', 'math'), Weekday.tue, _s1),
        Weekday.tue,
        _s2,
      );
      final changes = (out as DropAccepted).changes;
      expect(
        [for (final c in changes) (c.slot.id, c.course?.coursId)],
        [('s1', 'fr'), ('s2', 'math')],
      );
    });

    test('l’échange est refusé si l’un des deux sens crée un conflit', () {
      final view = _view(
        draft: [
          _cell('a', Weekday.mon, _s2, 'math'),
          _cell('b', Weekday.mon, _s1, 'fr'),
        ],
        bookings: const [busyKashala],
      );
      // Maths irait à 07:30, où Kashala a cours en 7e B.
      final out = DraftDrop.onSlot(
        view,
        SessionDragData(_gridCell('a', 'math'), Weekday.mon, _s2),
        Weekday.mon,
        _s1,
      );
      expect(out, isA<DropRefused>());
    });

    test('sur sa propre case : rien ; sur la réserve : retirée', () {
      final data = SessionDragData(_gridCell('a', 'math'), Weekday.mon, _s1);
      expect(
        DraftDrop.onSlot(_view(), data, Weekday.mon, _s1),
        isA<DropIgnored>(),
      );
      final removed = DraftDrop.onReserve(data) as DropAccepted;
      expect(removed.changes.single.course, isNull);
      expect(
        DraftDrop.onReserve(const CourseDragData('fr')),
        isA<DropIgnored>(),
      );
    });
  });

  group('marques', () {
    test('un férié ferme son jour, nommé ; les examens ne ferment rien', () {
      final days = DaysBetween.compute(
        from: DateTime.utc(2026, 6, 29),
        to: DateTime.utc(2026, 7, 5),
        elements: [
          CalendarElement(
            id: 'f',
            source: CalendarSource.national,
            nature: CalendarNature.publicHoliday,
            title: 'Indépendance',
            startDate: DateTime.utc(2026, 6, 30),
            endDate: DateTime.utc(2026, 6, 30),
          ),
          CalendarElement(
            id: 'x',
            source: CalendarSource.school,
            nature: CalendarNature.exam,
            title: 'Examens',
            startDate: DateTime.utc(2026, 7, 1),
            endDate: DateTime.utc(2026, 7, 2),
          ),
        ],
      );
      final closed = TimetableMarks.closedDays(
        ClassCalendarWeek(
          days: days,
          calendar: SchoolCalendar(
            id: 'c',
            yearLabel: '2025-2026',
            status: CalendarStatus.published,
            startDate: DateTime.utc(2025, 9, 1),
            endDate: DateTime.utc(2026, 7, 3),
            framework: FrameworkState.integrated,
            revision: 1,
          ),
        ),
        l10n,
      );
      expect(closed.keys, [Weekday.tue]);
      expect(closed[Weekday.tue]!.header, 'Jour férié');
      expect(closed[Weekday.tue]!.period, 'Indépendance');
    });

    test('« En cours » puis « Ensuite », à l’heure de l’école (A3)', () {
      final view = _view(
        published: [
          _cell(
            'm1',
            Weekday.wed,
            _s1,
            'math',
            status: TimetableCellStatus.published,
          ),
          _cell(
            'm2',
            Weekday.wed,
            _s2,
            'fr',
            status: TimetableCellStatus.published,
          ),
        ],
      );
      // Mercredi 3 juin 2026, 07:45.
      final now = TimetableMarks.now(view, null, DateTime(2026, 6, 3, 7, 45))!;
      expect(now.current?.id, 'm1');
      expect(now.next?.id, 'm2');
      final later = TimetableMarks.now(view, null, DateTime(2026, 6, 3, 10))!;
      expect((later.current, later.next), (null, null));
      expect(TimetableMarks.now(view, null, DateTime(2026, 6, 7, 9)), isNull);
    });

    test('hors programme, refusée, conflit : une alerte par séance', () {
      final view = _view(
        draft: [
          _cell('gone', Weekday.tue, _s1, 'latin'),
          _cell('ko', Weekday.tue, _s2, 'fr', sync: RecordSyncState.failed),
          _cell('busy', Weekday.mon, _s1, 'math'),
        ],
        bookings: const [busyKashala],
      );
      final alerts = TimetableMarks.draftAlerts(view, l10n);
      expect(alerts['gone'], 'Hors programme');
      expect(alerts['ko'], 'Refusée par le serveur');
      expect(alerts['busy'], 'Conflit avec 7e B');
      expect(TimetableMarks.outOfProgramme(view), {'gone'});
    });

    test('repérer un cours relie ses séances, estompe les autres (A4)', () {
      const marks = ScheduleGridMarks(linkedCoursId: 'math');
      expect(marks.emphasisOf(_gridCell('a', 'math')), SessionEmphasis.linked);
      expect(marks.emphasisOf(_gridCell('b', 'fr')), SessionEmphasis.dimmed);
      const filtered = ScheduleGridMarks(visibleCoursIds: {'fr'});
      expect(
        filtered.emphasisOf(_gridCell('a', 'math')),
        SessionEmphasis.dimmed,
      );
      expect(filtered.emphasisOf(_gridCell('b', 'fr')), SessionEmphasis.normal);
    });
  });
}
