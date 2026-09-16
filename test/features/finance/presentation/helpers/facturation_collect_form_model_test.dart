import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/tender_settlement.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_collect_form_model.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_rate_board.dart';

/// Lot R5 — la machine à états de la saisie, sortie de la page.
///
/// ⚠️ **Tout est asséré en CENTS ou en drapeaux, jamais sur une écriture.**
///
/// Ce que ces tests tiennent surtout, c'est le piège P1 : le modèle ne mémorise
/// PAS le règlement. `ExchangeRatesCubit` charge la série en asynchrone, et un
/// modèle qui l'aurait captée à sa construction convertirait de l'argent au taux
/// d'une série périmée sans que rien ne le signale.
final _taux = ExchangeRate(
  base: 'USD',
  quote: 'CDF',
  rateMicros: 2000000000,
  effectiveFrom: DateTime.utc(2026, 1, 1),
  divergenceBandBp: 200,
);

final _maintenant = DateTime.utc(2026, 9, 16, 8);

StudentCharge _charge({required String id, int cents = 5000}) => StudentCharge(
  id: id,
  studentId: 'stu-1',
  academicYearId: 'ay-1',
  schoolLevelId: 'lvl-1',
  schoolLevelGroupId: 'grp-1',
  feeTariffId: 'tar-$id',
  feeTariffCode: id,
  feeCode: 'TUITION',
  label: 'Minerval $id',
  expectedAmountInCents: cents.toDouble(),
  amountPaidInCents: 0,
  currency: 'USD',
  status: StudentChargeStatus.due,
);

