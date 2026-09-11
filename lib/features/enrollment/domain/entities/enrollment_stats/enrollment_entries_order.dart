/// L'ordre de lecture de la liste nominative — **un seul pour la table et
/// pour son document**.
///
/// Le serveur offre les deux sens et laisse le choix au client, sans jamais le
/// déduire de la largeur de la fenêtre : un ordre qui basculerait tout seul
/// entre « jour » et « année » changerait sans que personne l'ait demandé.
///
/// Le tri est `(createdAt, id)` dans le sens choisi, donc **total** : aucune
/// ligne ne peut s'afficher deux fois ni disparaître d'une page à l'autre.
enum EnrollmentEntriesOrder {
  /// L'ordre du registre : celui où le guichet a enregistré les dossiers.
  oldestFirst('oldest'),

  /// Les derniers arrivés en tête.
  newestFirst('newest');

  /// Valeur du paramètre `sort`.
  final String apiValue;

  const EnrollmentEntriesOrder(this.apiValue);

  /// L'ordre du tableau de bord **et** de son PDF, posé en un seul endroit.
  ///
  /// Le document doit se superposer ligne pour ligne à la table qu'on vient
  /// de lire : deux ordres différents feraient chercher en vain, sur la
  /// feuille, la ligne vue à l'écran. Le registre plutôt que l'aperçu — c'est
  /// ce que la table montrait déjà sur une journée, et l'ordre dans lequel une
  /// direction pointe un registre imprimé.
  ///
  /// Explicite plutôt que laissé au défaut du serveur, que son contrôleur
  /// annonce lui-même comme « pas arrêté » : un défaut qui bouge côté serveur
  /// ne doit pas retourner la table en silence.
  static const EnrollmentEntriesOrder dashboard = oldestFirst;
}
