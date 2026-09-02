import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';

/// Modèle de la table `payment_tenders` (append-only) — ce qui est **entré dans
/// le tiroir** pour un versement.
///
/// Sœur de `PaymentAllocationLocalModel`, et son exact complémentaire :
/// l'imputation dit ce qui a été éteint, dans la devise de la créance ; le
/// tender dit ce qui a été reçu, dans la devise reçue.
class PaymentTenderLocalModel {
  final String id;
  final String clientUuid;
  final String paymentId;

  /// Le **net conservé**, jamais le montant présenté : 120 000 tendus,
  /// 5 000 rendus, on écrit 115 000. Sans cette règle, le total de caisse ne
  /// retombe jamais sur le comptage du tiroir.
  final int amountInCents;

  /// La devise **reçue**.
  final String currency;

  /// Le taux de guichet gelé, en micro-unités. `1 000 000` = taux 1, le cas où
  /// perçu et imputé se confondent.
  final int rateMicros;

  /// La devise de la **créance** contre laquelle ce taux s'applique.
  final String pivotCurrency;

  const PaymentTenderLocalModel({
    required this.id,
    required this.clientUuid,
    required this.paymentId,
    required this.amountInCents,
    required this.currency,
    this.rateMicros = ExchangeRate.scale,
    required this.pivotCurrency,
  });

  /// La ligne d'identité : perçu = imputé, taux 1.
  ///
  /// C'est ce que porte tout l'historique, et ce qu'écrit le guichet tant que le
  /// parent règle dans la devise de la créance — c'est-à-dire le cas courant.
  factory PaymentTenderLocalModel.identity({
    required String id,
    required String clientUuid,
    required String paymentId,
    required Money amount,
  }) {
    final currency = CurrencyCode.normalize(amount.currency);
    return PaymentTenderLocalModel(
      id: id,
      clientUuid: clientUuid,
      paymentId: paymentId,
      amountInCents: amount.amountInCents,
      currency: currency,
      pivotCurrency: currency,
    );
  }

  /// Vrai quand cette ligne ne fait que redire l'imputation.
  bool get isIdentity =>
      rateMicros == ExchangeRate.scale && currency == pivotCurrency;

  /// Le montant reçu, comme argent.
  Money get amount => Money(amountInCents, currency);

  /// Le taux appliqué, comme objet valeur — pour convertir les imputations de
  /// ce pivot en devise reçue.
  ExchangeRate get rate => ExchangeRate(
    base: pivotCurrency,
    quote: currency,
    rateMicros: rateMicros,
    // Le taux d'un tender est GELÉ au versement : il ne se re-résout pas, donc
    // sa date d'effet n'a plus de rôle une fois la ligne écrite.
    effectiveFrom: DateTime.utc(1970),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'client_uuid': clientUuid,
    'payment_id': paymentId,
    'amount_in_cents': amountInCents,
    'currency': currency,
    'rate_micros': rateMicros,
    'pivot_currency': pivotCurrency,
  };

  /// Colonnes dont le PULL est autoritaire.
  ///
  /// **Exclut `client_uuid`**, comme l'imputation : c'est une clé d'idempotence
  /// locale, le serveur n'en a pas connaissance et l'écraser romprait le lien
  /// avec l'entrée d'outbox qui a poussé ce versement.
  Map<String, Object?> toPullPatch() => {
    'payment_id': paymentId,
    'amount_in_cents': amountInCents,
    'currency': currency,
    'rate_micros': rateMicros,
    'pivot_currency': pivotCurrency,
  };

  /// Relit une ligne, y compris écrite par une version antérieure.
  ///
  /// `rate_micros` retombe sur le taux 1 s'il manque, et `pivot_currency` sur la
  /// devise reçue : c'est l'identité, c'est-à-dire ce que valait tout
  /// encaissement avant la V2. Refuser la ligne ferait disparaître de l'argent
  /// déjà encaissé d'une lecture qui ne remonte jamais d'erreur.
  factory PaymentTenderLocalModel.fromMap(Map<String, Object?> m) {
    final currency = CurrencyCode.normalize((m['currency'] as String?) ?? '');
    final pivot = CurrencyCode.normalize(
      (m['pivot_currency'] as String?) ?? '',
    );
    final micros = (m['rate_micros'] as num?)?.toInt() ?? ExchangeRate.scale;
    return PaymentTenderLocalModel(
      id: (m['id'] as String?) ?? '',
      clientUuid: (m['client_uuid'] as String?) ?? '',
      paymentId: (m['payment_id'] as String?) ?? '',
      amountInCents: (m['amount_in_cents'] as num?)?.toInt() ?? 0,
      currency: currency,
      rateMicros: micros <= 0 ? ExchangeRate.scale : micros,
      pivotCurrency: pivot.isEmpty ? currency : pivot,
    );
  }
}
