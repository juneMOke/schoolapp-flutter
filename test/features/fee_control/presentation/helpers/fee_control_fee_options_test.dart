import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/fee_control/presentation/helpers/fee_control_fee_options.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

LocalFeeTariff tariff({
  String id = 't1',
  String feeCode = 'TUITION',
  String? code,
  String label = 'Frais scolaires annuels',
  int amountInCents = 15000,
  String currency = 'USD',
  String? schoolLevelId = 'l1',
}) => LocalFeeTariff(
  id: id,
  feeCode: feeCode,
  code: code,
  label: label,
  amountInCents: amountInCents,
  currency: currency,
  schoolLevelId: schoolLevelId,
);

void main() {
  final AppLocalizations l10n = AppLocalizationsFr();

  group('buildFeeControlFeeOptions', () {
    /// La maille n'est pas décorative : `getFeeChargeAggregates` joint par
    /// `fee_code` avec des `SUM`. Deux entrées pour la même nature donneraient
    /// deux choix menant au même tableau — et, le sélecteur travaillant sur la
    /// valeur, deux entrées de même valeur le casseraient.
    test('une entrée par nature, jamais deux', () {
      final options = buildFeeControlFeeOptions([
        tariff(id: 't-niveau', feeCode: 'TUITION'),
        // Le même code, mais posé au CYCLE : la grille d'un niveau les remonte
        // tous les deux.
        tariff(id: 't-cycle', feeCode: 'TUITION', schoolLevelId: null),
        tariff(id: 't-exam', feeCode: 'EXAMINATION'),
      ]);

      expect(options.map((o) => o.feeCode), ['TUITION', 'EXAMINATION']);
    });

    test("l'ordre de la grille est conservé", () {
      final options = buildFeeControlFeeOptions([
        tariff(id: 'a', feeCode: 'CANTEEN'),
        tariff(id: 'b', feeCode: 'TUITION'),
        tariff(id: 'c', feeCode: 'BOOKS'),
      ]);

      expect(options.map((o) => o.feeCode), ['CANTEEN', 'TUITION', 'BOOKS']);
    });

    /// Une nature à ligne unique : cette ligne EST la nature, son libellé et son
    /// code décrivent exactement ce qui sera contrôlé.
    test('une seule ligne → son libellé et son code nomment la nature', () {
      final options = buildFeeControlFeeOptions([
        tariff(label: 'Frais scolaires annuels', code: 'SCO'),
      ]);

      expect(options.single.isSingleTariff, isTrue);
      expect(options.single.tariffLabel, 'Frais scolaires annuels');
      expect(options.single.tariffCode, 'SCO');
      expect(options.single.amountInCents, 15000);
      expect(options.single.currency, 'USD');
    });

    /// Le piège que ce lot ferme : la version d'avant gardait la PREMIÈRE ligne
    /// et affichait son libellé. « Minerval — 1/7 » désignait alors un contrôle
    /// qui porte sur les sept tranches, et le montant affiché valait le septième
    /// de l'attendu.
    test('plusieurs tranches → aucun libellé emprunté, le total est sommé', () {
      final options = buildFeeControlFeeOptions([
        tariff(
          id: 't1',
          code: 'T1',
          label: 'Minerval — 1/3',
          amountInCents: 5000,
        ),
        tariff(
          id: 't2',
          code: 'T2',
          label: 'Minerval — 2/3',
          amountInCents: 5000,
        ),
        tariff(
          id: 't3',
          code: 'T3',
          label: 'Minerval — 3/3',
          amountInCents: 5000,
        ),
      ]);

      expect(options.single.tariffCount, 3);
      expect(options.single.isSingleTariff, isFalse);
      expect(options.single.tariffLabel, isEmpty);
      expect(options.single.tariffCode, isNull);
      expect(options.single.amountInCents, 15000);
    });

    /// Additionner deux devises ne produit aucun montant vrai. Mieux vaut n'en
    /// afficher aucun que d'en afficher un faux sur de l'argent.
    test('tranches de devises différentes → pas de montant du tout', () {
      final options = buildFeeControlFeeOptions([
        tariff(id: 't1', code: 'T1', amountInCents: 5000, currency: 'USD'),
        tariff(id: 't2', code: 'T2', amountInCents: 5000, currency: 'CDF'),
      ]);

      expect(options.single.amountInCents, isNull);
      expect(options.single.currency, isNull);
    });
  });

  group('feeControlFeeOptionFor', () {
    test('retrouve la nature choisie, regroupée comme le sélecteur', () {
      final tariffs = [
        tariff(id: 't1', code: 'T1', label: 'Minerval — 1/2'),
        tariff(id: 't2', code: 'T2', label: 'Minerval — 2/2'),
        tariff(id: 'e1', feeCode: 'EXAMINATION', code: 'OM', label: 'Examens'),
      ];

      // La nature à deux tranches n'emprunte le libellé d'aucune des deux, même
      // interrogée directement : c'est ce que le formulaire fera descendre dans
      // la requête, et donc ce que la puce de critère affichera.
      expect(feeControlFeeOptionFor(tariffs, 'TUITION')!.tariffLabel, isEmpty);
      expect(
        feeControlFeeOptionFor(tariffs, 'EXAMINATION')!.tariffLabel,
        'Examens',
      );
    });

    test('rien de choisi, ou une nature absente de la grille → null', () {
      expect(feeControlFeeOptionFor([tariff()], null), isNull);
      expect(feeControlFeeOptionFor([tariff()], 'CANTEEN'), isNull);
    });
  });

  group('feeControlFeeOptionLabel', () {
    test('libellé de la grille, code utile, puis montant', () {
      final option = buildFeeControlFeeOptions([
        tariff(label: 'Organisation matériel examens', code: 'OM2'),
      ]).single;

      expect(
        feeControlFeeOptionLabel(option, l10n),
        'Organisation matériel examens (OM2) · 150,00\u00a0\$',
      );
    });

    /// Le serveur retombe sur la nature quand l'école ne saisit pas de code :
    /// « Frais scolaires annuels (TUITION) » n'ajouterait que du bruit.
    test('un code qui vaut la nature ne se compose pas', () {
      final option = buildFeeControlFeeOptions([
        tariff(label: 'Frais scolaires annuels', code: 'TUITION'),
      ]).single;

      expect(
        feeControlFeeOptionLabel(option, l10n),
        'Frais scolaires annuels · 150,00\u00a0\$',
      );
    });

    /// Une créance ad hoc peut n'avoir aucun libellé : un frais sans nom du tout
    /// serait pire que trop générique.
    test('sans libellé de grille → la nature localisée', () {
      final option = buildFeeControlFeeOptions([
        tariff(label: '   ', code: null),
      ]).single;

      expect(
        feeControlFeeOptionLabel(option, l10n),
        '${l10n.studentChargeFeeCodeTuition} · 150,00\u00a0\$',
      );
    });

    test('plusieurs tranches → la nature, le compte, et le total', () {
      final option = buildFeeControlFeeOptions([
        tariff(
          id: 't1',
          code: 'T1',
          label: 'Minerval — 1/2',
          amountInCents: 5000,
        ),
        tariff(
          id: 't2',
          code: 'T2',
          label: 'Minerval — 2/2',
          amountInCents: 5000,
        ),
      ]).single;

      expect(
        feeControlFeeOptionLabel(option, l10n),
        '${l10n.studentChargeFeeCodeTuition} · 2 tranches · 100,00\u00a0\$',
      );
    });

    test('tranches de devises différentes → ni total, ni montant faux', () {
      final option = buildFeeControlFeeOptions([
        tariff(id: 't1', code: 'T1', currency: 'USD'),
        tariff(id: 't2', code: 'T2', currency: 'CDF'),
      ]).single;

      expect(
        feeControlFeeOptionLabel(option, l10n),
        '${l10n.studentChargeFeeCodeTuition} · 2 tranches',
      );
    });
  });
}
