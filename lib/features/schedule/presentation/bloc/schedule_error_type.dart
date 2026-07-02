/// Type d'erreur exposé au UI pour le module emploi du temps.
///
/// Identique à `CoursNotationErrorType` (convention projet), **plus** [conflict]
/// pour le HTTP 409 des écritures (double-booking enseignant ou classe). Partagé
/// par le BLoC de lecture ([TimetableBloc]) et d'écriture ([ScheduleEditBloc]).
enum ScheduleErrorType {
  none,
  network,
  notFound,
  validation,
  // HTTP 403 -> UnauthorizedFailure -> forbidden (convention projet). Pas de
  // valeur `unauthorized` : elle ne serait jamais émise par les BLoCs.
  forbidden,
  invalidCredentials,
  // HTTP 409 -> ConflictFailure -> conflict (écritures uniquement).
  conflict,
  server,
  storage,
  auth,
  unknown,
}
