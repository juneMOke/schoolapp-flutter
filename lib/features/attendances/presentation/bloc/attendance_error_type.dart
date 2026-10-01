/// Le type d'erreur d'affichage des écrans de présence, que l'anatomie
/// d'erreur partagée (`AttendanceResultsErrorState`) traduit en 4 états.
enum AttendanceErrorType {
  none,
  network,
  notFound,
  validation,
  unauthorized,
  // 403 (acces refuse) : produit par `UnauthorizedFailure` (HTTP 403),
  // affiche par l'anatomie d'erreur partagee.
  forbidden,
  invalidCredentials,
  server,
  storage,
  auth,
  unknown,
}
