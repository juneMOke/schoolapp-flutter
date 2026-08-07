/// Ré-authentification **silencieuse** avant tout trafic authentifié (ADR-010).
///
/// Une session ouverte OFFLINE arrive au retour réseau avec un access token
/// vide (déconsignation) ou périmé (le TTL access se compte en heures, la
/// coupure en jours). Sans cette étape, c'est la première requête métier qui
/// porte la ré-authentification : elle part avec un jeton mort, se prend un
/// 401 — ou un 403 si une couche intermédiaire répond avant l'API — et
/// consomme une tentative d'outbox au passage. Multiplié par la file entière,
/// cela empoisonne des écritures (`SYNC_ERROR`) qui n'ont jamais pu partir.
///
/// La boucle de synchro demande donc explicitement un access exploitable AVANT
/// de flusher et de puller. Sur échec, elle ne tente RIEN : la session reste
/// ouverte (l'utilisateur ne quitte pas son écran), les écritures restent en
/// file, et le cycle suivant retentera.
///
/// Implémentée côté `features/auth` (même patron que [SessionCredentialsProbe]
/// et `RevocationEvaluator` — le socle `core/offline` reste découplé de l'auth).
abstract interface class SessionReauthenticator {
  /// Garantit un access token exploitable pour les appels qui suivent.
  ///
  /// Retourne `true` si un access valide est déjà en place ou vient d'être
  /// minté ; `false` si le mint a échoué — l'appelant doit alors s'abstenir de
  /// tout appel authentifié. **Ne détruit jamais la session** : le verdict de
  /// révocation appartient au refresher (401 du contrat) et au guardian.
  Future<bool> ensureFreshAccess();
}
