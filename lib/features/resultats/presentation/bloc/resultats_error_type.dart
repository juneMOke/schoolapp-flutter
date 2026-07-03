/// Type d'erreur exposé au UI pour le module **résultats par classe**.
///
/// Identique à `CoursNotationErrorType` (convention projet) : **pas** de
/// `conflict` car cette feature est 100 % lecture (aucune écriture, aucun 409).
/// Partagé par les trois BLoCs (vue classe, vue focus, recherche « Par élève »).
/// Alimente l'anatomie d'erreur (network / auth401 / auth403 / server500).
enum ResultatsErrorType {
  none,
  network,
  notFound,
  validation,
  // HTTP 403 -> UnauthorizedFailure -> forbidden (convention projet). Pas de
  // valeur `unauthorized` : elle ne serait jamais émise par les BLoCs.
  forbidden,
  invalidCredentials,
  server,
  storage,
  auth,
  unknown,
}
