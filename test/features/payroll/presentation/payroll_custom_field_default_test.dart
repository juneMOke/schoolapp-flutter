import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_variables_custom.dart';

const _cards = PayrollDeductionType(
  id: 'a',
  code: 'CARTE',
  label: 'Cartes',
  currency: 'USD',
  defaultAmountInCents: 1000,
  sortOrder: 10,
);

PayrollDeductionEntry _entry(
  int amount, {
  String currency = 'USD',
  RecordSyncState state = RecordSyncState.synced,
}) => PayrollDeductionEntry(
  staffMemberId: 'm-1',
  deductionTypeId: 'a',
  amountInCents: amount,
  currency: currency,
  syncState: state,
);

void main() {
  PayrollCustomField field(
    PayrollDeductionEntry? entry, {
    String currency = 'USD',
  }) => PayrollCustomField.of(_cards, entry, currency);

  test('sans saisie, le champ s\'ouvre sur le défaut et n\'écrit rien', () {
    final input = field(null);

    expect(input.amountInCents, 1000);
    expect(input.defaultInCents, 1000);
    expect(input.changed('m-1'), isNull);
  });

  test('changer le montant écrit une saisie', () {
    final input = field(null)..controller.text = '25';

    expect(input.changed('m-1')!.amountInCents, 2500);
  });

  test('vider le champ écrit un 0, qui écarte le défaut', () {
    final input = field(null)..controller.text = '';

    expect(input.changed('m-1')!.amountInCents, 0);
    expect(input.preview('m-1').amountInCents, 0);
  });

  test('un 0 déjà saisi se montre, et ne repart pas', () {
    final input = field(_entry(0));

    expect(input.controller.text, '0');
    expect(input.changed('m-1'), isNull);
  });

  test('une saisie égale au défaut reste une saisie', () {
    final input = field(_entry(1000));

    expect(input.changed('m-1'), isNull);
    expect(input.preview('m-1').amountInCents, 1000);
  });

  test('retaper le défaut fige le montant pour cet agent', () {
    final input = field(null)..controller.text = '10';

    expect(input.changed('m-1')!.amountInCents, 1000);
  });

  test('une saisie d\'une autre devise n\'est pas effacée sans geste', () {
    final sameType = field(_entry(500, currency: 'CDF'));
    final otherLine = field(_entry(700), currency: 'CDF');

    expect(sameType.controller.text, isEmpty);
    expect(sameType.changed('m-1'), isNull);
    expect(otherLine.changed('m-1'), isNull);
  });

  test(
    'une rubrique refusée et inconnue du serveur ne rouvre pas son défaut',
    () {
      const refused = PayrollDeductionType(
        id: 'a',
        code: 'CARTE',
        label: 'Cartes',
        currency: 'USD',
        defaultAmountInCents: 1000,
        sortOrder: 10,
        syncState: RecordSyncState.failed,
      );

      final input = PayrollCustomField.of(refused, null, 'USD');

      expect(input.amountInCents, 0);
      expect(input.defaultInCents, isNull);
    },
  );

  test('une saisie refusée sans valeur serveur rouvre le défaut', () {
    final input = field(_entry(5000, state: RecordSyncState.failed));

    expect(input.amountInCents, 1000);
    expect(input.changed('m-1'), isNull);
  });

  group('agent d\'une autre devise', () {
    test('la rubrique n\'apparaît pas', () {
      expect(PayrollCustomField.shown(_cards, null, 'CDF'), isFalse);
      expect(PayrollCustomField.shown(_cards, null, 'USD'), isTrue);
    });

    test('un montant resté se montre, et ne se retire qu\'à 0', () {
      final stale = _entry(500);

      expect(PayrollCustomField.shown(_cards, stale, 'CDF'), isTrue);
      final input = field(stale, currency: 'CDF');
      expect(input.locked, isTrue);
      expect(input.defaultInCents, isNull);

      input.clear();

      expect(input.changed('m-1')!.amountInCents, 0);
    });
  });

  test('une archivée ne rouvre pas son défaut', () {
    const archived = PayrollDeductionType(
      id: 'a',
      label: 'Cartes',
      currency: 'USD',
      defaultAmountInCents: 1000,
      sortOrder: 10,
      archived: true,
    );

    expect(PayrollCustomField.shown(archived, null, 'USD'), isFalse);
    expect(PayrollCustomField.of(archived, null, 'USD').amountInCents, 0);
  });
}
