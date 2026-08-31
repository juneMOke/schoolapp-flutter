import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/core/money/money.dart';

part 'money_model.g.dart';

/// Miroir du schéma `Money` de la spec : un montant, dans une devise.
///
/// `currency` reste une **chaîne**, jamais une enum générée. Le serveur ferme
/// la liste, mais une enum stricte côté client ferait échouer la
/// désérialisation d'un lot entier le jour où une devise s'ajoute — de l'argent
/// déjà encaissé, invisible. On normalise à la sortie, on ne rejette jamais.
@JsonSerializable()
class MoneyModel {
  final int amountInCents;
  final String currency;

  const MoneyModel({required this.amountInCents, required this.currency});

  factory MoneyModel.fromJson(Map<String, dynamic> json) =>
      _$MoneyModelFromJson(json);

  Map<String, dynamic> toJson() => _$MoneyModelToJson(this);

  factory MoneyModel.fromEntity(Money money) =>
      MoneyModel(amountInCents: money.amountInCents, currency: money.currency);

  Money toEntity() => Money.parse(amountInCents, currency);
}
