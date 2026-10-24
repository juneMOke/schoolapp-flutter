import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_seniority.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_member_row.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_stats.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_seniority.dart';

import '../hr_personnel_builders.dart';

void main() {
  group('HrStaffStats (servis par le serveur)', () {
    const stats = HrStaffStats(
      asOf: '2026-10-24',
      headcount: 7,
      sexes: HrSexSplit(women: 3, men: 3, unknown: 1),
      averageSeniority: 7.4,
      seniorityBase: 6,
      dean: HrDean(
        staffMemberId: 'd',
        lastName: 'MBUYI',
        middleName: 'KABEYA',
        firstName: 'Béatrice',
        entryDate: '1998-09-01',
        years: 28,
      ),
      categories: [
        HrCategoryCount(
          key: HrCategoryKey.teacher,
          split: HrSexSplit(women: 2, men: 2, unknown: 1),
        ),
        HrCategoryCount(
          key: HrCategoryKey.support,
          split: HrSexSplit(women: 1, men: 1),
        ),
      ],
    );

    test('les enseignants et leur part se déduisent des catégories', () {
      expect(stats.teachers, 5);
      expect(stats.teacherPercent, 71);
      expect(stats.countOf(HrCategoryKey.administrative), 0);
    });

    test('le doyen se nomme prénom puis nom', () {
      expect(stats.dean!.displayName, 'Béatrice MBUYI');
    });

    test('un fichier vide : 0 % d\'enseignants, pas de division par zéro', () {
      const empty = HrStaffStats(
        asOf: '2026-10-24',
        headcount: 0,
        sexes: HrSexSplit(),
        averageSeniority: null,
        seniorityBase: 0,
        dean: null,
        categories: [],
      );
      expect(empty.teacherPercent, 0);
    });
  });

  group('HrStaffMembersPage', () {
    HrStaffMembersPage pageOf(int total, {int size = 20}) => HrStaffMembersPage(
      totalElements: total,
      page: 0,
      size: size,
      items: const [],
    );

    test('les pages se déduisent du total', () {
      expect(pageOf(0).totalPages, 0);
      expect(pageOf(20).totalPages, 1);
      expect(pageOf(21).totalPages, 2);
      expect(pageOf(5, size: 0).totalPages, 0);
    });
  });

  group('Entrée à venir ou illisible', () {
    test('à venir : 0 an', () {
      expect(HrSeniority.yearsAt('2026-11-01', '2026-10-24'), 0);
    });

    test('illisible : en fin de liste', () {
      final view = viewOf([
        agent('a', lastName: 'Amisi', entryDate: '01/09/2016'),
        agent('b', lastName: 'Bola', entryDate: '2020-09-01'),
      ]);
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
