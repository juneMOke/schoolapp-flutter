import 'package:equatable/equatable.dart';

class PaymentAllocation extends Equatable {
  final String id;
  final String paymentId;
  final String studentChargeId;
  final String feeCode;
  final String studentChargeLabel;
  final int amountInCents;
  final String currency;

  /// Identité du payeur et date du versement porteur de cette imputation
  /// (détail d'un frais §16). Repliés depuis le paiement joint : la source
  /// online (backend) ne les porte pas encore → valeurs par défaut vides /
  /// nulles, l'UI retombe alors sur « valeur inconnue ».
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;

  /// Numéro du payeur (v28), même repli et même réserve que ci-dessus : la
  /// source online ne le porte pas encore, il est alors nul.
  final String? payerPhoneNumber;
  final DateTime? paidAt;

  /// Code de la ligne de grille sur laquelle l'argent a été reçu (v39).
  ///
  /// Composé à la lecture locale par jointure sur la grille ; nul sur le chemin
  /// online pur, que le serveur ne sert pas encore. Le LIBELLÉ, lui, reste celui
  /// gelé à l'encaissement.
  final String? feeTariffCode;

  const PaymentAllocation({
    required this.id,
    required this.paymentId,
    required this.studentChargeId,
    required this.feeCode,
    required this.studentChargeLabel,
    required this.amountInCents,
    required this.currency,
    this.payerFirstName = '',
    this.payerLastName = '',
    this.payerMiddleName,
    this.payerPhoneNumber,
    this.paidAt,
    this.feeTariffCode,
  });

  @override
  List<Object?> get props => [
    id,
    paymentId,
    studentChargeId,
    feeCode,
    studentChargeLabel,
    amountInCents,
    currency,
    payerFirstName,
    payerLastName,
    payerMiddleName,
    payerPhoneNumber,
    paidAt,
    feeTariffCode,
  ];
}
