import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_fingerprint_json.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_line_json.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_fingerprint.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line_parts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_advance_schedule.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_engine.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_fingerprinter.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

import '../payroll_builders.dart';

const _month = '2026-10';
const _cards = PayrollDeductionType(
  id: 'b-cards',
  label: 'Cartes',
  sortOrder: 10,
);
const _uniform = PayrollDeductionType(
  id: 'a-unif',
  label: 'Tenue',
  sortOrder: 20,
);

PayrollDeductionEntry _entry(
  String typeId,
  int amount, {
  String currency = 'USD',
}) => PayrollDeductionEntry(
  staffMemberId: 'm-1',
  deductionTypeId: typeId,
  amountInCents: amount,
  currency: currency,
);

PayrollLine _line(
  List<PayrollDeductionEntry> entries, {
  List<PayrollDeductionType> types = const [_cards, _uniform],
  StaffContract? on,
  List advances = const [],
  PayrollVariables? variables,
}) => PayrollEngine.compute(
  PayrollEngineInput(
    month: _month,
    settings: PayrollSettings.defaults,
    contractsByMember: {
      'm-1': [on ?? contract('m-1')],
    },
    variables: {'m-1': ?variables},
    deductionTypes: types,
    deductions: {'m-1': entries},
    advances: PayrollAdvanceSchedule.statesOf(
      advances.cast(),
      _month,
      const [],
    ),
  ),
).lines.single;

