import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_dashboard_projector.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_level_aggregate.dart';

/// Un élève d'un niveau, dans une devise, avec son attendu et son payé.
LocalFeeLevelAggregate at(
  String studentId, {
  required String? level,
  int expected = 100000,
  int paidMirror = 0,
  int paidPending = 0,
  String currency = 'USD',
}) => LocalFeeLevelAggregate(
  schoolLevelId: level,
  charge: LocalFeeChargeAggregate.single(
    studentId: studentId,
    currency: currency,
    expectedInCents: expected,
    paidMirrorInCents: paidMirror,
    paidPendingInCents: paidPending,
  ),
);

/// [count] élèves d'un niveau, dont [settled] ont soldé — de quoi fabriquer un
/// taux exact sans aligner vingt littéraux.
List<LocalFeeLevelAggregate> level(
  String id, {
  required int count,
  required int settled,
}) => [
  for (var i = 0; i < count; i++)
    at('$id-$i', level: id, paidMirror: i < settled ? 100000 : 0),
];

void main() {
  group('répartition', () {
    test(
      'compte les trois statuts par niveau, sans jamais les recalculer',
      () async {
        final summary = FeeControlDashboardProjector.project([
          at('s1', level: 'lvl-1', paidMirror: 100000), // soldé
          at('s2', level: 'lvl-1', paidMirror: 40000), // partiel
          at('s3', level: 'lvl-1'), // rien versé
          at('s4', level: 'lvl-2', paidMirror: 100000),
        ]);

        final one = summary.groups.firstWhere(
          (g) => g.schoolLevelId == 'lvl-1',
        );
        expect(one.breakdown.settled, 1);
        expect(one.breakdown.partial, 1);
        expect(one.breakdown.none, 1);
        expect(summary.total.total, 4);
      },
    );

    test('un encaissement hors ligne compte comme un paiement', () {
      final summary = FeeControlDashboardProjector.project([
        at('s1', level: 'lvl-1', paidPending: 100000),
      ]);

      expect(summary.total.settled, 1);
    });

    test('population vide → résumé vide, pas de division par zéro', () {
      final summary = FeeControlDashboardProjector.project([]);

      expect(summary, FeeControlDashboardSummary.empty);
      expect(summary.settledPercent, 0);
      expect(summary.isEmpty, isTrue);
    });
  });

  group('invariant : le total est la somme des groupes', () {
    test('sur une population ordinaire', () {
      final summary = FeeControlDashboardProjector.project([
        ...level('lvl-1', count: 10, settled: 4),
        ...level('lvl-2', count: 7, settled: 7),
        ...level('lvl-3', count: 3, settled: 0),
      ]);

      expect(
        summary.groups.fold(0, (sum, g) => sum + g.breakdown.settled),
        summary.total.settled,
      );
      expect(
        summary.groups.fold(0, (sum, g) => sum + g.breakdown.total),
        summary.total.total,
      );
      expect(summary.total.total, 20);
    });

    test('un élève à cheval sur deux niveaux compte dans les deux (D5)', () {
      final summary = FeeControlDashboardProjector.project([
        at('s1', level: 'lvl-1', paidMirror: 100000),
        at('s1', level: 'lvl-2'),
      ]);

      expect(summary.total.total, 2);
      expect(summary.total.settled, 1);
      expect(summary.total.none, 1);
      expect(summary.groups.length, 2);
    });

    test('les créances sans niveau forment un groupe qui SE VOIT', () {
      final summary = FeeControlDashboardProjector.project([
        at('s1', level: null),
        ...level('lvl-1', count: 2, settled: 2),
      ]);

      expect(summary.groups.map((g) => g.schoolLevelId), contains(null));
      expect(summary.total.total, 3);
    });
  });

  group('le taux affiché', () {
    test(
      'n\'annonce 100 % que si PERSONNE ne reste — 249/250 reste à 99 %',
      () {
        final summary = FeeControlDashboardProjector.project(
          level('lvl-1', count: 250, settled: 249),
        );

        expect(summary.settledPercent, 99);
      },
    );

    test('n\'annonce 0 % que si PERSONNE n\'a soldé — 1/400 monte à 1 %', () {
      final summary = FeeControlDashboardProjector.project(
        level('lvl-1', count: 400, settled: 1),
      );

      expect(summary.settledPercent, 1);
    });

    test('les deux bornes exactes, elles, s\'affichent bien', () {
      expect(
        FeeControlDashboardProjector.project(
          level('lvl-1', count: 5, settled: 5),
        ).settledPercent,
        100,
      );
      expect(
        FeeControlDashboardProjector.project(
          level('lvl-1', count: 5, settled: 0),
        ).settledPercent,
        0,
      );
    });
  });

  group('classement', () {
    test('le plus en retard remonte en tête', () {
      final summary = FeeControlDashboardProjector.project([
        ...level('lvl-bon', count: 10, settled: 9),
        ...level('lvl-mauvais', count: 10, settled: 2),
        ...level('lvl-moyen', count: 10, settled: 5),
      ]);

      expect(summary.groups.map((g) => g.schoolLevelId), [
        'lvl-mauvais',
        'lvl-moyen',
        'lvl-bon',
      ]);
    });

    test('deux taux que l\'affichage rendrait ex æquo restent départagés', () {
      // 497/500 = 99,4 % et 499/500 = 99,8 % : tous deux « 99 % » à l'écran.
      //
      // ⚠️ Les identifiants sont choisis pour que l'ordre alphabétique soit
      // l'INVERSE de l'ordre attendu. Sans cela, un tri retombé sur le
      // départage par identifiant rendrait le bon ordre par accident, et ce
      // test passerait en ne vérifiant rien — ce qu'il faisait à la première
      // écriture, jusqu'à ce que la mutation le dise.
      final summary = FeeControlDashboardProjector.project([
        ...level('lvl-a-99-8', count: 500, settled: 499),
        ...level('lvl-z-99-4', count: 500, settled: 497),
      ]);

      expect(summary.groups.map((g) => g.settledPercent), [99, 99]);
      expect(summary.groups.map((g) => g.schoolLevelId), [
        'lvl-z-99-4',
        'lvl-a-99-8',
      ]);
    });

    test('à taux égal, le groupe le plus nombreux passe devant', () {
      final summary = FeeControlDashboardProjector.project([
        ...level('lvl-petit', count: 4, settled: 2),
        ...level('lvl-grand', count: 40, settled: 20),
      ]);

      expect(summary.groups.map((g) => g.schoolLevelId), [
        'lvl-grand',
        'lvl-petit',
      ]);
    });

    test(
      'à taux ET effectif égaux, l\'ordre reste STABLE entre deux appels',
      () {
        List<String?> order() => FeeControlDashboardProjector.project([
          ...level('lvl-b', count: 5, settled: 3),
          ...level('lvl-a', count: 5, settled: 3),
        ]).groups.map((g) => g.schoolLevelId).toList();

        expect(order(), ['lvl-a', 'lvl-b']);
        expect(order(), order());
      },
    );
  });

  group('les montants', () {
    test('le reste dû s\'agrège par groupe et pour l\'ensemble', () {
      final summary = FeeControlDashboardProjector.project([
        at('s1', level: 'lvl-1', expected: 100000, paidMirror: 40000),
        at('s2', level: 'lvl-1', expected: 100000),
        at('s3', level: 'lvl-2', expected: 50000, paidMirror: 50000),
      ]);

      final one = summary.groups.firstWhere((g) => g.schoolLevelId == 'lvl-1');
      expect(one.remaining.entries.single.amountInCents, 160000);
      expect(summary.remaining.entries.single.amountInCents, 160000);
    });

    test('deux devises ne sont JAMAIS additionnées', () {
      final summary = FeeControlDashboardProjector.project([
        at('s1', level: 'lvl-1', expected: 100000, currency: 'USD'),
        at('s2', level: 'lvl-1', expected: 300000, currency: 'CDF'),
      ]);

      expect(summary.remaining.entries.length, 2);
      expect(summary.remaining.entries.map((m) => m.currency).toSet(), {
        'USD',
        'CDF',
      });
    });

    test('un élève débiteur dans une seule de ses deux devises n\'est pas en '
        'ordre', () {
      final summary = FeeControlDashboardProjector.project([
        const LocalFeeLevelAggregate(
          schoolLevelId: 'lvl-1',
          charge: LocalFeeChargeAggregate(
            studentId: 's1',
            positions: [
              FeeChargePosition(
                currency: 'USD',
                expectedInCents: 50000,
                paidMirrorInCents: 50000,
                paidPendingInCents: 0,
              ),
              FeeChargePosition(
                currency: 'CDF',
                expectedInCents: 300000,
                paidMirrorInCents: 0,
                paidPendingInCents: 0,
              ),
            ],
          ),
        ),
      ]);

      expect(summary.total.partial, 1);
      expect(summary.total.settled, 0);
    });
  });
}
