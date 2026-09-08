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

  /// Le nombre de reçus **ayant alimenté cette caisse**.
  ///
  /// ⚠️ **Ce n'est pas le compteur global**, et la nuance n'est pas une
  /// subtilité comptable. Un reçu compte **une fois par caisse qu'il a
  /// alimentée** : un versement payé moitié en francs, moitié en dollars entre
  /// dans les deux. La somme des compteurs par caisse dépasse donc
  /// [FinanceTill.receiptsIssued] dès qu'un panier est mixte — « 40 $ + 35 FC »
  /// au-dessus de « 70 reçus émis » a raison deux fois et paraît faux, d'où le
  /// sous-titre de la tuile neutre qui doit l'annoncer.
  ///
  /// C'est **ce compteur-ci** qui est le dénominateur du ticket moyen : diviser
  /// par un compteur qui ignore les paniers mixtes fausserait le chiffre.
  final int receiptCount;

  /// Le ticket moyen, en centimes — `total / receiptCount`, **calculé serveur**,
  /// `0` quand aucun reçu n'a alimenté la caisse.
  ///
  /// Lu et jamais recalculé : refaire la division ici rouvrirait la division par
  /// zéro que le serveur a déjà fermée, et ferait diverger deux arrondis pour le
  /// même chiffre.
  final int averageTicket;

  /// L'écart à la période précédente de même durée, en pourcentage entier.
  ///
  /// **`null` veut dire « carte masquée », jamais « 0 % »** — c'est le cas où la
  /// période précédente était vide, et où le pourcentage vaudrait « +∞ ». La
  /// tuile se tait au lieu de mentir ; afficher zéro annoncerait une stabilité
  /// qui n'a pas été observée.
  final int? trendPercent;

  const TillSummary({
    required this.total,
    required this.fees,
    required this.boutique,
    required this.receiptCount,
    required this.averageTicket,
    this.trendPercent,
  });

  /// La tendance a été mesurée : la période précédente n'était pas vide.
  bool get hasTrend => trendPercent != null;

  /// Aucun reçu n'a alimenté cette caisse — donc pas de ticket moyen à afficher.
  /// La sous-ligne le tait plutôt que d'écrire « ticket moyen 0 ».
  bool get hasNoReceipts => receiptCount == 0;

  @override
  List<Object?> get props => [
    total,
    fees,
    boutique,
    receiptCount,
    averageTicket,
    trendPercent,
  ];
}
