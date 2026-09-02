import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_designation.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_grouping.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Comment un groupe de créances se nomme (GF-2).
///
/// La règle du Contrôle des frais, transposée à ce que l'élève porte
/// réellement — avec une nuance qui n'existait pas là-bas : **le titre de
/// l'école** coiffe le groupe quand cet appareil le connaît.
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  StudentCharge charge({
    required String id,
    String feeCode = 'TUITION',
    String label = '',
    String? tariffCode,
  }) => StudentCharge(
    id: id,
    studentId: 's-1',
    academicYearId: 'y-1',
    schoolLevelId: 'lvl-1',
    schoolLevelGroupId: 'grp-1',
    feeTariffId: 't-$id',
    feeTariffCode: tariffCode,
    feeCode: feeCode,
    label: label,
    expectedAmountInCents: 50000,
    amountPaidInCents: 0,
    currency: 'CDF',
    status: StudentChargeStatus.due,
  );

  StudentChargeGroup groupOf(List<StudentCharge> charges) =>
      groupChargesByFeeCode(charges).single;

  group('une seule tranche', () {
    test('garde le libellé du TARIF et son code, pas le titre de section', () {
      // Le libellé d'un tarif est un instantané gelé à la naissance de la
      // créance : renommer la section ne le réécrit pas. Lui substituer le titre
      // de l'école ferait dire à la fiche autre chose que la note de perception.
      final group = groupOf([
        charge(
          id: '1',
          feeCode: 'EXAMINATION',
          label: 'Organisation matériel — 2/3',
          tariffCode: 'OM2',
        ),
      ]);

      expect(
        chargeGroupDesignation(group, l10n, schoolTitle: 'Frais d\'épreuves'),
        'Organisation matériel — 2/3 (OM2)',
      );
    });

    test('sans libellé, retombe sur la nature localisée', () {
      final group = groupOf([charge(id: '1', feeCode: 'CANTEEN')]);

      expect(chargeGroupDesignation(group, l10n), 'Cantine');
    });

    test('n\'annonce aucun compte de tranches', () {
      final group = groupOf([charge(id: '1', label: 'Minerval')]);

      expect(chargeGroupDesignation(group, l10n), 'Minerval');
    });
  });

  group('plusieurs tranches', () {
    test('prend le titre de l\'école quand il est connu', () {
      final group = groupOf([
        charge(id: '1', label: 'Minerval — 1/3', tariffCode: 'T1'),
        charge(id: '2', label: 'Minerval — 2/3', tariffCode: 'T2'),
        charge(id: '3', label: 'Minerval — 3/3', tariffCode: 'T3'),
      ]);

      expect(
        chargeGroupDesignation(group, l10n, schoolTitle: 'Frais scolaires'),
        'Frais scolaires · 3 tranches',
      );
    });

    test('retombe sur la nature localisée quand il ne l\'est pas', () {
      // Le repli d'une tablette qui n'a pas encore reçu le catalogue — et de
      // celle qui n'a jamais vu le serveur. Il est STABLE : il dit toujours la
      // même chose.
      final group = groupOf([
        charge(id: '1', label: 'Minerval — 1/2'),
        charge(id: '2', label: 'Minerval — 2/2'),
      ]);

      expect(
        chargeGroupDesignation(group, l10n),
        'Frais de scolarité · 2 tranches',
      );
    });

    test('un titre vide ou blanc vaut un titre absent', () {
      final group = groupOf([charge(id: '1'), charge(id: '2')]);

      expect(
        chargeGroupDesignation(group, l10n, schoolTitle: '   '),
        'Frais de scolarité · 2 tranches',
      );
    });

    test(
      'n\'emprunte JAMAIS le libellé de la première tranche pour l\'ensemble',
      () {
        // Le piège que le sélecteur du Contrôle a déjà écarté : « Minerval —
        // 1/7 » en tête laisserait croire qu'on ne regarde que la première.
        final group = groupOf([
          charge(id: '1', label: 'Minerval — 1/7', tariffCode: 'T1'),
          charge(id: '2', label: 'Minerval — 2/7', tariffCode: 'T2'),
        ]);

        final designation = chargeGroupDesignation(group, l10n);

        expect(designation, isNot(contains('1/7')));
        expect(designation, isNot(contains('T1')));
      },
    );

    test('le compte annoncé est celui de l\'ÉLÈVE', () {
      // Trois tranches portées sur un minerval qui en compte sept dans la
      // grille : la fiche décrit cet élève-ci.
      final group = groupOf([
        charge(id: '1', tariffCode: 'T1'),
        charge(id: '2', tariffCode: 'T2'),
        charge(id: '3', tariffCode: 'T3'),
      ]);

      expect(
        chargeGroupDesignation(group, l10n),
        'Frais de scolarité · 3 tranches',
      );
    });
  });
}
