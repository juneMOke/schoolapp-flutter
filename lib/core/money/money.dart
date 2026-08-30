import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';

/// Un montant et sa devise — le schéma `Money` de la spec.
///
/// C'est la brique de tout ce qui porte de l'argent depuis la rupture
/// multi-devise : un versement, un solde, un indicateur. Seule une **imputation**
/// garde encore ses deux champs séparés, parce qu'elle ne vise qu'une créance,
/// donc qu'une devise.
class Money extends Equatable {
  /// Toujours des centimes entiers. Un `double` qui traverserait la couche
  /// métier finirait par arrondir de l'argent.
  final int amountInCents;

  /// Code ISO en majuscules.
  ///
  /// **Peut être vide**, et ce n'est pas une anomalie à corriger ici : le
  /// grand-livre local porte des lignes dont la devise n'a jamais été
  /// renseignée, et une lecture ne remonte jamais d'erreur. La mise en forme
  /// escamote alors le suffixe, comme elle le faisait déjà.
  final String currency;

  /// Montant dont la devise est **déjà canonique**.
  ///
  /// Aux frontières — JSON, SQL, saisie — passer par [Money.parse], qui
  /// normalise. Ce constructeur reste `const` pour que les fixtures et le code
  /// interne, où la devise est écrite à la main, ne paient pas ce détour.
  const Money(this.amountInCents, this.currency);

  /// Montant venu d'une frontière : la devise y est normalisée.
  factory Money.parse(int amountInCents, String currency) =>
      Money(amountInCents, CurrencyCode.normalize(currency));

  /// Vrai quand il n'y a rien dans cette devise — ce qui n'est **pas** la même
  /// chose qu'un sac vide (cf. `MoneyBag`).
  bool get isZero => amountInCents == 0;

  @override
  List<Object?> get props => [amountInCents, currency];

  @override
  String toString() => 'Money($amountInCents $currency)';
}
