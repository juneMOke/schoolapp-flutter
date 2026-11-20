import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_event_validation.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_phase_rule.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/days_between.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/school_year_progress.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

CalendarElement el(
  String id,
  CalendarNature nature,
  DateTime start,
  DateTime end, {
  CalendarSource source = CalendarSource.school,
  CalendarScope scope = const SchoolScope(),
  PeriodRhythm? rhythm,
  int? period,
  int? sub,
}) => CalendarElement(
  id: id,
  source: source,
  nature: nature,
  title: id,
  startDate: start,
  endDate: end,
  scope: scope,
  rhythm: rhythm,
  periodOrder: period,
  subPeriodOrder: sub,
);

void main() {
  group('CalendarDays', () {
    test('premier lundi de septembre strictement après', () {
      expect(
        CalendarDays.firstMondayOfSeptemberAfter(d(2026, 7, 3)),
        d(2026, 9, 7),
      );
      expect(
        CalendarDays.firstMondayOfSeptemberAfter(d(2025, 9, 1)),
        d(2026, 9, 7),
      );
      expect(
        CalendarDays.firstMondayOfSeptemberAfter(d(2025, 8, 31)),
        d(2025, 9, 1),
      );
    });

    test('lit un yyyy-MM-dd et refuse le reste', () {
      expect(CalendarDays.tryParse('2026-06-10'), d(2026, 6, 10));
      expect(CalendarDays.tryParse('2026-06-10T00:00:00Z'), d(2026, 6, 10));
      expect(CalendarDays.tryParse('bad'), isNull);
      expect(CalendarDays.format(d(2026, 1, 4)), '2026-01-04');
    });
  });

  group('CalendarPhaseRule (A3)', () {
    CalendarPhase phase(
      DateTime today, {
      CalendarStatus? status,
      DateTime? next,
    }) => CalendarPhaseRule.compute(
      status: status ?? CalendarStatus.published,
      startDate: d(2025, 9, 1),
      endDate: d(2026, 7, 3),
      today: today,
      nextFrameworkStartDate: next,
    );

    test('brouillon reste DRAFT', () {
      expect(
        phase(d(2026, 1, 1), status: CalendarStatus.draft),
        CalendarPhase.draft,
      );
    });
    test('bornes incluses', () {
      expect(phase(d(2025, 8, 31)), CalendarPhase.upcoming);
      expect(phase(d(2025, 9, 1)), CalendarPhase.inForce);
      expect(phase(d(2026, 7, 3)), CalendarPhase.inForce);
      expect(phase(d(2026, 7, 4)), CalendarPhase.ended);
    });
    test('archivé au cadre suivant, sinon au premier lundi de septembre', () {
      expect(phase(d(2026, 9, 6)), CalendarPhase.ended);
      expect(phase(d(2026, 9, 7)), CalendarPhase.archived);
      expect(
        phase(d(2026, 8, 31), next: d(2026, 8, 31)),
        CalendarPhase.archived,
      );
      expect(phase(d(2026, 9, 7), next: d(2026, 9, 14)), CalendarPhase.ended);
    });
  });

  group('CalendarScope (K7, A2)', () {
    test('aller-retour des formes connues', () {
      for (final raw in [
        'SCHOOL',
        'CYCLE:SEC',
        'LEVEL:SEC/CTEB7',
        'RHYTHM:SEMESTER',
        'CATALOG_LEVEL:P6',
      ]) {
        expect(CalendarScope.parse(raw).wire, raw);
      }
      expect(CalendarScope.parse(null), const SchoolScope());
      expect(CalendarScope.parse('LEVEL:SEC'), isA<UnknownScope>());
      expect(CalendarScope.parse('ROOM:12'), isA<UnknownScope>());
    });

    test('une classe est concernée selon la portée', () {
      const key = ClassroomScopeKey(
        cycleCode: 'SEC',
        levelCode: 'CTEB7',
        rhythm: PeriodRhythm.semester,
        catalogLevelCode: 'CTEB7',
      );
      expect(key.isConcernedBy(const SchoolScope()), isTrue);
      expect(key.isConcernedBy(const CycleScope('PRI')), isFalse);
      expect(
        key.isConcernedBy(
          const LevelScope(cycleCode: 'PRI', levelCode: 'CTEB7'),
        ),
        isFalse,
      );
      expect(
        key.isConcernedBy(const RhythmScope(PeriodRhythm.trimester)),
        isFalse,
      );
      expect(key.isConcernedBy(const CatalogLevelScope(['CTEB7'])), isTrue);
      expect(key.isConcernedBy(const UnknownScope('X')), isFalse);
    });
  });

  group('DaysBetween (CAL-R15)', () {
    test('priorité férié > examens > congés, période sans couleur', () {
      final days = DaysBetween.compute(
        from: d(2026, 6, 29),
        to: d(2026, 7, 5),
        elements: [
          el('p', CalendarNature.period, d(2026, 2, 1), d(2026, 7, 3)),
          el('ex', CalendarNature.exam, d(2026, 6, 29), d(2026, 7, 1)),
          el(
            'fer',
            CalendarNature.publicHoliday,
            d(2026, 6, 30),
            d(2026, 6, 30),
          ),
          el('vac', CalendarNature.holidayBreak, d(2026, 7, 4), d(2026, 9, 6)),
        ],
      );
      expect(days, hasLength(7));
      expect(days[0].topNature, CalendarNature.exam);
      expect(days[1].topNature, CalendarNature.publicHoliday);
      expect(days[1].isClosed, isTrue);
      expect(days[3].topNature, isNull); // jeudi : la période seule
      expect(days[5].topNature, CalendarNature.holidayBreak); // samedi : congé
    });

    test('le week-end ignore un événement de plusieurs jours', () {
      final days = DaysBetween.compute(
        from: d(2026, 6, 5),
        to: d(2026, 6, 7),
        elements: [
          el('int', CalendarNature.assessment, d(2026, 6, 5), d(2026, 6, 8)),
          el('fete', CalendarNature.schoolLife, d(2026, 6, 7), d(2026, 6, 7)),
        ],
      );
      expect(days[0].topNature, CalendarNature.assessment);
      expect(days[1].topNature, isNull);
      expect(days[2].topNature, CalendarNature.schoolLife);
    });

    test('filtre par la portée de la classe', () {
      const key = ClassroomScopeKey(cycleCode: 'PRI', levelCode: 'P6');
      final days = DaysBetween.compute(
        from: d(2026, 6, 10),
        to: d(2026, 6, 10),
        classroom: key,
        elements: [
          el(
            'sec',
            CalendarNature.exam,
            d(2026, 6, 10),
            d(2026, 6, 10),
            scope: const CycleScope('SEC'),
          ),
          el(
            'p6',
            CalendarNature.assessment,
            d(2026, 6, 10),
            d(2026, 6, 10),
            scope: const LevelScope(cycleCode: 'PRI', levelCode: 'P6'),
          ),
        ],
      );
      expect(days.single.elements.map((e) => e.id), ['p6']);
    });
  });

  group('SchoolYearProgress (CAL-R14, A2 de la spec)', () {
    final elements = [
      el(
        'P3',
        CalendarNature.period,
        d(2026, 2, 2),
        d(2026, 4, 10),
        rhythm: PeriodRhythm.semester,
        period: 2,
        sub: 1,
      ),
      el(
        'P4',
        CalendarNature.period,
        d(2026, 4, 13),
        d(2026, 7, 3),
        rhythm: PeriodRhythm.semester,
        period: 2,
        sub: 2,
      ),
      el(
        'T3',
        CalendarNature.period,
        d(2026, 4, 13),
        d(2026, 7, 3),
        rhythm: PeriodRhythm.trimester,
        period: 3,
        sub: 2,
      ),
      el('exS2', CalendarNature.exam, d(2026, 6, 15), d(2026, 6, 26)),
      el('vac', CalendarNature.holidayBreak, d(2026, 7, 4), d(2026, 9, 6)),
    ];

    test('le 10 juin 2026 : semaine 41 / 44, P4, examens dans 5 j', () {
      final progress = SchoolYearProgress.compute(
        startDate: d(2025, 9, 1),
        endDate: d(2026, 7, 3),
        today: d(2026, 6, 10),
        elements: elements,
        rhythm: PeriodRhythm.semester,
      )!;
      expect(progress.week, 41);
      expect(progress.weekCount, 44);
      expect(progress.currentPeriod!.id, 'P4');
      expect(progress.currentPeriod!.subPeriodRank, 4);
      expect(progress.nextDeadline!.id, 'exS2');
      expect(progress.daysUntilNextDeadline, 5);
    });

    test('le rythme choisit le jeu de périodes (A1)', () {
      final progress = SchoolYearProgress.compute(
        startDate: d(2025, 9, 1),
        endDate: d(2026, 7, 3),
        today: d(2026, 6, 10),
        elements: elements,
        rhythm: PeriodRhythm.trimester,
      )!;
      expect(progress.currentPeriod!.id, 'T3');
    });

    test('hors année : rien', () {
      expect(
        SchoolYearProgress.compute(
          startDate: d(2025, 9, 1),
          endDate: d(2026, 7, 3),
          today: d(2026, 7, 10),
          elements: elements,
        ),
        isNull,
      );
    });
  });

  group('CalendarEventValidation (CAL-R7)', () {
    final nationals = [
      el(
        'fer',
        CalendarNature.publicHoliday,
        d(2026, 6, 30),
        d(2026, 6, 30),
        source: CalendarSource.national,
      ),
      el(
        'exN',
        CalendarNature.exam,
        d(2026, 6, 15),
        d(2026, 6, 19),
        source: CalendarSource.national,
      ),
    ];

    CalendarEventCheck check(
      CalendarNature nature,
      DateTime s,
      DateTime e, {
      String title = 'Réunion',
    }) => CalendarEventValidation.check(
      title: title,
      nature: nature,
      startDate: s,
      endDate: e,
      yearStart: d(2025, 9, 1),
      yearEnd: d(2026, 7, 3),
      nationalElements: nationals,
    );

    test('fin avant début et hors année bloquent', () {
      expect(
        check(CalendarNature.schoolLife, d(2026, 6, 2), d(2026, 6, 1)).errors,
        [CalendarEventError.endBeforeStart],
      );
      expect(
        check(CalendarNature.schoolLife, d(2026, 7, 2), d(2026, 7, 6)).errors,
        [CalendarEventError.outOfYear],
      );
      expect(
        check(
          CalendarNature.schoolLife,
          d(2026, 6, 2),
          d(2026, 6, 2),
          title: ' ',
        ).canSave,
        isFalse,
      );
    });

    test('chevaucher un férié avertit sans bloquer', () {
      final result = check(
        CalendarNature.schoolLife,
        d(2026, 6, 29),
        d(2026, 6, 30),
      );
      expect(result.canSave, isTrue);
      expect(result.warnings.single.isBreakOverlap, isTrue);
    });

    test('une interrogation pendant un examen national avertit', () {
      final result = check(
        CalendarNature.assessment,
        d(2026, 6, 16),
        d(2026, 6, 16),
      );
      expect(result.warnings.single.isBreakOverlap, isFalse);
      expect(
        check(
          CalendarNature.schoolLife,
          d(2026, 6, 16),
          d(2026, 6, 16),
        ).warnings,
        isEmpty,
      );
    });
  });

  test('libellé de l’année suivante', () {
    expect(SchoolCalendar.shiftYearLabel('2026-2027', 1), '2027-2028');
    expect(SchoolCalendar.shiftYearLabel('2026', 1), isNull);
  });
}
