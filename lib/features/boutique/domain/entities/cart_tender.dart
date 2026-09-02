import 'package:equatable/equatable.dart';

/// Comment le client règle **une devise du panier**.
///
/// La question se pose par devise de catalogue, pas par article : un panier qui
/// mêle des uniformes en dollars et des manuels en francs pose deux fois la
/// question, et une seule fois par unité. C'est la transposition exacte du
/// guichet, où elle se pose frais par frais — dans les deux cas, sur le montant
/// dû, là où la réponse a un sens.
class CartTender extends Equatable {
  /// La devise réellement posée au comptoir. Vide = celle du catalogue, c'est-à-
  /// dire le cas courant, qui ne coûte rien.
  final String currency;

  /// Ce qui est **tendu**, en centimes de [currency]. `null` = le montant
  /// converti exact, qui est le défaut.
  ///
  /// Saisi seulement quand le client pose une somme ronde : l'écart devient de
  /// la monnaie à rendre, jamais un trop-perçu.
  final int? tenderedCents;

  const CartTender({this.currency = '', this.tenderedCents});

  /// Vrai quand cette part du panier change d'unité.
  bool isConvertedFrom(String catalogCurrency) =>
      currency.isNotEmpty && currency != catalogCurrency;

  CartTender copyWith({
    String? currency,
    int? tenderedCents,
    bool clearTendered = false,
  }) => CartTender(
    currency: currency ?? this.currency,
    tenderedCents: clearTendered ? null : (tenderedCents ?? this.tenderedCents),
  );

  @override
  List<Object?> get props => [currency, tenderedCents];
}
