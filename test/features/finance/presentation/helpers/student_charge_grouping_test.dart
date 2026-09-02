import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_grouping.dart';

/// Le repli des créances sous leur nature (GF-1).
///
/// Trois propriétés money-grade, et chacune a un contre-exemple qui coûte cher :
///  - **aucune créance perdue** — une tranche qui disparaît de l'écran est une
///    tranche que personne ne réclame ;
///  - **aucune somme inter-devises** — 425,00 $ + 90 000 FC n'existe pas ;
///  - **le statut vient du COMPOSÉ** — le miroir serveur dirait « à régler » sur
///    un frais que le guichet vient de solder hors ligne, et le caissier
///    réencaisserait.
void main() {
  StudentCharge charge({
    required String id,
    String feeCode = 'TUITION',
    String? tariffCode,
    double expected = 50000,
    double paid = 0,
    double pending = 0,
    String currency = 'CDF',
    StudentChargeStatus status = StudentChargeStatus.due,
    String? dueAt,
  }) => StudentCharge(
    id: id,
    studentId: 's-1',
    academicYearId: 'y-1',
    schoolLevelId: 'lvl-1',
    schoolLevelGroupId: 'grp-1',
    feeTariffId: 't-$id',
    feeTariffCode: tariffCode,
    feeCode: feeCode,
    label: 'Minerval',
    expectedAmountInCents: expected,
    amountPaidInCents: paid,
    amountPaidPendingInCents: pending,
    currency: currency,
    status: status,
    dueAt: dueAt,
  );

  group('groupChargesByFeeCode', () {
    test('replie par nature sans perdre une seule créance', () {
      final charges = [
        charge(id: '1'),
        charge(id: '2'),
        charge(id: '3', feeCode: 'CANTEEN'),
      ];

      final groups = groupChargesByFeeCode(charges);

      expect(groups.map((g) => g.feeCode), ['TUITION', 'CANTEEN']);
      expect(
        groups.expand((g) => g.charges).map((c) => c.id).toList(),
        ['1', '2', '3'],
        reason:
            'Une tranche escamotée est une tranche que personne ne réclame.',
      );
    });

    test('garde l\'ordre du DAO : première apparition, puis échéances', () {
      // L'ordre servi : `fee_code ASC`, puis `due_at ASC`. On ne re-trie pas —
      // c'est l'ordre dans lequel une famille paie.
      final groups = groupChargesByFeeCode([
        charge(id: 'c1', feeCode: 'CANTEEN', dueAt: '2026-10-01'),
        charge(id: 't1', dueAt: '2026-09-01'),
        charge(id: 't2', dueAt: '2026-10-01'),
      ]);

      expect(groups.map((g) => g.feeCode), ['CANTEEN', 'TUITION']);
      expect(groups.last.charges.map((c) => c.id), ['t1', 't2']);
    });

    test('regroupe par CLÉ, pas par adjacence', () {
      // Le chemin online pur pourrait servir un autre ordre : le repli doit
      // rester juste, sinon la même nature ferait deux en-têtes.
      final groups = groupChargesByFeeCode([
        charge(id: '1'),
        charge(id: '2', feeCode: 'CANTEEN'),
        charge(id: '3'),
      ]);

      expect(groups, hasLength(2));
      expect(groups.first.charges.map((c) => c.id), ['1', '3']);
    });

    test('une casse discordante ne fait pas deux groupes', () {
      final groups = groupChargesByFeeCode([
        charge(id: '1', feeCode: 'TUITION'),
        charge(id: '2', feeCode: 'tuition'),
      ]);

      expect(groups, hasLength(1));
      expect(groups.single.feeCode, 'TUITION');
    });

    test('une liste vide rend une liste vide', () {
      expect(groupChargesByFeeCode(const []), isEmpty);
    });
  });

  group('les totaux du groupe', () {
    test('somment PAR DEVISE, jamais entre elles', () {
      final group = groupChargesByFeeCode([
        charge(id: '1', expected: 50000, paid: 20000),
        charge(id: '2', expected: 50000, paid: 0),
        charge(id: '3', expected: 42500, paid: 42500, currency: 'USD'),
      ]).single;

      expect(group.expected.entries, [
        const Money(100000, 'CDF'),
        const Money(42500, 'USD'),
      ]);
      expect(group.paidTotal.entries, [
        const Money(20000, 'CDF'),
        const Money(42500, 'USD'),
      ]);
      expect(group.remaining.entries, [
        const Money(80000, 'CDF'),
        const Money(0, 'USD'),
      ]);
    });

    test('le payé est COMPOSÉ : miroir serveur + versement pas remonté', () {
      final group = groupChargesByFeeCode([
        charge(id: '1', expected: 50000, paid: 10000, pending: 15000),
      ]).single;

      expect(group.paidTotal.entries.single, const Money(25000, 'CDF'));
      expect(group.remaining.entries.single, const Money(25000, 'CDF'));
      expect(group.hasPendingPayment, isTrue);
    });

    test('le reste ne descend jamais sous zéro', () {
      final group = groupChargesByFeeCode([
        charge(id: '1', expected: 50000, paid: 80000),
      ]).single;

      expect(group.remaining.entries.single, const Money(0, 'CDF'));
    });
  });

  group('le statut du groupe', () {
    test('rien payé nulle part → à régler', () {
      final group = groupChargesByFeeCode([
        charge(id: '1'),
        charge(id: '2'),
      ]).single;

      expect(group.status, StudentChargeStatus.due);
    });

    test('tout soldé → soldé', () {
      final group = groupChargesByFeeCode([
        charge(id: '1', expected: 50000, paid: 50000),
        charge(id: '2', expected: 50000, paid: 50000),
      ]).single;

      expect(group.status, StudentChargeStatus.paid);
    });

    test('une tranche payée, une autre non → partiel', () {
      final group = groupChargesByFeeCode([
        charge(id: '1', expected: 50000, paid: 50000),
        charge(id: '2', expected: 50000, paid: 0),
      ]).single;

      expect(group.status, StudentChargeStatus.partial);
    });

    test(
      'un versement pas encore remonté SOLDE le groupe, malgré le miroir',
      () {
        // LE test de ce lot. Le miroir serveur dit encore DUE — rien ne le
        // recalcule après un encaissement local. S'en remettre à lui ferait
        // afficher « à régler » sur un frais que le guichet vient d'encaisser,
        // et le caissier réencaisserait.
        final group = groupChargesByFeeCode([
          charge(
            id: '1',
            expected: 50000,
            paid: 0,
            pending: 50000,
            status: StudentChargeStatus.due,
          ),
        ]).single;

        expect(group.status, StudentChargeStatus.paid);
      },
    );

    test('le statut ne somme pas deux devises', () {
      // Soldé en dollars, rien payé en francs : le groupe est PARTIEL. Une
      // dérivation par sommes aurait comparé des chiffres sans unité commune.
      final group = groupChargesByFeeCode([
        charge(id: '1', expected: 42500, paid: 42500, currency: 'USD'),
        charge(id: '2', expected: 50000, paid: 0),
      ]).single;

      expect(group.status, StudentChargeStatus.partial);
    });
  });

  group('la progression par devise', () {
    test('une entrée par devise, dans l\'ordre des montants affichés', () {
      final group = groupChargesByFeeCode([
        charge(id: '1', expected: 100000, paid: 25000),
        charge(id: '2', expected: 40000, paid: 40000, currency: 'USD'),
      ]).single;

      final progress = group.progressByCurrency;

      expect(progress.map((p) => p.expected.currency), ['CDF', 'USD']);
      expect(progress.first.ratio, closeTo(0.25, 0.0001));
      expect(progress.last.ratio, 1);
    });

    test(
      'rien d\'attendu mais quelque chose de payé vaut une barre pleine',
      () {
        // Une barre vide sous un montant encaissé se lit comme un encaissement
        // perdu. Même règle que la ligne de tranche.
        final group = groupChargesByFeeCode([
          charge(id: '1', expected: 0, paid: 30000),
        ]).single;

        expect(group.progressByCurrency.single.ratio, 1);
      },
    );

    test('rien d\'attendu ni payé vaut une barre vide', () {
      final group = groupChargesByFeeCode([
        charge(id: '1', expected: 0, paid: 0),
      ]).single;

      expect(group.progressByCurrency.single.ratio, 0);
    });

    test('un sur-paiement plafonne à 1', () {
      final group = groupChargesByFeeCode([
        charge(id: '1', expected: 50000, paid: 80000),
      ]).single;

      expect(group.progressByCurrency.single.ratio, 1);
    });
  });

  group('le compte de tranches', () {
    test('est celui de l\'ÉLÈVE, pas celui de la grille', () {
      // Trois tranches portées sur un minerval qui en compte sept dans la
      // grille : la fiche décrit CET élève.
      final group = groupChargesByFeeCode([
        charge(id: '1', tariffCode: 'T1'),
        charge(id: '2', tariffCode: 'T2'),
        charge(id: '3', tariffCode: 'T3'),
      ]).single;

      expect(group.trancheCount, 3);
      expect(group.isSingleTranche, isFalse);
    });

    test('une nature d\'une seule tranche se reconnaît', () {
      final group = groupChargesByFeeCode([charge(id: '1')]).single;

      expect(group.isSingleTranche, isTrue);
    });
  });
}
