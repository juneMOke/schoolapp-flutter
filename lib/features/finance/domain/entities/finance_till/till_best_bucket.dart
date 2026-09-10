import 'package:equatable/equatable.dart';

/// L'intervalle le plus fort de la série, et sa part de **ce qui est dessiné**.
///
/// ## Pourquoi la part ne se rapporte pas à la fenêtre comptée
///
/// Les deux diffèrent sur `day`, où la série trace **sept jours** pour une seule
/// journée comptée. Rapporter le meilleur jour au total d'une seule journée
/// donnerait **100 % à chaque fois**, et la carte cesserait de rien dire. La
/// part se lit donc « ce jour-là a fait 75 % de ce que la semaine a vu » —
/// c'est le serveur qui la calcule, sur la somme des barres, et l'écran ne la
/// recalcule jamais.
///
/// ## Absent vaut masqué
///
/// Le serveur rend `null` quand rien n'est entré : une caisse creuse n'a pas de
/// meilleur jour, et en désigner un ferait lire une pointe là où il n'y a rien.
/// **Même doctrine que `trendPercent`** — la carte disparaît au lieu de mentir.
class TillBestBucket extends Equatable {
  /// La clé de l'intervalle, dans la même forme que celle d'une barre :
  /// `YYYY-MM-DD` sur un axe de journées, `YYYY-MM` sur l'axe annuel.
  final String key;

  /// Le total de cet intervalle, en centimes, dans la devise du bloc.
  final int amount;

  /// Part de l'intervalle dans **la somme des barres dessinées**, en pourcentage
  /// entier. Ne jamais en dériver un montant : l'arrondi entier ne retombe pas
  /// sur les centimes.
  final int sharePercent;

  const TillBestBucket({
    required this.key,
    required this.amount,
    required this.sharePercent,
  });

  @override
  List<Object?> get props => [key, amount, sharePercent];
}
