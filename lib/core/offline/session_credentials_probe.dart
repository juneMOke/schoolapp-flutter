/// Sonde de crédentiels de session pour la boucle de synchro (V1.1).
///
/// Une session ouverte OFFLINE peut être **sans jetons** (logout préalable sans
/// consigne, purge d'identité croisée sur tablette partagée, consigne brûlée
/// par une révocation). Dans cet état, chaque flush partirait sans
/// `Authorization` → 401 systématique → `attempts++` sur des écritures qui
/// n'ont aucune chance de partir, jusqu'au poison `SYNC_ERROR` — y compris
/// l'argent. La boucle de synchro sonde donc les crédentiels AVANT de flusher
/// (et de puller) : sans jetons utilisables, elle ne tente rien et surface
/// « Reconnexion requise » à la place.
///
/// Implémentée par `AuthSessionManager` (même patron que `RevocationEvaluator`
/// — le socle core reste découplé de features/auth).
abstract interface class SessionCredentialsProbe {
  /// Vrai si la session courante peut authentifier des appels API : access
  /// token non vide, OU refresh token **actif** présent (l'interceptor de
  /// refresh mintera un access au premier 401). La consigne ne compte PAS :
  /// elle est verrouillée tant que son propriétaire n'a pas re-prouvé son
  /// mot de passe.
  Future<bool> canAuthenticate();
}
