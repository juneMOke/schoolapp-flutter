import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_deduction_issues.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_engine.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_fingerprinter.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

import '../payroll_builders.dart';

const _month = '2026-10';
const _cards = PayrollDeductionType(
  id: 'cards',
  code: 'CARTE',
  label: 'Cartes',
  currency: 'USD',
  defaultAmountInCents: 1000,
  sortOrder: 10,
);

PayrollLine _line(
  List<PayrollDeductionEntry> entries, {
  List<PayrollDeductionType> types = const [_cards],
  StaffContract? on,
}) => PayrollEngine.compute(
  PayrollEngineInput(
    month: _month,
    settings: PayrollSettings.defaults,
    contractsByMember: {
      'm-1': [on ?? contract('m-1')],
    },
    deductionTypes: types,
    deductions: {'m-1': entries},
  ),
).lines.single;

PayrollDeductionEntry _entry(int amount) => PayrollDeductionEntry(
  staffMemberId: 'm-1',
  deductionTypeId: 'cards',
  amountInCents: amount,
  currency: 'USD',
);

void main() {
  group('le défaut au moteur', () {
    test('un mois sans aucune saisie retient le défaut', () {
      final without = _line(const [], types: const []);
      final line = _line(const []);

      expect(line.deductions.custom.single.takenInCents, 1000);
      expect(line.deductions.custom.single.fromDefault, isTrue);
      expect(line.netInCents, without.netInCents - 1000);
    });

    test('un défaut et la même saisie signent la même empreinte', () {
      expect(
        PayrollFingerprinter.digestLines([_line(const [])]),
        PayrollFingerprinter.digestLines([
          _line([_entry(1000)]),
        ]),
      );
    });

    test('une saisie à 0 rend le net d\'avant', () {
      expect(
        _line([_entry(0)]).netInCents,
        _line(const [], types: const []).netInCents,
      );
    });

    test('un défaut dépassant le brut se rogne comme une saisie', () {
      final greedy = PayrollDeductionType(
        id: _cards.id,
        code: _cards.code,
        label: _cards.label,
        currency: _cards.currency,
        defaultAmountInCents: 99999999,
        sortOrder: 10,
      );

      final custom = _line(const [], types: [greedy]).deductions.custom.single;

      expect(custom.trimmed, isTrue);
    });

    test('8 — conventionné sans devise de prime : la première réglée', () {
      final conventionne = contract(
        'm-1',
        kind: StaffContractKind.conventionne,
        amount: 50000,
        currency: 'CDF',
      );

      final line = _line(const [], on: conventionne);

      expect(line.currency, PayrollSettings.defaults.firstCurrency);
      expect(
        line.deductions.custom.isNotEmpty,
        _cards.appliesTo(PayrollSettings.defaults.firstCurrency),
      );
    });
  });

  test('un défaut ne bloque jamais le circuit', () {
    final line = _line(const []);

    final issues = PayrollDeductionIssues.of(
      entries: const {},
      types: const [_cards],
      lines: [line],
    );

    expect(issues.blocker, isNull);
    expect(issues.foreign, isEmpty);
  });

  test('une saisie d\'une autre devise bloque toujours', () {
    final line = _line(const []);

    final issues = PayrollDeductionIssues.of(
      entries: {
        'm-1': const [
          PayrollDeductionEntry(
            staffMemberId: 'm-1',
            deductionTypeId: 'cards',
            amountInCents: 500,
            currency: 'CDF',
          ),
        ],
      },
      types: const [_cards],
      lines: [line],
    );

    expect(issues.blocker, PayrollBlocker.deductionCurrency);
  });
}
