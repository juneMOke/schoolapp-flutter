import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_replacements.dart';

CalendarElement _e(
  String id, {
  CalendarNature nature = CalendarNature.schoolLife,
  bool national = false,
  String? replaces,
  PeriodRhythm? rhythm,
  int? period,
  int? sub,
}) => CalendarElement(
  id: id,
  source: national ? CalendarSource.national : CalendarSource.school,
  nature: nature,
  title: id,
  startDate: DateTime.utc(2026, 11, 14),
  endDate: DateTime.utc(2026, 11, 14),
  replaces: replaces,
  rhythm: rhythm,
  periodOrder: period,
  subPeriodOrder: sub,
);

List<String> _ids(List<CalendarElement> list) => [for (final e in list) e.id];

void main() {
  test('un remplacement masque l’élément national, et reste seul', () {
    final out = CalendarReplacements.resolve([
      _e('n', national: true),
      _e('r', replaces: 'n'),
      _e('autre'),
    ]);
    expect(_ids(out), ['r', 'autre']);
  });

  test('un remplacement orphelin s’écarte', () {
    expect(_ids(CalendarReplacements.resolve([_e('r', replaces: 'x')])), []);
  });

  test('un remplacement refusé ne masque rien et reste montré', () {
    final out = CalendarReplacements.resolve(
      [_e('n', national: true), _e('r', replaces: 'n')],
      inert: {'r'},
    );
    expect(_ids(out), ['n', 'r']);
  });

  test('un refusé à côté d’un remplacement vivant : le vivant masque', () {
    final out = CalendarReplacements.resolve(
      [
        _e('n', national: true),
        _e('refuse', replaces: 'n'),
        _e('vivant', replaces: 'n'),
      ],
      inert: {'refuse'},
    );
    expect(_ids(out), ['refuse', 'vivant']);
  });

  test('une période remplacée garde son rythme et ses rangs', () {
    final out = CalendarReplacements.resolve([
      _e(
        'p2',
        nature: CalendarNature.period,
        national: true,
        rhythm: PeriodRhythm.semester,
        period: 1,
        sub: 2,
      ),
      _e('p2-ecole', nature: CalendarNature.period, replaces: 'p2'),
    ]);
    final kept = out.single;
    expect(kept.id, 'p2-ecole');
    expect(kept.replaces, 'p2');
    expect(kept.rhythm, PeriodRhythm.semester);
    expect(kept.subPeriodRank, 2);
  });

  test('un remplacement d’un élément qui ne s’y prête plus est orphelin', () {
    CalendarElement national({bool replaceable = true, String? scope}) =>
        CalendarElement(
          id: 'n',
          source: CalendarSource.national,
          nature: CalendarNature.schoolLife,
          title: 'n',
          startDate: DateTime.utc(2026, 11, 14),
          endDate: DateTime.utc(2026, 11, 14),
          replaceable: replaceable,
          scope: scope == null
              ? const SchoolScope()
              : CalendarScope.parse(scope),
        );
    final r = _e('r', replaces: 'n');
    expect(_ids(CalendarReplacements.resolveForDisplay([national(), r])), [
      'r',
    ]);
    expect(
      _ids(
        CalendarReplacements.resolveForDisplay([
          national(replaceable: false),
          r,
        ]),
      ),
      ['n'],
    );
    expect(
      _ids(
        CalendarReplacements.resolveForDisplay([
          national(scope: 'RHYTHM:TRIMESTER'),
          r,
        ]),
      ),
      ['n'],
    );
  });
}
