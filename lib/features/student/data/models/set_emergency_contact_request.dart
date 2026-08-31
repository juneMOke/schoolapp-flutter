/// Désignation du tuteur à appeler en urgence pour un élève.
///
/// [parentId] est délibérément **facultatif** : à `null`, la requête retire la
/// désignation sans en poser d'autre. Un corps plutôt qu'un paramètre d'URL
/// parce que « aucun contact » doit pouvoir s'exprimer aussi explicitement
/// qu'une désignation — un paramètre absent, lui, ne se distingue pas d'un
/// oubli.
class SetEmergencyContactRequest {
  final String? parentId;

  const SetEmergencyContactRequest(this.parentId);

  Map<String, dynamic> toJson() => <String, dynamic>{'parentId': parentId};
}
