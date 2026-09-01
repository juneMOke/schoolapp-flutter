import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_fee_code_amount.dart';

/// Ce qui est entré en caisse sur la fenêtre, dans une devise.
///
/// **[total] vaut toujours `fees + boutique`**, par construction : les deux
/// moitiés sont comptées sur la même fenêtre d'instants et dans le même fuseau.
/// C'est l'invariant que l'écran affiche, et le seul que le caissier puisse
/// vérifier contre son tiroir.
class TillSummary extends Equatable {
  final int total;

  /// Les frais scolaires encaissés, en centimes.
  final int fees;

  /// Les ventes boutique, en centimes — datées de leur **temps métier**
  /// (`sold_at`) : une vente saisie hors ligne lundi et synchronisée mercredi
  /// appartient à la caisse de lundi.
  ///
  /// C'est le seul chiffre réellement neuf à l'écran, et la raison d'être de
  /// cet onglet : un uniforme payé comptant est de l'argent reçu au même
  /// guichet, dans le même tiroir, le même jour.
  final int boutique;

  /// La ventilation de la moitié **frais uniquement**, triée par montant
  /// décroissant.
  ///
  /// ⚠️ La somme des [TillFeeCodeAmount.amount] vaut [fees], **jamais**
  /// [total] : une vente boutique n'est imputée sur aucune créance, elle n'a
  /// donc aucun poste de frais, et sa contribution reste entière dans
  /// [boutique].
  final List<TillFeeCodeAmount> byFeeCode;

  const TillSummary({
    required this.total,
    required this.fees,
    required this.boutique,
    required this.byFeeCode,
  });

  @override
  List<Object?> get props => [total, fees, boutique, byFeeCode];
}
