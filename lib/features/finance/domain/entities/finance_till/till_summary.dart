import 'package:equatable/equatable.dart';

/// Ce qui est entré en caisse sur la fenêtre, dans une devise **reçue**.
///
/// **[total] vaut toujours `fees + boutique`**, par construction : les deux
/// moitiés sont comptées sur la même fenêtre d'instants et dans le même fuseau.
/// C'est l'invariant que l'écran affiche, et le seul que le caissier puisse
/// vérifier contre son tiroir.
///
/// ⚠️ **La ventilation par nature de frais ne vit plus ici.** Elle relève de
/// l'imputation — donc de la devise de la **créance** — et depuis qu'un parent
/// règle 50 USD en tendant 115 000 FC, les deux ne se comptent plus dans la
/// même unité. Les empiler dans ce résumé donnait un total qui ne retombait pas
/// sur la somme des lignes affichées dessous.
class TillSummary extends Equatable {
  final int total;

  /// Les frais scolaires encaissés, en centimes, **en devise reçue** : lus sur
  /// les lignes d'encaissement, pas sur les imputations. Grouper sur la devise
  /// de la créance faisait annoncer « 50 USD encaissés » un jour où le tiroir
  /// n'avait vu que des francs.
  final int fees;

  /// Les ventes boutique, en centimes — datées de leur **temps métier**
  /// (`sold_at`) : une vente saisie hors ligne lundi et synchronisée mercredi
  /// appartient à la caisse de lundi.
  ///
  /// C'est le seul chiffre réellement neuf à l'écran, et la raison d'être de
  /// cet onglet : un uniforme payé comptant est de l'argent reçu au même
  /// guichet, dans le même tiroir, le même jour.
  final int boutique;

  const TillSummary({
    required this.total,
    required this.fees,
    required this.boutique,
  });

  @override
  List<Object?> get props => [total, fees, boutique];
}
