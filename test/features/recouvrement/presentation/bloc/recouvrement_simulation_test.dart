import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation_cubit.dart';

LocalRecoveryLine line(
  String studentId, {
  String? level = 'lvl-1',
  String currency = 'USD',
  int expected = 30000,
  int paid = 0,
}) => LocalRecoveryLine(
  schoolLevelId: level,
  studentId: studentId,
  charges: [
    RecoveryChargePosition(
      feeCode: 'TUITION',
      position: FeeChargePosition(
        currency: currency,
        expectedInCents: expected,
        paidMirrorInCents: paid,
        paidPendingInCents: 0,
      ),
    ),
  ],
);

RecouvrementSimulation run(
  List<LocalRecoveryLine> lines, {
  RecouvrementCriterion criterion = RecouvrementCriterion.noPayment,
  int criticalPercent = 60,
  Money? threshold,
  ExchangeRate? rate,
}) => RecouvrementSimulationProjector.project(
  lines,
  criterion: criterion,
  criticalPercent: criticalPercent,
  threshold: threshold,
  rate: rate,
);

void main() {
  group('le ciblage', () {
    final population = [
      line('rien'),
      line('partiel', paid: 12000),
      line('solde', paid: 30000),
    ];

    test('« n\'ont rien payé » ne vise que ceux qui n\'ont rien versé', () {
      expect(run(population).targeted, 1);
    });

    test('« n\'ont pas tout soldé » vise aussi les partiels', () {
      expect(
        run(population, criterion: RecouvrementCriterion.notSettled).targeted,
        2,
      );
    });

    test('sans plancher, « a payé moins que… » ne vise PERSONNE', () {
      expect(
        run(
          population,
          criterion: RecouvrementCriterion.belowThreshold,
        ).targeted,
        0,
        reason: 'un champ vide ne doit pas viser toute l\'école',
      );
    });

    test('avec plancher, vise ceux qui ont versé moins', () {
      expect(
        run(
          population,
          criterion: RecouvrementCriterion.belowThreshold,
          threshold: Money.parse(20000, 'USD'),
        ).targeted,
        2,
        reason: '0 et 12 000 sont sous 20 000 ; 30 000 non',
      );
    });
  });

  group('le plancher en sélection mixte', () {
    final mixed = [
      line('usd', currency: 'USD', expected: 30000, paid: 5000),
      line('cdf', currency: 'CDF', expected: 5000000, paid: 3000000),
    ];

    final rate = ExchangeRate(
      base: 'USD',
      quote: 'CDF',
      rateMicros: 2850 * ExchangeRate.scale,
      effectiveFrom: DateTime.utc(2026, 9, 1),
    );

    test('convertit pour comparer, avec le taux du guichet', () {
      // 3 000 000 FC ÷ 2 850 ≈ 1 052 cents de dollar, soit sous 10 000.
      final result = run(
        mixed,
        criterion: RecouvrementCriterion.belowThreshold,
        threshold: Money.parse(10000, 'USD'),
        rate: rate,
      );

      expect(result.targeted, 2);
    });

    test('sans taux, ne vise personne plutôt que d\'inventer un chiffre', () {
      final result = run(
        mixed,
        criterion: RecouvrementCriterion.belowThreshold,
        threshold: Money.parse(10000, 'USD'),
      );

      expect(
        result.targeted,
        1,
        reason: 'seul l\'élève en dollars est comparable sans cours',
      );
    });
  });

  group('l\'effectif conservé', () {
    test('le total se recalcule sur la SOMME des groupes, jamais moyenné', () {
      // Un groupe de 40 dont 4 partent (90 % conservés), un groupe de 2 dont 2
      // partent (0 %). La moyenne des pourcentages dirait 45 % ; la vérité est
      // 36 restants sur 42, soit 86 %.
      final result = run([
        for (var i = 0; i < 36; i++) line('a$i', level: 'A', paid: 30000),
        for (var i = 0; i < 4; i++) line('a-out$i', level: 'A'),
        for (var i = 0; i < 2; i++) line('b$i', level: 'B'),
      ]);

      expect(result.headcount, 42);
      expect(result.targeted, 6);
      expect(result.keptPercent, 86);
    });

    test('un groupe intact conserve 100 %', () {
      expect(run([line('s1', paid: 30000)]).rows.single.keptPercent, 100);
    });

    test('un groupe entièrement visé tombe à 0 %', () {
      expect(run([line('s1')]).rows.single.keptPercent, 0);
    });
  });

  group('le classement des groupes', () {
    test('les plus abîmés en HAUT — l\'inverse du classement voisin', () {
      final result = run([
        for (var i = 0; i < 4; i++) line('sain$i', level: 'sain', paid: 30000),
        for (var i = 0; i < 4; i++) line('casse$i', level: 'casse'),
      ]);

      expect(result.rows.map((r) => r.schoolLevelId), ['casse', 'sain']);
    });

    test('à part égale, l\'identifiant départage — l\'ordre est STABLE', () {
      final result = run([line('a', level: 'ZZZ'), line('b', level: 'AAA')]);

      expect(result.rows.map((r) => r.schoolLevelId), ['AAA', 'ZZZ']);
    });

    test('les ex æquo à la virgule ne sont pas confondus par l\'arrondi', () {
      // 54,5 % et 54,8 % arrondissent tous deux à 55 : le tri doit pourtant
      // les séparer, et dans le bon sens.
      final result = run([
        for (var i = 0; i < 11; i++) line('a$i', level: 'A', paid: 30000),
        for (var i = 0; i < 9; i++) line('a-out$i', level: 'A'),
        for (var i = 0; i < 17; i++) line('b$i', level: 'B', paid: 30000),
        for (var i = 0; i < 14; i++) line('b-out$i', level: 'B'),
      ]);

      // A garde 11/20 = 55,0 % ; B garde 17/31 = 54,8 %. B passe devant.
      expect(result.rows.first.schoolLevelId, 'B');
    });
  });

  group('les groupes ingérables', () {
    test('sous le seuil, un groupe est nommé', () {
      final result = run([
        for (var i = 0; i < 3; i++) line('a$i', level: 'A'),
        for (var i = 0; i < 3; i++) line('b$i', level: 'B', paid: 30000),
      ], criticalPercent: 60);

      expect(result.critical, ['A']);
    });

    test(
      'déplacer le seuil déplace la liste, sans relire quoi que ce soit',
      () {
        final population = [
          for (var i = 0; i < 7; i++) line('a$i', level: 'A', paid: 30000),
          for (var i = 0; i < 3; i++) line('a-out$i', level: 'A'),
        ];

        expect(run(population, criticalPercent: 60).critical, isEmpty);
        expect(run(population, criticalPercent: 90).critical, ['A']);
      },
    );
  });

  group('perdu et manquant', () {
    test('deux paires distinctes, qui ne s\'additionnent jamais', () {
      final result = run([
        line('vise', paid: 0, expected: 30000),
        line('epargne', paid: 30000, expected: 30000),
      ]);

      expect(
        result.lost.isAllZero,
        isTrue,
        reason: 'les visés n\'ont rien payé',
      );
      expect(result.missing.amountIn('USD')!.amountInCents, 30000);
    });

    test('un visé qui avait versé fait perdre CE versement', () {
      final result = run([
        line('partiel', paid: 12000, expected: 30000),
      ], criterion: RecouvrementCriterion.notSettled);

      expect(result.lost.amountIn('USD')!.amountInCents, 12000);
      expect(result.missing.amountIn('USD')!.amountInCents, 18000);
    });

    test('deux devises restent côte à côte', () {
      final result = run([
        line('usd', currency: 'USD', expected: 30000),
        line('cdf', currency: 'CDF', expected: 5000000),
      ]);

      expect(result.missing.entries, hasLength(2));
    });
  });

  group('le cubit', () {
    test('recalcule à chaque réglage, sans jamais rien lire', () {
      final cubit = RecouvrementSimulationCubit();
      addTearDown(cubit.close);

      cubit.setLines([line('rien'), line('partiel', paid: 12000)]);
      expect(cubit.state.result.targeted, 1);

      cubit.setCriterion(RecouvrementCriterion.notSettled);
      expect(cubit.state.result.targeted, 2);
    });

    test('quitter le plancher l\'OUBLIE — il ne réapparaît pas plus tard', () {
      final cubit = RecouvrementSimulationCubit();
      addTearDown(cubit.close);

      cubit.setCriterion(RecouvrementCriterion.belowThreshold);
      cubit.setThreshold(Money.parse(20000, 'USD'));
      expect(cubit.state.threshold, isNotNull);

      cubit.setCriterion(RecouvrementCriterion.noPayment);
      expect(cubit.state.threshold, isNull);
    });

    test('le seuil est borné aux crans que le curseur offre', () {
      final cubit = RecouvrementSimulationCubit();
      addTearDown(cubit.close);

      cubit.setCriticalPercent(5);
      expect(
        cubit.state.criticalPercent,
        RecouvrementSimulationState.minCriticalPercent,
      );

      cubit.setCriticalPercent(200);
      expect(
        cubit.state.criticalPercent,
        RecouvrementSimulationState.maxCriticalPercent,
      );
    });

    test('un nouveau registre CONSERVE les réglages de l\'arbitrage', () {
      final cubit = RecouvrementSimulationCubit();
      addTearDown(cubit.close);

      cubit.setCriterion(RecouvrementCriterion.notSettled);
      cubit.setCriticalPercent(75);
      cubit.setLines([line('s1')]);

      expect(cubit.state.criterion, RecouvrementCriterion.notSettled);
      expect(cubit.state.criticalPercent, 75);
    });
  });
}
