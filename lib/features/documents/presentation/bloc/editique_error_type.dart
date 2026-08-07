/// Familles d'erreur d'une émission de pièce, telles que l'UI doit les traiter.
///
/// Conforme à la convention du projet : aucune `Failure` ne traverse l'état
/// d'un BLoC — chaque module réduit les `Failure` du socle à son propre enum,
/// puis le traduit dans une extension l10n dédiée.
enum EditiqueErrorType {
  /// Aucune connexion, ou requête qui n'a jamais atteint le serveur. Rien n'a
  /// pu être produit : un nouvel essai est toujours sans risque.
  network,

  /// La requête est partie et son sort est **inconnu** : le serveur a pu
  /// produire la pièce et consommer son numéro.
  ///
  /// C'est le seul cas où réessayer peut fabriquer un doublon. Sur une pièce
  /// non archivée, l'action de reprise doit disparaître.
  uncertain,

  /// Session expirée (401).
  sessionExpired,

  /// Droits insuffisants (403). Ne propose jamais de réessayer.
  forbidden,

  /// La ressource n'existe pas côté serveur (404) : dossier, paiement ou élève
  /// inconnu, ou aucune créance sur l'année.
  notFound,

  /// Règle métier ou paramètre refusé (400/422).
  invalid,

  /// Erreur serveur (5xx) ou réponse inexploitable.
  server,
}
