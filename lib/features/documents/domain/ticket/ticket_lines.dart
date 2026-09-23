import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// Une ligne de **perçu** : ce qui est entré dans le tiroir, dans son unité.
///
/// Complémentaire de [TicketAllocationLine], et dans l'autre devise. Une
/// imputation éteint une créance, donc elle est en devise de créance ; un
/// tender décrit une pile de billets, donc il est en devise reçue. [rateMicros]
/// est le seul nombre qui relie les deux, et il est **gelé** au versement.
class TicketTenderLine extends Equatable {
  /// Le net conservé, jamais le montant présenté.
  final int amountInCents;

  /// La devise reçue.
  final String currency;

  /// Le taux appliqué, en micro-unités. `1 000 000` = perçu et imputé dans la
  /// même unité, ce qui est le cas courant et tout l'historique.
  final int rateMicros;

  /// La devise de la créance contre laquelle ce taux s'applique.
  final String pivotCurrency;

  const TicketTenderLine({
    required this.amountInCents,
    required this.currency,
    this.rateMicros = ExchangeRate.scale,
    required this.pivotCurrency,
  });

  /// Les lignes de perçu d'un versement réglé **dans la devise de la créance** :
  /// une par devise, taux 1.
  ///
  /// C'est le cas courant, et tout l'historique d'avant la V2 — la forme que le
  /// backfill de la v41 écrit en base. Elle ne coûte aucune arithmétique et
  /// n'imprime aucun taux.
  static List<TicketTenderLine> identityFrom(MoneyBag bag) => [
    for (final amount in bag.entries)
      TicketTenderLine(
        amountInCents: amount.amountInCents,
        currency: amount.currency,
        pivotCurrency: amount.currency,
      ),
  ];

  /// Vrai quand cette ligne ne fait que redire l'imputation — le ticket
  /// n'imprime alors **aucun taux** : un « 1,00 » sur un papier de guichet ferait
  /// chercher au parent ce qui a été converti.
  bool get isIdentity =>
      rateMicros == ExchangeRate.scale && currency == pivotCurrency;

  ExchangeRate get rate => ExchangeRate.parse(
    base: pivotCurrency,
    quote: currency,
    rateMicros: rateMicros,
    effectiveFrom: DateTime.utc(1970),
  );

  Money get amount => Money.parse(amountInCents, currency);

  @override
  List<Object?> get props => [
    amountInCents,
    currency,
    rateMicros,
    pivotCurrency,
  ];
}

/// Une ligne de répartition du versement (zone Z5).
class TicketAllocationLine extends Equatable {
  final String label;
  final int amountInCents;

  /// La devise de CETTE imputation : elle solde une créance, donc elle en tient
  /// exactement une. Scalaire, définitivement.
  final String currency;

  const TicketAllocationLine({
    required this.label,
    required this.amountInCents,
    required this.currency,
  });

  @override
  List<Object?> get props => [label, amountInCents, currency];
}
