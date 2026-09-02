import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_charge_entry.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_charge_group_entry.dart';

/// L'entrée de groupe de la page d'encaissement (GE-1).
///
/// Ce qui se joue ici : **une saisie, N imputations**, sans que le contrat de
/// push bouge. Le groupe pilote des `FacturationChargeEntry` existantes — celles
/// que la page enverra au serveur — au lieu de les remplacer.
void main() {
  StudentCharge charge({
    required String id,
    String feeCode = 'TUITION',
    double expected = 50000,
    double paid = 0,
    String currency = 'CDF',
  }) => StudentCharge(
    id: id,
    studentId: 's-1',
    academicYearId: 'y-1',
    schoolLevelId: 'lvl-1',
    schoolLevelGroupId: 'grp-1',
    feeTariffId: 't-$id',
    feeCode: feeCode,
    label: 'Minerval',
    expectedAmountInCents: expected,
    amountPaidInCents: paid,
    currency: currency,
    status: StudentChargeStatus.due,
  );

  FacturationChargeGroupEntry groupOf(List<StudentCharge> charges) {
    final entries = [for (final c in charges) FacturationChargeEntry(c)];
    final group = groupPayableEntries(entries).single;
    addTearDown(() {
      group.dispose();
      for (final entry in entries) {
        entry.dispose();
      }
    });
    return group;
  }

  group('le repli', () {
    test('groupe par NATURE ET DEVISE', () {
      // La clé n'est pas celle de la fiche : un montant tapé a une seule
      // devise, donc un groupe ne peut pas en porter deux.
      final entries = [
        FacturationChargeEntry(charge(id: '1')),
        FacturationChargeEntry(charge(id: '2', currency: 'USD')),
        FacturationChargeEntry(charge(id: '3')),
      ];
      addTearDown(() {
        for (final e in entries) {
          e.dispose();
        }
      });

      final groups = groupPayableEntries(entries);
      addTearDown(() {
        for (final g in groups) {
          g.dispose();
        }
      });

      expect(groups, hasLength(2));
      expect(groups.first.currency, 'CDF');
      expect(groups.first.tranches.map((t) => t.charge.id), ['1', '3']);
      expect(groups.last.currency, 'USD');
    });

    test('ne perd aucune tranche et garde l\'ordre reçu', () {
      final group = groupOf([
        charge(id: '1'),
        charge(id: '2'),
        charge(id: '3'),
      ]);

      expect(group.tranches.map((t) => t.charge.id), ['1', '2', '3']);
      expect(group.trancheCount, 3);
    });

    test('une nature d\'une seule tranche se reconnaît', () {
      expect(groupOf([charge(id: '1')]).isSingleTranche, isTrue);
    });

    test('une liste vide rend une liste vide', () {
      expect(groupPayableEntries(const []), isEmpty);
    });
  });

  group('la ventilation en cascade', () {
    test('solde les premières tranches et coche ce qu\'elle atteint', () {
      final group = groupOf([
        charge(id: '1'),
        charge(id: '2'),
        charge(id: '3'),
      ]);

      final posted = group.applyCascade('1200');

      expect(posted, 120000);
      expect(group.tranches[0].controller.text, '500');
      expect(group.tranches[1].controller.text, '500');
      expect(group.tranches[2].controller.text, '200');
      expect(group.tranches.every((t) => t.selected), isTrue);
    });

    test('DÉCOCHE les tranches qu\'elle n\'atteint pas', () {
      // Une case cochée sans montant se lit comme un oubli de saisie, et une
      // imputation vide ne part pas au serveur.
      final group = groupOf([charge(id: '1'), charge(id: '2')]);

      group.applyCascade('300');

      expect(group.tranches[0].selected, isTrue);
      expect(group.tranches[1].selected, isFalse);
      expect(group.tranches[1].controller.text, isEmpty);
    });

    test('ce qui est ventilé vaut ce qui sera imputé', () {
      // `allocatedCents` lit les montants EFFECTIFS des tranches — donc ce que
      // la page enverra vraiment.
      final group = groupOf([charge(id: '1'), charge(id: '2')]);

      final posted = group.applyCascade('750');

      expect(posted, 75000);
      expect(group.allocatedCents, 75000);
    });

    test('plafonne au restant du groupe, sans déborder', () {
      final group = groupOf([charge(id: '1'), charge(id: '2')]);

      final posted = group.applyCascade('99999');

      expect(group.capInCents, 100000);
      expect(posted, 100000);
      expect(group.allocatedCents, 100000);
    });

    test('tient compte de ce qui est DÉJÀ payé sur une tranche', () {
      // Le restant composé, pas l'attendu : une tranche à moitié réglée
      // n'absorbe plus que sa moitié.
      final group = groupOf([
        charge(id: '1', expected: 50000, paid: 30000),
        charge(id: '2'),
      ]);

      expect(group.capInCents, 70000);
      final posted = group.applyCascade('300');

      expect(posted, 30000);
      expect(group.tranches[0].controller.text, '200');
      expect(group.tranches[1].controller.text, '100');
    });

    test('une saisie vide ou nulle ne règle rien', () {
      final group = groupOf([charge(id: '1')]);
      group.applyCascade('500');

      expect(group.applyCascade(''), 0);
      expect(group.tranches.single.selected, isFalse);
      expect(group.allocatedCents, 0);
    });

    test('une re-ventilation plus basse RETIRE ce qui avait été posé', () {
      // Le piège : sans remise à zéro des tranches non atteintes, corriger un
      // montant vers le bas laisserait des imputations fantômes.
      final group = groupOf([
        charge(id: '1'),
        charge(id: '2'),
        charge(id: '3'),
      ]);
      group.applyCascade('1500');
      expect(group.allocatedCents, 150000);

      group.applyCascade('300');

      expect(group.allocatedCents, 30000);
      expect(group.tranches[1].selected, isFalse);
      expect(group.tranches[2].selected, isFalse);
    });
  });

  group('la sélection', () {
    test('est DÉRIVÉE des tranches, jamais stockée', () {
      final group = groupOf([charge(id: '1'), charge(id: '2')]);
      expect(group.selected, isFalse);

      group.applyCascade('300');
      expect(group.selected, isTrue);

      // Décocher la seule tranche réglée à la main éteint le groupe, sans
      // qu'aucun drapeau n'ait à être tenu d'accord.
      group.tranches[0].selected = false;
      expect(group.selected, isFalse);
    });
  });

  group('la bascule de source', () {
    test('le groupe commande par défaut', () {
      expect(groupOf([charge(id: '1')]).groupIsSource, isTrue);
    });

    test('quand les tranches commandent, le groupe affiche leur somme', () {
      final group = groupOf([charge(id: '1'), charge(id: '2')]);

      // Le caissier a déplié et tapé sur la deuxième tranche seulement.
      group.groupIsSource = false;
      group.tranches[1].selected = true;
      group.tranches[1].controller.text = '420';
      group.reflectFromTranches();

      expect(group.controller.text, '420');
      expect(group.allocatedCents, 42000);
    });

    test('la somme reflétée est bornée au restant, comme l\'imputation', () {
      final group = groupOf([charge(id: '1')]);

      group.groupIsSource = false;
      group.tranches.single.selected = true;
      group.tranches.single.controller.text = '9999';
      group.reflectFromTranches();

      // 500 = le restant de la tranche, pas les 9999 tapés.
      expect(group.controller.text, '500');
    });

    test('rien de réglé : le champ du groupe reste vide, pas « 0 »', () {
      final group = groupOf([charge(id: '1')]);

      group.groupIsSource = false;
      group.reflectFromTranches();

      expect(group.controller.text, isEmpty);
    });
  });

  group('la devise de règlement (GE-4)', () {
    test(
      'est PROPAGÉE aux tranches, sans quoi elle ne partirait nulle part',
      () {
        // Ce sont les tranches qui produisent les `SettlementLine`, donc les
        // tenders envoyés. Une devise posée au groupe seul serait inerte.
        final group = groupOf([charge(id: '1'), charge(id: '2')]);

        group.setTenderCurrency('USD');

        expect(group.effectiveTenderCurrency, 'USD');
        expect(
          group.tranches.every((t) => t.effectiveTenderCurrency == 'USD'),
          isTrue,
        );
      },
    );

    test('revenir à la devise de créance efface la conversion', () {
      final group = groupOf([charge(id: '1')]);
      group.setTenderCurrency('USD');
      group.tenderController.text = '42';

      group.setTenderCurrency('CDF');

      expect(group.effectiveTenderCurrency, 'CDF');
      expect(group.tenderController.text, isEmpty);
      expect(group.tranches.single.effectiveTenderCurrency, 'CDF');
    });

    test('poser la devise de la créance ne convertit pas', () {
      final group = groupOf([charge(id: '1')]);

      group.setTenderCurrency('CDF');

      expect(group.isConverted, isFalse);
    });

    test('convertir n\'est vrai QUE si le groupe est réglé', () {
      final group = groupOf([charge(id: '1')]);
      group.setTenderCurrency('USD');
      expect(group.isConverted, isFalse);

      group.applyCascade('500');

      expect(group.isConverted, isTrue);
    });

    test('les tranches ne pilotent jamais la conversion du groupe', () {
      // Leur montant imputé est la source, leur comptoir en découle : sinon la
      // page recalculerait le champ qui a le curseur.
      final group = groupOf([charge(id: '1'), charge(id: '2')]);
      group.tranches.first.tenderIsSource = true;

      group.setTenderCurrency('USD');

      expect(group.tranches.every((t) => !t.tenderIsSource), isTrue);
    });

    test('le comptoir n\'est PAS borné au restant', () {
      // Le parent pose ce qu'il pose ; l'excédent devient de la monnaie à
      // rendre, il ne s'impute pas.
      final group = groupOf([charge(id: '1')]);
      group.tenderController.text = '9999';

      expect(group.tenderedCents, 999900);
      expect(group.capInCents, 50000);
    });

    test('une conversion se ventile en UNE fois, pas tranche par tranche', () {
      // La page convertit au niveau du groupe puis ventile le résultat en
      // devise de créance : une seule troncature au lieu de N.
      final group = groupOf([
        charge(id: '1'),
        charge(id: '2'),
        charge(id: '3'),
      ]);

      final posted = group.applyCascadeCents(120000);

      expect(posted, 120000);
      expect(group.allocatedCents, 120000);
      expect(group.tranches[2].effectiveCents, 20000);
    });
  });

  test('clear vide le groupe ET ses tranches', () {
    final group = groupOf([charge(id: '1'), charge(id: '2')]);
    group.applyCascade('1000');

    group.clear();

    expect(group.controller.text, isEmpty);
    expect(group.selected, isFalse);
    expect(group.allocatedCents, 0);
    expect(group.tranches.every((t) => t.controller.text.isEmpty), isTrue);
  });
}