void main() {
  group('rubriques de l\'école au moteur', () {
    test('une paie sans rubrique ne bouge pas', () {
      final without = _line(const [], types: const []);
      final zero = _line([_entry('b-cards', 0)]);

      expect(zero, without);
      expect(zero.deductions.custom, isEmpty);
    });

    test('elles baissent le net et entrent dans le total', () {
      final without = _line(const [], types: const []);
      final line = _line([_entry('b-cards', 500)]);

      expect(line.netInCents, without.netInCents - 500);
      expect(line.deductions.customInCents, 500);
      expect(
        line.deductions.totalInCents,
        without.deductions.totalInCents + 500,
      );
      expect(
        line.netInCents,
        line.grossInCents - line.deductions.totalInCents - line.advanceInCents,
      );
    });

    test('ordre : sortOrder, puis identifiant en texte', () {
      final line = _line(
        [_entry('a-unif', 100), _entry('b-cards', 200), _entry('c-last', 300)],
        types: const [
          _uniform,
          _cards,
          PayrollDeductionType(id: 'c-last', label: 'Autre', sortOrder: 10),
        ],
      );

      expect(line.deductions.custom.map((c) => c.deductionTypeId), [
        'b-cards',
        'c-last',
        'a-unif',
      ]);
    });

    test('rognage dans l\'ordre, le reste est perdu, 0 reste listé', () {
      final capacity = _line(const [], types: const []).netInCents;
      final line = _line([
        _entry('b-cards', capacity - 100),
        _entry('a-unif', 400),
      ]);
      final last = _line([_entry('b-cards', capacity), _entry('a-unif', 400)]);

      expect(line.netInCents, 0);
      expect(line.deductions.custom.last.takenInCents, 100);
      expect(line.deductions.custom.last.trimmed, isTrue);
      expect(line.deductions.hasTrimmedCustom, isTrue);
      expect(last.deductions.custom.last.requestedInCents, 400);
      expect(last.deductions.custom.last.takenInCents, 0);
    });

    test('elles passent avant l\'avance, qui glisse au mois suivant', () {
      final capacity = _line(const [], types: const []).netInCents;
      final line = _line(
        [_entry('b-cards', capacity - 3000)],
        advances: [advance('m-1', amount: 10000)],
      );

      expect(line.advanceInCents, 3000);
      expect(line.carriedInCents, 7000);
      expect(line.netInCents, 0);
    });

    test('une rubrique archivée avec un montant compte toujours', () {
      final active = _line([_entry('b-cards', 500)]);
      final archived = _line(
        [_entry('b-cards', 500)],
        types: const [
          PayrollDeductionType(
            id: 'b-cards',
            label: 'Cartes',
            sortOrder: 10,
            archived: true,
          ),
        ],
      );

      expect(archived.netInCents, active.netInCents);
      expect(archived.deductions.custom, hasLength(1));
    });

    test('une saisie dans une autre devise sort du calcul', () {
      final without = _line(const [], types: const []);
      final line = _line([_entry('b-cards', 500, currency: 'cdf')]);

      expect(line.netInCents, without.netInCents);
      expect(line.deductions.custom, isEmpty);
    });

    test('une saisie sans rubrique au catalogue n\'est pas comptée', () {
      final without = _line(const [], types: const []);

      expect(_line([_entry('ghost', 500)]).netInCents, without.netInCents);
    });

    test('le taux du mois se calcule sur le net après rubriques', () {
      final line = _line([_entry('b-cards', 500)]);

      expect(line.toPayInCents, line.netInCents);
    });

    test('devise d\'un conventionné : sa prime, sinon la 1re de l\'école', () {
      final withBonus = contract(
        'm-1',
        kind: StaffContractKind.conventionne,
        amount: 90000,
        bonus: 5000,
      );
      final noBonus = contract(
        'm-1',
        kind: StaffContractKind.conventionne,
        amount: 90000,
        currency: 'CDF',
      );

      expect(PayrollEngine.currencyOf(withBonus), 'USD');
      expect(PayrollEngine.currencyOf(noBonus, fallback: 'USD'), 'USD');
    });
  });

  group('empreinte', () {
    const base = PayrollDigestLine(
      staffMemberId: 'm',
      currency: 'USD',
      grossInCents: 100,
      advanceInCents: 0,
      netInCents: 90,
      formulaVersion: 3,
      toPayInCents: 90,
    );

    test('sans rubrique, la forme canonique actuelle', () {
      expect(base.canonical, 'm|USD|100|0|0|0|0|0|90|90');
    });

    test(
      'avec rubriques, un dernier champ, 0 compris, en minuscules',
      () async {
        const lines = [
          PayrollLine(
            month: _month,
            staffMemberId: 'M',
            currency: 'USD',
            baseInCents: 100,
            grossInCents: 100,
            netInCents: 90,
            deductions: PayrollLineDeductions(
              custom: [
                PayrollLineCustomDeduction(
                  deductionTypeId: 'B-CARDS',
                  label: 'Cartes',
                  requestedInCents: 10,
                  takenInCents: 10,
                ),
                PayrollLineCustomDeduction(
                  deductionTypeId: 'a-unif',
                  label: 'Tenue',
                  requestedInCents: 5,
                  takenInCents: 0,
                ),
              ],
            ),
          ),
        ];

        final digest = PayrollFingerprinter.digestLines(lines).single;
        final totals = PayrollFingerprinter.totalsOf([digest]).single;

        expect(
          digest.canonical,
          'm|USD|100|0|0|0|0|0|90|90|b-cards:10,a-unif:0',
        );
        expect(totals.deductionInCents, 10);
      },
    );

    test('une rubrique qui diffère signale l\'agent', () {
      const server = PayrollDigestLine(
        staffMemberId: 'm',
        currency: 'USD',
        grossInCents: 100,
        advanceInCents: 0,
        netInCents: 90,
        formulaVersion: 3,
        toPayInCents: 90,
        customDeductions: [
          PayrollDigestDeduction(deductionTypeId: 't', takenInCents: 0),
        ],
      );

      expect(PayrollFingerprinter.differingMembers([base], [server]), {'m'});
    });

    test('customDeductions[] se relit et se réécrit', () {
      final parsed = PayrollFingerprintJson.tryParse({
        'lineCount': 1,
        'totals': const [],
        'linesDigest': 'x',
        'formulaVersion': 3,
        'lines': [
          {
            'staffMemberId': 'm',
            'currency': 'USD',
            'grossInCents': 100,
            'advanceInCents': 0,
            'netInCents': 90,
            'toPayInCents': 90,
            'customDeductions': [
              {'deductionTypeId': 'T', 'takenInCents': 10},
            ],
          },
        ],
      })!;

      expect(parsed.lines.single.customDeductions.single.deductionTypeId, 't');
      expect(
        PayrollFingerprintJson.tryParse(PayrollFingerprintJson.encode(parsed)),
        parsed,
      );
    });
  });

  group('ligne descendue', () {
    Map<String, Object?> raw(Object? custom) => {
      'staffMemberId': 'm',
      'currency': 'USD',
      'grossInCents': 100,
      'netInCents': 90,
      'deductions': {'custom': custom},
    };

    test('custom[] se lit, dans l\'ordre, et entre dans le total', () {
      final line = PayrollLineJson.tryParse(
        raw([
          {
            'deductionTypeId': 't',
            'label': 'Cartes',
            'requestedInCents': 15,
            'takenInCents': 10,
          },
        ]),
        month: _month,
      )!;

      expect(line.deductions.custom.single.label, 'Cartes');
      expect(line.deductions.custom.single.trimmed, isTrue);
      expect(line.deductions.totalInCents, 10);
    });

    test('absent, il vaut vide ; illisible, la ligne est écartée', () {
      expect(
        PayrollLineJson.tryParse(raw(null), month: _month)?.deductions.custom,
        isEmpty,
      );
      expect(
        PayrollLineJson.tryParse(
          raw([
            {'label': 'sans identifiant'},
          ]),
          month: _month,
        ),
        isNull,
      );
    });
  });
}
