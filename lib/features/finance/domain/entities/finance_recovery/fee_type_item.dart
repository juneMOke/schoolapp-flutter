import 'package:equatable/equatable.dart';

/// Une ligne de la répartition par poste de frais — les mêmes quatre chiffres
/// que [FinanceKpis], un cran plus fin, et le libellé du poste.
class FeeTypeItem extends Equatable {
  final String code;

  /// Le libellé **français de la nature** du frais (« Minerval » pour
  /// `TUITION`), tel que le serveur l'envoie.
  ///
  /// Il voyage avec le code pour que chaque client cesse de tenir sa propre
  /// table de vingt-trois traductions — elles divergent à la première nature
  /// ajoutée. Ce n'est pas le libellé que la direction a rédigé pour les
  /// parents : celui-là vit sur le tarif.
  ///
  /// Jamais vide : le mapping retombe sur le code si le serveur n'envoie rien.
  final String label;

  /// Encaissé sur ce poste, en centimes. Peut **dépasser** [expected] — c'est
  /// un arriéré d'un autre exercice qui se solde — sans que le taux franchisse
  /// 100.
  final int collected;

  final int expected;

  /// Ce qui reste dû sur ce poste, plancherisé créance par créance.
  ///
  /// C'est lui qui rend la ligne lisible quand [collected] dépasse [expected] :
  /// sans lui, l'écran montre un encaissé supérieur à l'attendu à côté d'une
  /// barre aux deux tiers, et rien n'explique l'écart.
  final int outstanding;

  final int collectionRate;

  const FeeTypeItem({
    required this.code,
    required this.label,
    required this.collected,
    required this.expected,
    required this.outstanding,
    required this.collectionRate,
  });

  /// Voir [FinanceKpis.hasNoExpectation] : même règle, même tiret à l'écran.
  bool get hasNoExpectation => expected == 0;

  @override
  List<Object?> get props => [
    code,
    label,
    collected,
    expected,
    outstanding,
    collectionRate,
  ];
}
