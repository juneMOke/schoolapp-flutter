import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/data/models/attendance_overview_response_model/attendance_overview_response_model.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_evolution_granularity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_weekday.dart';

void main() {
  Map<String, dynamic> buildJson() => {
    'context': {
      'schoolYear': '2025-2026',
      'period': 'year',
      'periodStart': '2025-09-01',
      'periodEnd': '2026-06-30',
      'generatedAt': '2026-02-05T08:30:00.000Z',
    },
    'kpis': {
      'presenceRate': 90,
      'justifiedAbsenceRate': 6.5,
      'unjustifiedAbsenceRate': 3.5,
      'recordedDays': 180,
      'presentDays': 162,
      'justifiedAbsenceDays': 12,
      'unjustifiedAbsenceDays': 6,
    },
    'evolution': {
      'granularity': 'month',
      'currentBucketIndex': 1,
      'buckets': [
        {
          'key': '2025-09',
          'presenceRate': 92.0,
          'recordedDays': 20,
          'isCurrent': false,
        },
        {
          'key': '2025-10',
          'presenceRate': 88.0,
          'recordedDays': 22,
          'isCurrent': true,
        },
      ],
    },
    'byClass': [
      {
        'cycle': 'PRIMARY',
        'level': 'CP',
        'classroomId': 'cls-1',
        'className': 'CP-A',
        'presenceRate': 91.0,
        'justifiedAbsenceRate': 5.0,
        'unjustifiedAbsenceRate': 4.0,
        'recordedDays': 180,
      },
    ],
    'topAbsentClasses': [
      {
        'classroomId': 'cls-9',
        'className': 'CM2-B',
        'level': 'CM2',
        'absenceRate': 18.5,
        'absenceDays': 33,
      },
    ],
    'byAbsenceReason': [
      {'reason': 'SICKNESS', 'count': 12},
      {'reason': null, 'count': 5},
      {'reason': 'WEIRD_UNMAPPED', 'count': 2},
    ],
    'byWeekday': [
      {'weekday': 'MONDAY', 'absenceRate': 7.2, 'recordedDays': 36},
      {'weekday': 'SATURDAY', 'absenceRate': 1.1, 'recordedDays': 4},
    ],
  };

  test('fromJson decode toute la structure imbriquee', () {
    final model = AttendanceOverviewResponseModel.fromJson(buildJson());

    expect(model.context.schoolYear, '2025-2026');
    expect(model.context.period, 'year');
    expect(model.context.periodStart, DateTime(2025, 9, 1));
    expect(model.context.periodEnd, DateTime(2026, 6, 30));
    expect(
      model.context.generatedAt,
      DateTime.parse('2026-02-05T08:30:00.000Z'),
    );

    expect(model.kpis.presenceRate, 90.0);
    expect(model.kpis.justifiedAbsenceRate, 6.5);
    expect(model.kpis.unjustifiedAbsenceRate, 3.5);
    expect(model.kpis.recordedDays, 180);
    expect(model.kpis.presentDays, 162);
    expect(model.kpis.justifiedAbsenceDays, 12);
    expect(model.kpis.unjustifiedAbsenceDays, 6);

    expect(model.evolution.granularity, 'month');
    expect(model.evolution.currentBucketIndex, 1);
    expect(model.evolution.buckets, hasLength(2));
    expect(model.evolution.buckets[0].key, '2025-09');
    expect(model.evolution.buckets[0].presenceRate, 92.0);
    expect(model.evolution.buckets[0].recordedDays, 20);
    expect(model.evolution.buckets[0].isCurrent, isFalse);
    expect(model.evolution.buckets[1].key, '2025-10');
    expect(model.evolution.buckets[1].isCurrent, isTrue);

    expect(model.byClass, hasLength(1));
    expect(model.byClass.first.classroomId, 'cls-1');
    expect(model.byClass.first.className, 'CP-A');
    expect(model.byClass.first.cycle, 'PRIMARY');
    expect(model.byClass.first.level, 'CP');
    expect(model.byClass.first.presenceRate, 91.0);
    expect(model.byClass.first.justifiedAbsenceRate, 5.0);
    expect(model.byClass.first.unjustifiedAbsenceRate, 4.0);
    expect(model.byClass.first.recordedDays, 180);

    expect(model.topAbsentClasses, hasLength(1));
    expect(model.topAbsentClasses.first.classroomId, 'cls-9');
    expect(model.topAbsentClasses.first.absenceRate, 18.5);
    expect(model.topAbsentClasses.first.absenceDays, 33);

    expect(model.byAbsenceReason, hasLength(3));
    expect(model.byAbsenceReason[0].reason, 'SICKNESS');
    expect(model.byAbsenceReason[0].absenceDays, 12);
    expect(model.byAbsenceReason[1].reason, isNull);
    expect(model.byAbsenceReason[1].absenceDays, 5);
    expect(model.byAbsenceReason[2].reason, 'WEIRD_UNMAPPED');
    expect(model.byAbsenceReason[2].absenceDays, 2);

    expect(model.byWeekday, hasLength(2));
    expect(model.byWeekday[0].weekday, 'MONDAY');
    expect(model.byWeekday[0].absenceRate, 7.2);
    expect(model.byWeekday[0].recordedDays, 36);
    expect(model.byWeekday[1].weekday, 'SATURDAY');
    expect(model.byWeekday[1].absenceRate, 1.1);
    expect(model.byWeekday[1].recordedDays, 4);
  });

  test('toEntity mappe entierement (dont enums, dates et generatedAt)', () {
    final entity = AttendanceOverviewResponseModel.fromJson(
      buildJson(),
    ).toEntity();

    // Contexte
    expect(entity.context.schoolYear, '2025-2026');
    expect(entity.context.period, 'year');
    expect(entity.context.periodStart, DateTime(2025, 9, 1));
    expect(entity.context.periodEnd, DateTime(2026, 6, 30));
    expect(
      entity.context.generatedAt,
      DateTime.parse('2026-02-05T08:30:00.000Z'),
    );

    // KPIs
    expect(entity.kpis.presenceRate, 90.0);
    expect(entity.kpis.justifiedAbsenceRate, 6.5);
    expect(entity.kpis.unjustifiedAbsenceRate, 3.5);
    expect(entity.kpis.recordedDays, 180);
    expect(entity.kpis.presentDays, 162);
    expect(entity.kpis.justifiedAbsenceDays, 12);
    expect(entity.kpis.unjustifiedAbsenceDays, 6);

    // Evolution
    expect(entity.evolution.granularity, AttendanceEvolutionGranularity.month);
    expect(entity.evolution.currentBucketIndex, 1);
    expect(entity.evolution.buckets, hasLength(2));
    expect(entity.evolution.buckets[0].key, '2025-09');
    expect(entity.evolution.buckets[0].presenceRate, 92.0);
    expect(entity.evolution.buckets[0].recordedDays, 20);
    expect(entity.evolution.buckets[0].isCurrent, isFalse);
    expect(entity.evolution.buckets[1].isCurrent, isTrue);

    // byClass
    expect(entity.byClass, hasLength(1));
    expect(entity.byClass.first.cycle, 'PRIMARY');
    expect(entity.byClass.first.level, 'CP');
    expect(entity.byClass.first.classroomId, 'cls-1');
    expect(entity.byClass.first.className, 'CP-A');
    expect(entity.byClass.first.presenceRate, 91.0);
    expect(entity.byClass.first.justifiedAbsenceRate, 5.0);
    expect(entity.byClass.first.unjustifiedAbsenceRate, 4.0);
    expect(entity.byClass.first.recordedDays, 180);

    // topAbsentClasses
    expect(entity.topAbsentClasses, hasLength(1));
    expect(entity.topAbsentClasses.first.classroomId, 'cls-9');
    expect(entity.topAbsentClasses.first.className, 'CM2-B');
    expect(entity.topAbsentClasses.first.level, 'CM2');
    expect(entity.topAbsentClasses.first.absenceRate, 18.5);
    expect(entity.topAbsentClasses.first.absenceDays, 33);

    // byAbsenceReason : SICKNESS / null / valeur inconnue -> unknown
    expect(entity.byAbsenceReason, hasLength(3));
    expect(entity.byAbsenceReason[0].reason, AbsenceReason.sickness);
    expect(entity.byAbsenceReason[0].absenceDays, 12);
    expect(entity.byAbsenceReason[1].reason, isNull);
    expect(entity.byAbsenceReason[1].absenceDays, 5);
    expect(entity.byAbsenceReason[2].reason, AbsenceReason.unknown);
    expect(entity.byAbsenceReason[2].absenceDays, 2);

    // byWeekday : MONDAY -> monday, SATURDAY (hors lundi-vendredi) -> unknown
    expect(entity.byWeekday, hasLength(2));
    expect(entity.byWeekday[0].weekday, AttendanceWeekday.monday);
    expect(entity.byWeekday[0].absenceRate, 7.2);
    expect(entity.byWeekday[0].recordedDays, 36);
    expect(entity.byWeekday[1].weekday, AttendanceWeekday.unknown);
    expect(entity.byWeekday[1].absenceRate, 1.1);
    expect(entity.byWeekday[1].recordedDays, 4);
  });

  test('granularite week -> week', () {
    final entity = AttendanceOverviewResponseModel.fromJson({
      ...buildJson(),
      'evolution': {
        'granularity': 'week',
        'currentBucketIndex': 0,
        'buckets': const <dynamic>[],
      },
    }).toEntity();

    expect(entity.evolution.granularity, AttendanceEvolutionGranularity.week);
  });

  test('granularite day -> day', () {
    final entity = AttendanceOverviewResponseModel.fromJson({
      ...buildJson(),
      'evolution': {
        'granularity': 'day',
        'currentBucketIndex': 0,
        'buckets': const <dynamic>[],
      },
    }).toEntity();

    expect(entity.evolution.granularity, AttendanceEvolutionGranularity.day);
  });

  test('granularite inconnue -> month (fallback)', () {
    final entity = AttendanceOverviewResponseModel.fromJson({
      ...buildJson(),
      'evolution': {
        'granularity': 'bogus',
        'currentBucketIndex': 0,
        'buckets': const <dynamic>[],
      },
    }).toEntity();

    expect(entity.evolution.granularity, AttendanceEvolutionGranularity.month);
  });

  test('taux entier (num) est converti en double', () {
    final entity = AttendanceOverviewResponseModel.fromJson(
      buildJson(),
    ).toEntity();

    // presenceRate fourni en entier (90) cote backend.
    expect(entity.kpis.presenceRate, 90.0);
  });

  test(
    'listes byClass/topAbsentClasses/byAbsenceReason/byWeekday absentes -> vides',
    () {
      final json = buildJson()
        ..remove('byClass')
        ..remove('topAbsentClasses')
        ..remove('byAbsenceReason')
        ..remove('byWeekday');

      final entity = AttendanceOverviewResponseModel.fromJson(json).toEntity();

      expect(entity.byClass, isEmpty);
      expect(entity.topAbsentClasses, isEmpty);
      expect(entity.byAbsenceReason, isEmpty);
      expect(entity.byWeekday, isEmpty);
    },
  );

  test('evolution sans buckets -> buckets vides', () {
    final json = Map<String, dynamic>.from(buildJson());
    json['evolution'] = {'granularity': 'month', 'currentBucketIndex': 0};

    final entity = AttendanceOverviewResponseModel.fromJson(json).toEntity();

    expect(entity.evolution.buckets, isEmpty);
  });

  group(
    'byAbsenceReason mappe chaque chaine backend vers le bon AbsenceReason',
    () {
      const cases = <String, AbsenceReason>{
        'SICKNESS': AbsenceReason.sickness,
        'FAMILY_EMERGENCY': AbsenceReason.familyEmergency,
        'PERSONAL': AbsenceReason.personal,
        'UNKNOWN': AbsenceReason.unknown,
        'VACATION': AbsenceReason.vacation,
        'UNDER_GRADUATE_LEAVE': AbsenceReason.underGraduateLeave,
        'MARRIAGE_LEAVE': AbsenceReason.marriageLeave,
        'PARENTAL_LEAVE': AbsenceReason.parentalLeave,
        'WORK_LEAVE': AbsenceReason.workLeave,
        'UNJUSTIFIED': AbsenceReason.unjustified,
        'OTHER': AbsenceReason.other,
      };

      cases.forEach((backendValue, expected) {
        test('$backendValue -> $expected', () {
          final json = Map<String, dynamic>.from(buildJson());
          json['byAbsenceReason'] = [
            {'reason': backendValue, 'count': 3},
          ];

          final entity = AttendanceOverviewResponseModel.fromJson(
            json,
          ).toEntity();

          expect(entity.byAbsenceReason.single.reason, expected);
        });
      });

      test('sickness en minuscules -> sickness (insensible a la casse)', () {
        final json = Map<String, dynamic>.from(buildJson());
        json['byAbsenceReason'] = [
          {'reason': 'sickness', 'count': 3},
        ];

        final entity = AttendanceOverviewResponseModel.fromJson(
          json,
        ).toEntity();

        expect(entity.byAbsenceReason.single.reason, AbsenceReason.sickness);
      });

      test(
        'UNKNOWN explicite -> unknown (distinct du repli valeur non mappee)',
        () {
          final json = Map<String, dynamic>.from(buildJson());
          json['byAbsenceReason'] = [
            {'reason': 'UNKNOWN', 'count': 3},
          ];

          final entity = AttendanceOverviewResponseModel.fromJson(
            json,
          ).toEntity();

          expect(entity.byAbsenceReason.single.reason, AbsenceReason.unknown);
        },
      );
    },
  );

  group(
    'byWeekday mappe chaque chaine backend vers le bon AttendanceWeekday',
    () {
      const cases = <String, AttendanceWeekday>{
        'MONDAY': AttendanceWeekday.monday,
        'TUESDAY': AttendanceWeekday.tuesday,
        'WEDNESDAY': AttendanceWeekday.wednesday,
        'THURSDAY': AttendanceWeekday.thursday,
        'FRIDAY': AttendanceWeekday.friday,
      };

      cases.forEach((backendValue, expected) {
        test('$backendValue -> $expected', () {
          final json = Map<String, dynamic>.from(buildJson());
          json['byWeekday'] = [
            {'weekday': backendValue, 'absenceRate': 2.0, 'recordedDays': 10},
          ];

          final entity = AttendanceOverviewResponseModel.fromJson(
            json,
          ).toEntity();

          expect(entity.byWeekday.single.weekday, expected);
        });
      });

      test('monday en minuscules -> monday (insensible a la casse)', () {
        final json = Map<String, dynamic>.from(buildJson());
        json['byWeekday'] = [
          {'weekday': 'monday', 'absenceRate': 2.0, 'recordedDays': 10},
        ];

        final entity = AttendanceOverviewResponseModel.fromJson(
          json,
        ).toEntity();

        expect(entity.byWeekday.single.weekday, AttendanceWeekday.monday);
      });
    },
  );

  group('AttendanceWeekday.toApiValue couvre tous les membres', () {
    const cases = <AttendanceWeekday, String>{
      AttendanceWeekday.monday: 'MONDAY',
      AttendanceWeekday.tuesday: 'TUESDAY',
      AttendanceWeekday.wednesday: 'WEDNESDAY',
      AttendanceWeekday.thursday: 'THURSDAY',
      AttendanceWeekday.friday: 'FRIDAY',
      AttendanceWeekday.unknown: 'UNKNOWN',
    };

    cases.forEach((weekday, expected) {
      test('$weekday -> $expected', () {
        expect(weekday.toApiValue(), expected);
      });
    });
  });

  test('round-trip toJson -> fromJson conserve l entite (via toEntity)', () {
    final model = AttendanceOverviewResponseModel.fromJson(buildJson());

    final roundTripped = AttendanceOverviewResponseModel.fromJson(
      model.toJson(),
    );

    // Les modeles ne sont pas Equatable : on compare les entites.
    expect(roundTripped.toEntity(), model.toEntity());
  });

  test(
    'toJson reserialise fidelement les champs bruts lossy (reason/weekday)',
    () {
      final json = AttendanceOverviewResponseModel.fromJson(
        buildJson(),
      ).toJson();

      final byWeekday = json['byWeekday'] as List<dynamic>;
      final byAbsenceReason = json['byAbsenceReason'] as List<dynamic>;

      expect((byWeekday[1] as Map<String, dynamic>)['weekday'], 'SATURDAY');
      expect(
        (byAbsenceReason[2] as Map<String, dynamic>)['reason'],
        'WEIRD_UNMAPPED',
      );
      expect((byAbsenceReason[1] as Map<String, dynamic>)['reason'], isNull);
    },
  );
}
