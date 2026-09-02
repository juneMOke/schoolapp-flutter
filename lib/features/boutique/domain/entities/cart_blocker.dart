import 'package:equatable/equatable.dart';

/// Ce qui empêche d'encaisser, **nommé**.
///
/// Le bouton d'encaissement n'est jamais un bouton grisé muet : quand il est
/// inactif, le pied dit exactement ce qui manque, dans l'ordre où l'utilisateur
/// peut le corriger.
///
/// **Aucune chaîne ici.** Le domaine décide *ce* qui manque et dans quel ordre ;
/// la présentation traduit. Un libellé posé ici échapperait à `AppLocalizations`
/// et ne se traduirait jamais.
enum CartBlockerKind {
  /// Panier vide. **Seul** : quand il est là, les autres manques sont muets —
  /// on ne reproche pas au guichet un numéro inachevé sur une vente qui n'existe
  /// pas encore.
  emptyCart,

  /// Téléphone entamé mais trop court.
  ///
  /// **Le seul manque de payeur qui bloque encore.** Depuis la V114 serveur,
  /// l'identité entière est facultative : une vente au comptant remet sa
  /// contrepartie sur-le-champ, et exiger un nom pour encaisser un cahier
  /// faisait taper « X » au guichet. Mais un numéro à moitié tapé n'est pas une
  /// absence, c'est une faute de frappe — et c'est la clé de rapprochement du
  /// répertoire, donc ce qui rendrait ce payeur introuvable demain.
  ///
  /// « Vous n'avez pas fini » n'est pas « vous n'avez rien mis » : ne rien
  /// mettre est désormais un choix, qu'on ne reproche plus.
  incompletePhone,

  /// n lignes dont le prix n'est pas résolu, faute de niveau.
  linesWithoutLevel,
}

/// Un manque, et ce qu'il faut pour l'énoncer.
class CartBlocker extends Equatable {
  final CartBlockerKind kind;

  /// Nombre d'éléments concernés — seul [CartBlockerKind.linesWithoutLevel]
  /// l'utilise (« 1 ligne sans niveau » / « 3 lignes sans niveau »).
  final int count;

  const CartBlocker(this.kind, {this.count = 1});

  @override
  List<Object?> get props => [kind, count];
}
