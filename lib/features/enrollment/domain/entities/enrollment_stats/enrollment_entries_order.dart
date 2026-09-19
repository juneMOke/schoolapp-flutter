/// L'ordre de lecture de la liste nominative — **et il n'est plus le même pour
/// la table et pour son document**.
///
/// Le serveur offre les deux sens chronologiques et laisse le choix au client,
/// sans jamais le déduire de la largeur de la fenêtre : un ordre qui
/// basculerait tout seul entre « jour » et « année » changerait sans que
/// personne l'ait demandé. Ce tri-là est `(createdAt, id)` dans le sens
/// choisi, donc **total** : aucune ligne ne peut s'afficher deux fois ni
/// disparaître d'une page à l'autre.
///
/// ⚠ [byName] est offert **au seul document**. Le passer à la table paginée
/// vaut un 400 : trier des noms demande une collation que Postgres et H2 ne
/// rendent pas à l'identique, et le serveur ne s'y risque qu'en mémoire, sur
/// les lignes qu'il charge d'un bloc sous son plafond. Une page de huit lignes
/// ne le peut pas.
enum EnrollmentEntriesOrder {
  /// L'ordre du guichet : celui où les dossiers ont été enregistrés.
  oldestFirst('oldest'),

  /// Les derniers arrivés en tête.
  newestFirst('newest'),

  /// L'alphabet, sur nom puis post-nom puis prénom, casse et accents ignorés.
  /// **Document seulement** — voir l'avertissement ci-dessus.
  byName('name');

  /// Valeur du paramètre `sort`.
  final String apiValue;

  const EnrollmentEntriesOrder(this.apiValue);

  /// L'ordre de la **table** du tableau de bord, posé en un seul endroit.
  ///
  /// Ce que la table montrait déjà sur une journée : l'écran sert à voir ce
  /// qui vient d'arriver.
  ///
  /// Explicite plutôt que laissé au défaut du serveur, que son contrôleur
  /// annonce lui-même comme « pas arrêté » : un défaut qui bouge côté serveur
  /// ne doit pas retourner la table en silence.
  static const EnrollmentEntriesOrder dashboard = oldestFirst;

  /// L'ordre du **registre imprimé**, et il diffère de celui de la table.
  ///
  /// Un registre sur papier se pointe sur un nom — on y cherche un élève, pas
  /// un instant de saisie — et lui seul porte l'index par initiale, que le
  /// serveur ne pose que sur une liste rangée. Se superposer ligne pour ligne
  /// à l'écran avait sa logique tant que le document n'était qu'une copie de
  /// la table ; retrouver quelqu'un sur douze pages en a une autre, et c'est
  /// celle-là qu'on sert.
  ///
  /// C'est aussi ce que le serveur applique par défaut sur ce document depuis
  /// que son contrat a changé. On le demande tout de même, pour la raison qui
  /// vaut au-dessus : un défaut qui bouge ne doit rien retourner en silence.
  static const EnrollmentEntriesOrder document = byName;
}
