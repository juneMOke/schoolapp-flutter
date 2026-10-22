import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_family_amount.dart';

/// Miroir d'une entrée de `families[]`.
class BoutiqueFamilyAmountModel {
  /// La valeur servie (`UNIFORME`…), gardée telle quelle : une famille inconnue
  /// de ce client doit survivre au cache, pas devenir `null` à l'écriture.
  final String family;
  final int amount;
  final int quantity;

  const BoutiqueFamilyAmountModel({
    required this.family,
    required this.amount,
    required this.quantity,
  });

  factory BoutiqueFamilyAmountModel.fromJson(Map<String, dynamic> json) =>
      BoutiqueFamilyAmountModel(
        family: (json['family'] as String?) ?? '',
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'family': family,
    'amount': amount,
    'quantity': quantity,
  };

  BoutiqueFamilyAmount toEntity() => BoutiqueFamilyAmount(
    family: ArticleFamily.fromWire(family),
    amount: amount,
    quantity: quantity,
  );
}
