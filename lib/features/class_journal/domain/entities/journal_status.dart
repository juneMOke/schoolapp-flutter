/// Où en est une séance du journal, vue du professeur.
enum JournalStatus {
  /// Objectif et contenu remplis.
  filled,

  /// Pas encore remplie, le jour n'est pas passé.
  toPrepare,

  /// Pas remplie, et le jour est passé.
  missing,

  /// Le serveur a refusé la dernière saisie : elle est à corriger.
  rejected,
}
