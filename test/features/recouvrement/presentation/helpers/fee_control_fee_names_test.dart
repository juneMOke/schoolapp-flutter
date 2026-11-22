import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_fee_code_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_fee_options.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_query_phrase.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

LocalFeeTariff _tariff({
  String id = 't1',
  String label = 'Minerval 1ère année',
  String? code = 'T1',
}) => LocalFeeTariff(
  id: id,
  feeCode: 'TUITION',
  code: code,
  label: label,
  amountInCents: 15000,
  currency: 'USD',
  schoolLevelId: 'l1',
);

/// L'école a renommé `TUITION` ; les autres natures gardent leur nom localisé.
const _titles = FeeSectionTitlesState(
  titles: {'TUITION': 'Frais scolaires annuels'},
);

FeeControlState _searched({
  String classroomId = 'c1',
  FeeControlPaymentFilter filter = FeeControlPaymentFilter.all,
}) => FeeControlState(
  lastQuery: FeeControlQuery(
    academicYearId: 'ay-1',
    classroomId: classroomId,
    feeCodes: const ['TUITION'],
    statusFilter: filter,
    page: 0,
    size: 20,
  ),
);

void main() {
  final AppLocalizations l10n = AppLocalizationsFr();

  group('feeControlFeeCodeLabel — une seule règle pour tout le module', () {
    final single = buildFeeControlFeeOptions([_tariff()]).single;
    final tranches = buildFeeControlFeeOptions([
      _tariff(id: 't1', label: 'Minerval — 1/2', code: 'T1'),
      _tariff(id: 't2', label: 'Minerval — 2/2', code: 'T2'),
    ]).single;

    test('le titre de section passe AVANT la grille : c\'est le nom que la '
        'liste de relance imprime', () {
      expect(
        feeControlFeeCodeLabel(
          single,
          'TUITION',
          l10n,
          sectionTitle: 'Frais scolaires annuels',
        ),
        'Frais scolaires annuels',
      );
    });

    test('sans titre, la ligne de grille unique nomme la nature', () {
      expect(
        feeControlFeeCodeLabel(single, 'TUITION', l10n),
        'Minerval 1ère année',
      );
    });

    test(
      'un titre blanc ne compte pas : il remplacerait un nom par du vide',
      () {
        expect(
          feeControlFeeCodeLabel(single, 'TUITION', l10n, sectionTitle: '   '),
          'Minerval 1ère année',
        );
      },
    );

    test('plusieurs tranches sans titre : la nature localisée — aucun libellé '
        'de tranche ne vaut pour l\'ensemble', () {
      expect(
        feeControlFeeCodeLabel(tranches, 'TUITION', l10n),
        'TUITION'.localizedFeeLabel(l10n),
      );
    });

    test('plusieurs tranches avec titre : le titre les nomme toutes', () {
      expect(
        feeControlFeeCodeLabel(
          tranches,
          'TUITION',
          l10n,
          sectionTitle: 'Frais scolaires annuels',
        ),
        'Frais scolaires annuels',
      );
    });
  });

  group('recouvrementFeeTitle — le tableau de bord, sans grille', () {
    test('le titre de section quand l\'appareil le connaît', () {
      expect(
        recouvrementFeeTitle('TUITION', _titles, l10n),
        'Frais scolaires annuels',
      );
    });

    test('la casse du code ne compte pas : le catalogue est indexé en '
        'majuscules', () {
      expect(
        recouvrementFeeTitle('tuition', _titles, l10n),
        'Frais scolaires annuels',
      );
    });

    test('sinon, la nature localisée', () {
      expect(
        recouvrementFeeTitle('CANTEEN', _titles, l10n),
        'CANTEEN'.localizedFeeLabel(l10n),
      );
    });
  });

  group('l\'ordre de l\'école', () {
    const ordered = FeeSectionTitlesState(
      titles: {
        'REGISTRATION': 'Frais d\'inscription',
        'TUITION': 'Frais scolaires annuels',
      },
    );

    test('les natures suivent l\'ordre des sections, pas celui d\'arrivée', () {
      expect(recouvrementSchoolOrder(['TUITION', 'REGISTRATION'], ordered), [
        'REGISTRATION',
        'TUITION',
      ]);
    });

    test('une nature inconnue passe après, et les inconnues gardent leur '
        'ordre d\'arrivée', () {
      expect(
        recouvrementSchoolOrder([
          'CANTEEN',
          'TUITION',
          'BOOKS',
          'REGISTRATION',
        ], ordered),
        ['REGISTRATION', 'TUITION', 'CANTEEN', 'BOOKS'],
      );
    });

    test('sans titres sur l\'appareil, l\'ordre d\'arrivée est rendu tel '
        'quel', () {
      expect(
        recouvrementSchoolOrder([
          'TUITION',
          'BOOKS',
        ], const FeeSectionTitlesState()),
        ['TUITION', 'BOOKS'],
      );
    });

    test('la grille du contrôle se range dans l\'ordre de l\'école', () {
      final options = buildFeeControlFeeOptions([
        _tariff(),
        const LocalFeeTariff(
          id: 't9',
          feeCode: 'REGISTRATION',
          label: 'Inscription',
          amountInCents: 1000,
          currency: 'USD',
          schoolLevelId: 'l1',
        ),
      ], titles: ordered);

      expect(
        [for (final option in options) option.feeCode],
        ['REGISTRATION', 'TUITION'],
      );
    });
  });

  // La v2 choisit les frais à l'échelle de l'année, sans grille de niveau :
  // le nom vient du titre de l'école, sinon de la nature localisée — jamais
  // d'une ligne de tarif, qui varie d'un niveau à l'autre.
  group('la requête rejouée', () {
    test('le sous-titre nomme le frais comme sa pastille', () {
      expect(
        FeeControlQueryPhrase.parts(_searched(), l10n, titles: _titles).first,
        'Frais scolaires annuels',
      );
    });

    test('sans titre, la nature localisée', () {
      expect(
        FeeControlQueryPhrase.parts(_searched(), l10n).first,
        'TUITION'.localizedFeeLabel(l10n),
      );
    });

    test('la situation s\'écrit toujours, « Tous » compris (maquette : '
        '« Scolarité · 1ère primaire · Tous »)', () {
      expect(
        FeeControlQueryPhrase.parts(_searched(), l10n, titles: _titles).last,
        l10n.feeControlPaymentStatusAll,
      );
    });

    test('la rubrique « Non affectés » se nomme comme telle', () {
      expect(
        FeeControlQueryPhrase.parts(
          _searched(classroomId: feeControlUnassigned),
          l10n,
          titles: _titles,
        ),
        contains(l10n.recouvrementUnassigned),
      );
    });

    test('la puce d\'un état vide nomme le frais par le titre de l\'école', () {
      final chip = FeeControlQueryPhrase.chips(
        _searched(),
        l10n,
        titles: _titles,
      ).first;
      expect(chip, contains('Frais scolaires annuels'));
    });
  });
}
