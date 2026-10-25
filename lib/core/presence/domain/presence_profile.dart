/// Le profil de présence d'une personne sur un mois ou une année — une couleur
/// qui résume ses jours pointés (spec RH · Présences §11).
///
/// Le serveur l'évalue et la tablette le lit : les seuils (10 % d'absences ou
/// 3 non justifiées, 15 % de retards, 97 % de présence et 5 % de retards au
/// plus) sont des constantes serveur, communes à toutes les écoles.
///
/// L'ordre des valeurs est celui de l'évaluation : la première règle qui
/// s'applique gagne.
enum PresenceProfile {
  /// Aucun jour pointé sur la période.
  notEvaluated('NON_EVALUE'),
  absentee('ABSENTEISTE'),
  late('RETARDATAIRE'),
  exemplary('EXEMPLAIRE'),
  regular('REGULIER');

  const PresenceProfile(this.wire);

  /// La valeur sur le fil.
  final String wire;

  /// Lit une valeur du fil. Une valeur inconnue — un profil ajouté côté
  /// serveur avant la tablette — se lit « non évalué » plutôt que de faire
  /// tomber la liste entière.
  static PresenceProfile fromWire(String? value) {
    for (final profile in values) {
      if (profile.wire == value) return profile;
    }
    return notEvaluated;
  }
}