void main() {
  late FacturationRateBoard rates;

  /// Compte les appels au rappel de règlement : c'est la sonde du piège P1.
  late int appelsAuReglement;
  late List<ExchangeRate> serie;

  FacturationCollectFormModel modele({int tranches = 3}) {
    rates = FacturationRateBoard(onChanged: () {});
    appelsAuReglement = 0;
    return FacturationCollectFormModel.fromCharges(
      charges: [for (var i = 1; i <= tranches; i++) _charge(id: 'T$i')],
      rates: rates,
      nowOf: () => _maintenant,
      settlementOf: () {
        appelsAuReglement++;
        return TenderSettlement(rates: serie, at: _maintenant);
      },
    );
  }

  setUp(() => serie = [_taux]);

  group('le règlement n\'est jamais mémorisé (piège P1)', () {
    test('il est REDEMANDÉ à chaque geste qui convertit', () {
      // ⚠️ La sonde se pose sur un geste qui CONVERTIT. Sur une ligne réglée
      // dans la devise de sa créance, `reflectTender` sort par sa branche
      // courte et ne demande aucun taux — un test posé là ne prouverait rien.
      final m = modele();
      final entry = m.entries.first;
      m.toggle(entry, true);
      m.tenderCurrencyChanged(entry, 'CDF');

      final apresPremier = appelsAuReglement;
      expect(apresPremier, greaterThan(0));

      m.reflectTender(entry);

      expect(appelsAuReglement, greaterThan(apresPremier));
    });

    test('une série arrivée APRÈS la construction est prise en compte', () {
      // Le cas réel : le cubit des taux charge en asynchrone. Un modèle qui
      // aurait capté la série vide à sa naissance ne convertirait jamais.
      serie = const [];
      final m = modele();
      final entry = m.entries.first;

      m.toggle(entry, true);
      m.tenderCurrencyChanged(entry, 'CDF');
      // Sans taux, le règlement rend une ligne au taux NUL : le comptoir vaut
      // alors l'imputation, il n'est pas vide.
      final sansTaux = entry.tenderController.text;
      expect(sansTaux, isNotEmpty);

      // Les taux arrivent — le cubit a fini de charger.
      serie = [_taux];
      m.reflectTender(entry);

      // 50,00 $ à 2 000,00 font 100 000 FC : le comptoir a forcément changé.
      // S'il n'avait pas bougé, c'est que le modèle aurait capté la série vide.
      expect(entry.tenderController.text, isNot(sansTaux));
    });
  });

  group('le jour du versement', () {
    test('vaut aujourd\'hui tant que rien n\'est choisi', () {
      expect(modele().paidDay, DateTime(2026, 9, 16));
    });

    test('re-confirmer le même jour ne change RIEN', () {
      final m = modele();

      expect(m.paidDayChanged(DateTime(2026, 9, 16)), isFalse);
    });

    test('choisir un autre jour le retient', () {
      final m = modele();

      expect(m.paidDayChanged(DateTime(2026, 9, 12)), isTrue);
      expect(m.paidDay, DateTime(2026, 9, 12));
    });

    test('ne retient que le jour, jamais l\'heure', () {
      final m = modele()..paidDayChanged(DateTime(2026, 9, 12, 7, 45));

      expect(m.paidDay, DateTime(2026, 9, 12));
    });
  });

  group('les gestes d\'une tranche', () {
    test('cocher solde la ligne', () {
      final m = modele();
      final entry = m.entries.first;

      m.toggle(entry, true);

      expect(entry.selected, isTrue);
      expect(entry.effectiveCents, 5000);
    });

    test('décocher vide les deux champs', () {
      final m = modele();
      final entry = m.entries.first;
      m.toggle(entry, true);

      m.toggle(entry, false);

      expect(entry.controller.text, isEmpty);
      expect(entry.tenderController.text, isEmpty);
    });

    test('taper le comptoir fait de LUI la source', () {
      final m = modele();
      final entry = m.entries.first;
      m.toggle(entry, true);
      m.tenderCurrencyChanged(entry, 'CDF');

      entry.tenderController.text = '40000';
      m.tenderEdited(entry);

      expect(entry.tenderIsSource, isTrue);
      // 40 000 FC à 2 000,00 éteignent 20,00 $.
      expect(entry.effectiveCents, 2000);
    });
  });

  group('les gestes d\'une nature', () {
    test('cocher la nature cascade sur ses tranches', () {
      final m = modele();
      final group = m.groups.single;

      m.groupToggle(group, true);

      expect(group.allocatedCents, 15000);
      expect(m.entries.every((e) => e.selected), isTrue);
    });

    test('éditer une tranche rend la main aux tranches', () {
      final m = modele();
      final group = m.groups.single;
      m.groupToggle(group, true);
      expect(group.groupIsSource, isTrue);

      m.allocationEdited(m.entries.first);

      // L'invariant de R2 : les deux drapeaux tombent ensemble.
      expect(group.groupIsSource, isFalse);
      expect(group.tenderIsSource, isFalse);
    });

    test('poser plus que le plafond n\'impute pas au-delà', () {
      final m = modele();
      final group = m.groups.single;
      m.groupToggle(group, true);
      m.groupTenderCurrencyChanged(group, 'CDF');

      group.tenderController.text = '999999';
      m.groupTenderEdited(group);

      // Le plafond de la nature : 3 × 50,00 $.
      expect(group.allocatedCents, 15000);
    });
  });

  group('changer la date re-dérive', () {
    test('sans détruire une ventilation saisie à la main', () {
      // Le parcours qui a coûté de l'argent avant R2, rejoué au niveau du
      // modèle : il doit rester sans effet sur la ventilation.
      final m = modele();
      final group = m.groups.single;
      m.groupToggle(group, true);
      m.groupTenderCurrencyChanged(group, 'CDF');
      group.tenderController.text = '200000';
      m.groupTenderEdited(group);

      m.entries.first.controller.text = '10';
      m.allocationEdited(m.entries.first);
      final ventilation = m.entries.first.controller.text;

      m.paidDayChanged(DateTime(2026, 9, 12));

      expect(m.entries.first.controller.text, ventilation);
    });
  });
}
