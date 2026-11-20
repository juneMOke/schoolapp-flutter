import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_phase_rule.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_replacements.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/days_between.dart';

/// Vecteurs partagés du lot V0 — **les mêmes fichiers que le serveur**
/// (`src/test/resources/calendar/*.json`), copiés tels quels, à l'octet près.
/// Ne jamais les retoucher à la main : les recopier du dépôt back.
List<Map<String, dynamic>> _cases(String path) =>
    ((jsonDecode(File(path).readAsStringSync()) as Map)['cases'] as List)
        .cast<Map<String, dynamic>>();

DateTime _day(Object? raw) => CalendarDays.tryParse(raw as String)!;

void main() {
  group('phase-vectors', () {
    for (final c in _cases('test/fixtures/calendar/phase-vectors.json')) {
      test(c['name'], () {
        final input = c['input'] as Map;
        final next = input['nextFrameworkStartDate'];
        final phase = CalendarPhaseRule.compute(
          status: CalendarStatus.fromWire(input['status']),
          startDate: _day(input['startDate']),
          endDate: _day(input['endDate']),
          today: _day(input['today']),
          nextFrameworkStartDate: next == null ? null : _day(next),
        );
        expect(phase.wire, c['expected']);
      });
    }
  });

  group('days-between-vectors', () {
    for (final c in _cases(
      'test/fixtures/calendar/days-between-vectors.json',
    )) {
      test(c['name'], () {
        final input = c['input'] as Map;
        final classroom = input['classroom'] as Map;
        final days = DaysBetween.compute(
          from: _day(input['from']),
          to: _day(input['to']),
          classroom: ClassroomScopeKey(
            cycleCode: classroom['cycleCode'],
            levelCode: classroom['levelCode'],
            rhythm: PeriodRhythm.fromWire(classroom['rhythm']),
            catalogLevelCode: classroom['catalogLevelCode'],
          ),
          // Les remplacements se résolvent d'abord, sur la liste brute, comme
          // `daysBetween` côté serveur.
          elements: CalendarReplacements.resolve([
            for (final e in input['elements'] as List)
              CalendarElement(
                id: e['id'],
                source: CalendarSource.fromWire(e['source']),
                nature: CalendarNature.fromWire(e['nature']),
                title: e['id'],
                startDate: _day(e['startDate']),
                endDate: _day(e['endDate']),
                scope: CalendarScope.parse(e['scope']),
                replaces: e['replaces'],
              ),
          ]),
        );
        expect([
          for (final day in days)
            {
              'date': CalendarDays.format(day.date),
              'elementIds': [for (final e in day.elements) e.id],
              'topNature': day.topNature?.wire,
              'noClasses': day.isClosed,
            },
        ], c['expected']);
      });
    }
  });
}
