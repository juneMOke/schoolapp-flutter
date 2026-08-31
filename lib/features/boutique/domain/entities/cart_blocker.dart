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
  /// on ne reproche pas au guichet de n'avoir pas nommé le payeur d'une vente
  /// qui n'existe pas encore.
  emptyCart,

  missingLastName,
  missingMiddleName,
  missingFirstName,

  /// Téléphone absent.
  missingPhone,

  /// Téléphone entamé mais trop court. Distinct de [missingPhone] : « vous
  /// n'avez pas fini » n'est pas « vous n'avez rien mis », et le second
  /// reprocherait au guichet de n'avoir pas commencé ce qu'il est en train de
  /// taper.
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
