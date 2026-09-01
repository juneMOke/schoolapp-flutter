import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/models/payment_tender_local_model.dart';

/// `payment_tenders` — ce qui est entré dans le tiroir.
///
/// Le modèle doit relire des lignes écrites par une version ANTÉRIEURE : la
/// table naît avec le taux et le pivot, mais une lecture ne remonte jamais
/// d'erreur, et refuser une ligne ferait disparaître de l'argent déjà encaissé.
void main() {
  group('identity — le cas courant', () {
    test('perçu = imputé, taux 1, même devise des deux côtés', () {
      final tender = PaymentTenderLocalModel.identity(
        id: 'tnd-1',
        clientUuid: 'tnd-1',
        paymentId: 'pay-1',
        amount: const Money(3000, 'USD'),
      );

      expect(tender.amountInCents, 3000);
      expect(tender.currency, 'USD');
      expect(tender.pivotCurrency, 'USD');
      expect(tender.rateMicros, ExchangeRate.scale);
      expect(tender.isIdentity, isTrue);
    });

    test('la devise est normalisée des deux côtés', () {
      final tender = PaymentTenderLocalModel.identity(
        id: 'tnd-1',
        clientUuid: 'tnd-1',
        paymentId: 'pay-1',
        amount: Money.parse(3000, ' usd '),
      );

      expect(tender.currency, 'USD');
      expect(tender.pivotCurrency, 'USD');
    });
  });

  group('isIdentity', () {
    test(
      'un règlement en francs sur une créance en dollars n’en est pas un',
      () {
        const tender = PaymentTenderLocalModel(
          id: 'tnd-1',
          clientUuid: 'tnd-1',
          paymentId: 'pay-1',
          amountInCents: 5000010,
          currency: 'CDF',
          rateMicros: 1666670000,
          pivotCurrency: 'USD',
        );

        expect(tender.isIdentity, isFalse);
      },
    );

    test('un taux de 1 entre deux devises différentes n’en est pas un', () {
      // Un dollar contre un franc au taux de 1 est une saisie fausse, pas le
      // cas courant.
      const tender = PaymentTenderLocalModel(
        id: 'tnd-1',
        clientUuid: 'tnd-1',
        paymentId: 'pay-1',
        amountInCents: 3000,
        currency: 'CDF',
        pivotCurrency: 'USD',
      );

      expect(tender.isIdentity, isFalse);
    });
  });

  group('rate — le taux gelé, prêt à convertir', () {
    test('convertit une imputation en devise reçue', () {
      const tender = PaymentTenderLocalModel(
        id: 'tnd-1',
        clientUuid: 'tnd-1',
        paymentId: 'pay-1',
        amountInCents: 5000010,
        currency: 'CDF',
        rateMicros: 1666670000,
        pivotCurrency: 'USD',
      );

      // 30,00 $ imputés valent 50 000,10 FC — et c'est bien ce que le tiroir a
      // reçu, à l'unité d'affichage près.
      expect(ExchangeRates.convertCents(3000, tender.rate), 5000010);
      expect(tender.rate.base, 'USD');
      expect(tender.rate.quote, 'CDF');
    });
  });

  group('fromMap — relire ce qu’une autre version a écrit', () {
    test('une ligne complète se relit telle quelle', () {
      final tender = PaymentTenderLocalModel.fromMap(const {
        'id': 'tnd-1',
        'client_uuid': 'cli-1',
        'payment_id': 'pay-1',
        'amount_in_cents': 5000010,
        'currency': 'CDF',
        'rate_micros': 1666670000,
        'pivot_currency': 'USD',
      });

      expect(tender.rateMicros, 1666670000);
      expect(tender.pivotCurrency, 'USD');
    });

    test('un taux absent retombe sur l’identité, pas sur zéro', () {
      // Zéro diviserait de l'argent. L'identité est ce que valait tout
      // encaissement avant la V2.
      final tender = PaymentTenderLocalModel.fromMap(const {
        'id': 'tnd-1',
        'client_uuid': 'cli-1',
        'payment_id': 'pay-1',
        'amount_in_cents': 3000,
        'currency': 'USD',
      });

      expect(tender.rateMicros, ExchangeRate.scale);
      expect(tender.pivotCurrency, 'USD');
      expect(tender.isIdentity, isTrue);
    });

    test('un taux nul ou négatif retombe aussi sur l’identité', () {
      for (final micros in const [0, -5]) {
        final tender = PaymentTenderLocalModel.fromMap({
          'id': 'tnd-1',
          'client_uuid': 'cli-1',
          'payment_id': 'pay-1',
          'amount_in_cents': 3000,
          'currency': 'USD',
          'rate_micros': micros,
        });
        expect(tender.rateMicros, ExchangeRate.scale);
      }
    });

    test('les devises se normalisent à la relecture', () {
      final tender = PaymentTenderLocalModel.fromMap(const {
        'id': 'tnd-1',
        'client_uuid': 'cli-1',
        'payment_id': 'pay-1',
        'amount_in_cents': 3000,
        'currency': ' cdf ',
        'pivot_currency': 'usd',
      });

      expect(tender.currency, 'CDF');
      expect(tender.pivotCurrency, 'USD');
    });
  });

  group('toPullPatch', () {
    test('n’écrase jamais la clé d’idempotence locale', () {
      // Le serveur ne connaît pas `client_uuid` : l'écraser romprait le lien
      // avec l'entrée d'outbox qui a poussé ce versement.
      const tender = PaymentTenderLocalModel(
        id: 'tnd-1',
        clientUuid: 'cli-1',
        paymentId: 'pay-1',
        amountInCents: 3000,
        currency: 'USD',
        pivotCurrency: 'USD',
      );

      expect(tender.toPullPatch().containsKey('client_uuid'), isFalse);
      expect(tender.toPullPatch()['amount_in_cents'], 3000);
    });
  });

  test('toMap round-trip', () {
    const tender = PaymentTenderLocalModel(
      id: 'tnd-1',
      clientUuid: 'cli-1',
      paymentId: 'pay-1',
      amountInCents: 5000010,
      currency: 'CDF',
      rateMicros: 1666670000,
      pivotCurrency: 'USD',
    );

    final relu = PaymentTenderLocalModel.fromMap(tender.toMap());

    expect(relu.id, tender.id);
    expect(relu.clientUuid, tender.clientUuid);
    expect(relu.amountInCents, tender.amountInCents);
    expect(relu.rateMicros, tender.rateMicros);
    expect(relu.pivotCurrency, tender.pivotCurrency);
  });
}
