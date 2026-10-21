import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';

/// Ce qu'une famille du catalogue a vendu sur la fenêtre, dans une devise.
class BoutiqueFamilyAmount extends Equatable {
  /// `null` : famille servie par un serveur plus récent que ce client. Elle
  /// reste comptée — son argent est réel — mais s'affiche en neutre.
  final ArticleFamily? family;

  /// En centimes.
  final int amount;

  /// Σ des quantités.
  final int quantity;

  const BoutiqueFamilyAmount({
    required this.family,
    required this.amount,
    required this.quantity,
  });

  BoutiqueFamilyAmount plus({required int amount, required int quantity}) =>
      BoutiqueFamilyAmount(
        family: family,
        amount: this.amount + amount,
        quantity: this.quantity + quantity,
      );

  @override
  List<Object?> get props => [family, amount, quantity];
}
