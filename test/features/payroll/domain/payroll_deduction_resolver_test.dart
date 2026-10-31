import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_deduction_issues.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_deduction_resolver.dart';

PayrollDeductionType _type(
  String id, {
  int defaultAmount = 0,
  String currency = 'USD',
  int order = 10,
  bool archived = false,
}) => PayrollDeductionType(
  id: id,
  label: id,
  currency: currency,
  defaultAmountInCents: defaultAmount,
  sortOrder: order,
  archived: archived,
);

PayrollDeductionEntry _entry(
  String type,
  int amount, {
  String currency = 'USD',
}) => PayrollDeductionEntry(
  staffMemberId: 'm-1',
  deductionTypeId: type,
  amountInCents: amount,
  currency: currency,
);

Map<String, int> _amounts(List<PayrollResolvedDeduction> resolved) => {
  for (final deduction in resolved) deduction.type.id: deduction.amountInCents,
};

void main() {
  group('cas du contrat, en attendant les vecteurs communs', () {
    test('1 — défaut sans saisie', () {
      final resolved = PayrollDeductionResolver.resolve(
        [_type('a', defaultAmount: 500)],
        const [],
        'USD',
      );

      expect(_amounts(resolved), {'a': 500});
      expect(resolved.single.fromDefault, isTrue);
    });

    test('2 — une saisie remplace le défaut, plus haut comme plus bas', () {
      for (final amount in [900, 100]) {
        final resolved = PayrollDeductionResolver.resolve(
          [_type('a', defaultAmount: 500)],
          [_entry('a', amount)],
          'USD',
        );

        expect(_amounts(resolved), {'a': amount});
        expect(resolved.single.fromDefault, isFalse);
      }
    });

    test('3 — une saisie à 0 écarte le défaut', () {
      expect(
        PayrollDeductionResolver.resolve(
          [_type('a', defaultAmount: 500)],
          [_entry('a', 0)],
          'USD',
        ),
        isEmpty,
      );
    });

    test('4 — agent d\'une autre devise : rubrique non applicable', () {
      expect(
        PayrollDeductionResolver.resolve(
          [_type('a', defaultAmount: 500)],
          const [],
          'CDF',
        ),
        isEmpty,
      );
    });

    test('5 — une archivée n\'applique plus son défaut, sa saisie compte', () {
      final archived = _type('a', defaultAmount: 500, archived: true);

      expect(
        PayrollDeductionResolver.resolve([archived], const [], 'USD'),
        isEmpty,
      );
      expect(
        _amounts(
          PayrollDeductionResolver.resolve(
            [archived],
            [_entry('a', 300)],
            'USD',
          ),
        ),
        {'a': 300},
      );
    });

    test('6 — l\'ordre du moteur vaut pour les défauts', () {
      final resolved = PayrollDeductionResolver.resolve(
        [
          _type('b', defaultAmount: 100, order: 20),
          _type('c', defaultAmount: 100, order: 10),
          _type('a', defaultAmount: 100, order: 10),
        ],
        const [],
        'USD',
      );

      expect(resolved.map((d) => d.type.id), ['a', 'c', 'b']);
    });

    test('un défaut à 0 ne retient rien', () {
      expect(
        PayrollDeductionResolver.resolve([_type('a')], const [], 'USD'),
        isEmpty,
      );
    });
  });

  group('rubrique refusée', () {
    PayrollDeductionType refused({required bool serverKnown}) =>
        PayrollDeductionType(
          id: 'a',
          label: 'a',
          currency: 'USD',
          defaultAmountInCents: 500,
          sortOrder: 10,
          serverKnown: serverKnown,
          syncState: RecordSyncState.failed,
        );

    test('jamais reçue par le serveur : son défaut ne compte pas', () {
      expect(
        PayrollDeductionResolver.resolve(
          [refused(serverKnown: false)],
          const [],
          'USD',
        ),
        isEmpty,
      );
    });

    test('connue du serveur : son défaut compte, et le circuit se bloque', () {
      final type = refused(serverKnown: true);

      expect(
        _amounts(PayrollDeductionResolver.resolve([type], const [], 'USD')),
        {'a': 500},
      );
      expect(
        PayrollDeductionIssues.of(
          entries: const {},
          types: [type],
          lines: const [],
        ).blocker,
        PayrollBlocker.deductionTypeRefused,
      );
    });
  });

  group('saisies hors de la devise de la ligne', () {
    test('hors calcul, et le défaut ne les remplace pas', () {
      expect(
        PayrollDeductionResolver.resolve(
          [_type('a', defaultAmount: 500)],
          [_entry('a', 900, currency: 'CDF')],
          'USD',
        ),
        isEmpty,
      );
    });

    test('une saisie sur une rubrique inconnue ne compte pas', () {
      expect(
        PayrollDeductionResolver.resolve(const [], [_entry('a', 900)], 'USD'),
        isEmpty,
      );
    });

    test('la casse des identifiants et des devises ne joue pas', () {
      expect(
        _amounts(
          PayrollDeductionResolver.resolve(
            [_type('a', defaultAmount: 500, currency: 'usd')],
            [_entry('A', 900)],
            'USD',
          ),
        ),
        {'a': 900},
      );
    });
  });
}
