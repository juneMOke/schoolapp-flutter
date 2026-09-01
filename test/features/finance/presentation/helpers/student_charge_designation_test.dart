import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/domain/fee_tariff_code.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_designation.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

StudentCharge charge({
  String label = 'Organisation matériel examens — 2/3',
  String feeCode = 'EXAMINATION',
  String? feeTariffCode = 'OM2',
}) => StudentCharge(
  id: 'c1',
  studentId: 's1',
  academicYearId: 'y1',
  schoolLevelId: 'l1',
  schoolLevelGroupId: 'g1',
  feeTariffId: 't1',
  feeTariffCode: feeTariffCode,
  feeCode: feeCode,
  label: label,
  expectedAmountInCents: 500000,
  amountPaidInCents: 0,
  currency: 'CDF',
  status: StudentChargeStatus.due,
);

void main() {
  final AppLocalizations l10n = AppLocalizationsFr();

  /// Le serveur retombe sur la NATURE quand l'école ne saisit pas de code. Vue
  /// de la tablette, cette valeur est présente et informativement vide : c'est
  /// la seule règle du lot, et elle est partagée avec le ticket imprimé, qui
  /// n'a pas de `l10n` pour la rejouer autrement.
  group('meaningfulTariffCode', () {
    test('un code qui distingue est retenu', () {
      expect(meaningfulTariffCode(code: 'OM2', feeCode: 'EXAMINATION'), 'OM2');
    });

    test('un code égal à la nature ne distingue rien', () {
      expect(meaningfulTariffCode(code: 'TUITION', feeCode: 'TUITION'), isNull);
    });

    /// Le serveur normalise en majuscules, mais rien n'oblige une base ancienne
    /// ou un import à l'avoir fait. La règle tranche sur le sens, pas sur
    /// l'orthographe — sinon « tuition » passerait pour un vrai discriminant et
    /// s'afficherait en face de sa propre nature.
    test('casse et espaces de bord ignorés dans la comparaison', () {
      expect(
        meaningfulTariffCode(code: ' tuition ', feeCode: 'TUITION'),
        isNull,
      );
    });

    test('absent ou vide → rien à afficher', () {
      expect(meaningfulTariffCode(code: null, feeCode: 'TUITION'), isNull);
      expect(meaningfulTariffCode(code: '   ', feeCode: 'TUITION'), isNull);
    });

    test('un code utile est rendu sans ses espaces de bord', () {
      expect(
        meaningfulTariffCode(code: '  OM2  ', feeCode: 'EXAMINATION'),
        'OM2',
      );
    });
  });

  group('chargeDesignation', () {
    /// Le cas qui a motivé le chantier : sept tranches de minerval s'affichaient
    /// sept fois « Minerval », et la ligne qu'on coche ne se distinguait de la
    /// suivante que par son montant.
    test('libellé + code → la tranche est nommée', () {
      expect(
        chargeDesignation(charge(), l10n),
        'Organisation matériel examens — 2/3 (OM2)',
      );
    });

    /// Une grille simple n'a pas de code à saisir, et le serveur y met la
    /// nature. Afficher « Minerval (TUITION) » ajouterait du bruit sur TOUTES
    /// les écoles pour ne rien distinguer nulle part.
    test('code égal à la nature → pas de parenthèse', () {
      expect(
        chargeDesignation(
          charge(
            label: 'Minerval',
            feeCode: 'TUITION',
            feeTariffCode: 'TUITION',
          ),
          l10n,
        ),
        'Minerval',
      );
    });

    /// Grille pas encore repullée après la v39, tarif hors de l'appareil,
    /// créance *ad hoc* : trois causes, un seul rendu — le libellé seul, qui est
    /// le comportement d'avant ce chantier.
    test('code absent → le libellé seul', () {
      expect(
        chargeDesignation(charge(feeTariffCode: null), l10n),
        'Organisation matériel examens — 2/3',
      );
    });

    /// Une créance *ad hoc* peut n'avoir aucun libellé : un frais sans nom du
    /// tout serait pire que trop générique.
    test('sans libellé → replie sur la nature localisée, code compris', () {
      expect(
        chargeDesignation(charge(label: '   '), l10n),
        '${l10n.studentChargeFeeCodeExamination} (OM2)',
      );
    });

    test('sans libellé ni code → la nature localisée, nue', () {
      expect(
        chargeDesignation(charge(label: '', feeTariffCode: null), l10n),
        l10n.studentChargeFeeCodeExamination,
      );
    });

    /// Nature inconnue du catalogue : la localisation retombe sur « Frais
    /// scolaire », et le code reste la seule chose qui distingue la ligne.
    test('nature inconnue sans libellé → repli générique + code', () {
      expect(
        chargeDesignation(
          charge(label: '', feeCode: 'NOUVEAU_FRAIS', feeTariffCode: 'X2'),
          l10n,
        ),
        '${l10n.studentChargeFeeCodeFallback} (X2)',
      );
    });

    /// Le libellé vient du serveur : il ne se traduit pas, et rien ne doit le
    /// réécrire au passage.
    test('le libellé du référentiel traverse tel quel', () {
      expect(
        chargeDesignation(charge(label: 'Frais d\'internat — 1/2'), l10n),
        'Frais d\'internat — 1/2 (OM2)',
      );
    });
  });
}
