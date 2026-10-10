/// Les entrées d'outbox du journal : un seul agrégat, un identifiant d'entrée
/// **déterministe** — une saisie remplace la précédente encore en attente
/// pour la même séance, qui n'attend donc jamais qu'une fois.
abstract final class JournalOutbox {
  static const String type = 'JOURNAL_ENTRY';

  static String entry(String journalEntryId) => '$type:$journalEntryId';
}
