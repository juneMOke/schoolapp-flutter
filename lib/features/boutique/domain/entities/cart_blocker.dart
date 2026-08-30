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

  /// Le panier mêle deux devises.
  ///
  /// ## Un blocage TEMPORAIRE, et qui se lèvera
  ///
  /// La révision 4 du contrat tranche l'inverse : une vente mixte sera **un
  /// acte de caisse, une vente, un reçu** — `sale.amounts[]` remplace le
  /// scalaire, et `currency` devient obligatoire sur chaque ligne. Imposer deux
  /// gestes au caissier serait « laisser le schéma dicter le métier », dit le
  /// back.
  ///
  /// Mais ce contrat n'est **pas encore fusionné**. Avec celui d'aujourd'hui,
  /// la vente ne porte qu'un `totalInCents` scalaire, et l'invariant serveur
  /// (`totalInCents == Σ lineTotalInCents`) est satisfait *numériquement* par la
  /// somme brute de deux unités : le serveur scellerait, sans rien signaler, un
  /// ticket dont le total ne veut rien dire. Un ticket scellé ne se corrige pas.
  ///
  /// ⇒ Ce blocage tient la place jusqu'au lot « caisse multi-devise », qui le
  /// retire dans le commit même où il ouvre le contrat.
  mixedCurrency,
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
