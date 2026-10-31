import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/domain/receipt_emission_day.dart';

/// Le back sert le jour d'émission comme une DATE à minuit UTC (réponse du
/// 2026-10-30) : il se lit tel quel, jamais converti en heure locale.
void main() {
  group('fromIso', () {
    test('minuit UTC garde son jour', () {
      expect(ReceiptEmissionDay.fromIso('2026-10-27T00:00:00Z'), '2026-10-27');
      expect(
        ReceiptEmissionDay.fromIso('2026-10-27T00:00:00.000Z'),
        '2026-10-27',
      );
    });

    test('une date sans fuseau garde ses chiffres', () {
      expect(ReceiptEmissionDay.fromIso('2026-10-27'), '2026-10-27');
    });

    test('un décalage ne fait pas reculer le jour', () {
      expect(
        ReceiptEmissionDay.fromIso('2026-10-27T00:00:00+01:00'),
        '2026-10-27',
      );
    });

    test('un nombre ou un jour impossible vaut une absence', () {
      expect(ReceiptEmissionDay.fromIso(1793059200000), isNull);
      expect(ReceiptEmissionDay.fromIso('2026-02-30'), isNull);
    });

    test('absent ou illisible : null', () {
      expect(ReceiptEmissionDay.fromIso(null), isNull);
      expect(ReceiptEmissionDay.fromIso('  '), isNull);
      expect(ReceiptEmissionDay.fromIso('demain'), isNull);
    });
  });

  test('fromEpochMs relit l époch du cache en UTC', () {
    final ms = DateTime.utc(2026, 10, 27).millisecondsSinceEpoch;

    expect(ReceiptEmissionDay.fromEpochMs(ms), '2026-10-27');
    expect(ReceiptEmissionDay.fromEpochMs(null), isNull);
  });

  test('toDate rend la date sans heure', () {
    expect(ReceiptEmissionDay.toDate('2026-10-27'), DateTime(2026, 10, 27));
    expect(ReceiptEmissionDay.toDate(null), isNull);
    expect(ReceiptEmissionDay.toDate('n/a'), isNull);
  });
}
