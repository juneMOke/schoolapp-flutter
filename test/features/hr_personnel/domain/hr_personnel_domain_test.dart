import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_seniority.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_stats.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_seniority.dart';

import '../hr_personnel_builders.dart';

void main() {
  group('HrStaffStats', () {
    test('compte l\'effectif, la parité et les enseignants', () {
      final stats = HrStaffStats.of(
        viewOf([
          agent('a', sex: StaffSex.female),
          agent('b', sex: StaffSex.male),
          agent('c', sex: null, category: StaffCategory.administrative),
          agent('d', sex: StaffSex.female, category: StaffCategory.support),
        ]),
        today: '2026-10-24',
      );

      expect(stats.headcount, 4);
      expect(stats.sexes, const HrSexSplit(women: 2, men: 1, unknown: 1));
      expect(stats.sexes.total, stats.headcount);
      expect(stats.teachers, 2);
      expect(stats.teacherPercent, 50);
    });

    test('les barres somment à l\'effectif, catégorie inconnue comprise', () {
      final stats = HrStaffStats.of(
        viewOf([
          agent('a', category: StaffCategory.support),
          agent('b', category: null),
          agent('c', category: StaffCategory.teacher),
        ]),
        today: '2026-10-24',
      );

      expect(stats.categories.map((c) => c.key), [
        HrCategoryKey.teacher,
        HrCategoryKey.support,
        HrCategoryKey.unknown,
      ]);
      expect(
        stats.categories.fold<int>(0, (sum, c) => sum + c.count),
        stats.headcount,
      );
    });

    test('la parité par catégorie garde les sexes non renseignés', () {
      final stats = HrStaffStats.of(
        viewOf([agent('a', sex: StaffSex.female), agent('b', sex: null)]),
        today: '2026-10-24',
      );

      expect(
        stats.categories.single.split,
        const HrSexSplit(women: 1, unknown: 1),
      );
    });

    test('l\'ancienneté moyenne exclut les dates d\'entrée absentes', () {
      final stats = HrStaffStats.of(
        viewOf([
          agent('a', entryDate: '2016-09-01'), // 10 ans
          agent('b', entryDate: '2023-09-15'), // 3 ans
          agent('c', entryDate: null),
        ]),
        today: '2026-10-24',
      );

      expect(stats.seniorityBase, 2);
      expect(stats.averageSeniority, 6.5);
    });

    test('l\'ancienneté moyenne s\'arrondit au dixième', () {
      final stats = HrStaffStats.of(
        viewOf([
          agent('a', entryDate: '2025-09-01'), // 1
          agent('b', entryDate: '2025-09-01'), // 1
          agent('c', entryDate: '2024-09-01'), // 2
        ]),
        today: '2026-10-24',
      );

      expect(stats.averageSeniority, 1.3);
    });

    test('sans aucune date d\'entrée, ni moyenne ni doyen', () {
      final stats = HrStaffStats.of(
        viewOf([agent('a', entryDate: null)]),
        today: '2026-10-24',
      );

      expect(stats.averageSeniority, isNull);
      expect(stats.dean, isNull);
    });

    test('le doyen est le premier entré ; à égalité, l\'alphabet', () {
      final stats = HrStaffStats.of(
        viewOf([
          agent('z', lastName: 'Tshibangu', entryDate: '2010-09-01'),
          agent('y', lastName: 'Élongo', entryDate: '2010-09-01'),
          agent('x', lastName: 'Amisi', entryDate: '2015-09-01'),
        ]),
        today: '2026-10-24',
      );

      expect(stats.dean?.member.id, 'y');
      expect(stats.dean?.years, 16);
    });

    test('compte les modifications en attente, fiches et pièces', () {
      final stats = HrStaffStats.of(
        viewOf(
          [agent('a', syncState: RecordSyncState.pending), agent('b')],
          documents: {
            'b': [document('b', 'ID', syncState: RecordSyncState.failed)],
          },
        ),
        today: '2026-10-24',
      );

      expect(stats.pending, 2);
    });

    test('un fichier vide rend des zéros', () {
      final stats = HrStaffStats.of(viewOf(const []), today: '2026-10-24');

      expect(stats.headcount, 0);
      expect(stats.teacherPercent, 0);
      expect(stats.categories, isEmpty);
    });
  });

  group('Entrée à venir ou illisible', () {
    test('à venir : 0 an, comptée dans la moyenne', () {
      final stats = HrStaffStats.of(
        viewOf([
          agent('a', entryDate: '2016-09-01'), // 10
          agent('b', entryDate: '2026-11-01'), // à venir : 0
        ]),
        today: '2026-10-24',
      );
      expect(stats.seniorityBase, 2);
      expect(stats.averageSeniority, 5.0);
      expect(HrSeniority.yearsAt('2026-11-01', '2026-10-24'), 0);
    });

    test('illisible : hors moyenne, et en fin de liste', () {
      final view = viewOf([
        agent('a', lastName: 'Amisi', entryDate: '01/09/2016'),
        agent('b', lastName: 'Bola', entryDate: '2020-09-01'),
      ]);
      expect(HrStaffStats.of(view, today: '2026-10-24').seniorityBase, 1);
      expect(
        [
          for (final row in const HrRosterQuery(
            sort: HrRosterSort.oldest,
          ).apply(view.all))
            row.member.id,
        ],
        ['b', 'a'],
      );
    });
  });

  group('Ancienneté (critère d\'acceptation)', () {
    test('entré le 25/10/2020 : 5 ans le 24/10/2026, 6 ans le lendemain', () {
      expect(StaffSeniority.yearsAt('2020-10-25', '2026-10-24'), 5);
      expect(StaffSeniority.yearsAt('2020-10-25', '2026-10-25'), 6);
    });
  });

  group('HrRosterQuery', () {
    final rows = viewOf([
      agent('b', lastName: 'Mayala', entryDate: '2018-09-01'),
      agent(
        'a',
        lastName: 'Élongo',
        firstName: 'Béatrice',
        category: StaffCategory.administrative,
        entryDate: null,
      ),
      agent('c', lastName: 'Kalala', entryDate: '2023-09-15'),
      agent('d', lastName: 'Amisi', category: null, entryDate: '2010-01-04'),
    ]).all;

    List<String> ids(HrRosterQuery query) => [
      for (final row in query.apply(rows)) row.member.id,
    ];

    test('tri par nom, sans égard aux accents', () {
      expect(ids(HrRosterQuery.none), ['d', 'a', 'c', 'b']);
      expect(ids(const HrRosterQuery(sort: HrRosterSort.nameDescending)), [
        'b',
        'c',
        'a',
        'd',
      ]);
    });

    test('tri par ancienneté : la date absente va en fin de liste', () {
      expect(ids(const HrRosterQuery(sort: HrRosterSort.oldest)), [
        'd',
        'b',
        'c',
        'a',
      ]);
      expect(ids(const HrRosterQuery(sort: HrRosterSort.newest)), [
        'c',
        'b',
        'd',
        'a',
      ]);
    });

    test('« beatrice » trouve « Béatrice »', () {
      expect(ids(HrRosterQuery.none.withText('beatrice')), ['a']);
    });

    test('la catégorie filtre, y compris « non renseignée »', () {
      expect(
        ids(HrRosterQuery.none.withCategory(HrCategoryKey.administrative)),
        ['a'],
      );
      expect(ids(HrRosterQuery.none.withCategory(HrCategoryKey.unknown)), [
        'd',
      ]);
    });

    test('re-taper la catégorie active la retire', () {
      final query = HrRosterQuery.none.toggleCategory(HrCategoryKey.teacher);
      expect(query.category, HrCategoryKey.teacher);
      expect(query.toggleCategory(HrCategoryKey.teacher).category, isNull);
    });

    test('vider garde l\'ordre choisi', () {
      const query = HrRosterQuery(
        text: 'x',
        category: HrCategoryKey.support,
        sort: HrRosterSort.oldest,
      );
      expect(query.cleared(), const HrRosterQuery(sort: HrRosterSort.oldest));
      expect(query.cleared().isFiltering, isFalse);
    });
  });
}
