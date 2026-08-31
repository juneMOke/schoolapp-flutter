/// Les quatre fenêtres de l'historique de caisse.
///
/// **Calendaires, ancrées sur aujourd'hui** — jamais glissantes. Un caissier
/// rapproche sa caisse d'un arrêté : « la semaine » veut dire celle qu'il est en
/// train de vivre, du lundi à maintenant, et non les sept derniers jours, qui ne
/// correspondent à aucun document.
enum SalesHistoryPeriod {
  /// Depuis minuit — le défaut : ce qu'on vérifie, c'est la caisse du jour.
  day,

  /// Depuis le lundi de la semaine en cours.
  week,

  /// Depuis le 1er du mois en cours.
  month,

  /// Depuis le 1er janvier de l'année civile en cours.
  ///
  /// L'exercice académique borne déjà la lecture par-dessus : cette fenêtre est
  /// la plus large, jamais la plus juste.
  year;

  /// Le premier instant de la fenêtre, **en heure locale**.
  ///
  /// L'heure locale, et non UTC : « aujourd'hui » est le jour du guichet. Une
  /// vente de 21 h à Kinshasa tombe le lendemain en UTC, et la compter dans la
  /// caisse de demain ferait mentir l'arrêté du soir.
  DateTime startOf(DateTime now) {
    final midnight = DateTime(now.year, now.month, now.day);
    return switch (this) {
      SalesHistoryPeriod.day => midnight,
      // `weekday` vaut 1 le lundi : le retrancher ramène au lundi de la semaine
      // en cours, y compris le lundi lui-même (0 jour retranché).
      SalesHistoryPeriod.week => midnight.subtract(
        Duration(days: now.weekday - DateTime.monday),
      ),
      SalesHistoryPeriod.month => DateTime(now.year, now.month),
      SalesHistoryPeriod.year => DateTime(now.year),
    };
  }

  /// La borne telle que le SQL doit la comparer à `sold_at`.
  ///
  /// ⚠️ **Tronquée à la seconde, sans suffixe.** `sold_at` mélange deux formats :
  /// l'écriture locale produit `...T11:42:00.000Z`, le delta serveur descend
  /// `...T11:42:00Z`. Or `'.'` (0x2E) est INFÉRIEUR à `'Z'` (0x5A) : une borne
  /// écrite `...T00:00:00Z` exclurait une vente locale de minuit pile, et une
  /// borne `...T00:00:00.000Z` en exclurait une du serveur. Un préfixe de 19
  /// caractères est plus petit que les deux, et reste exploitable par l'index —
  /// c'est une comparaison de préfixe, pas une fonction sur la colonne.
  String boundFor(DateTime now) =>
      startOf(now).toUtc().toIso8601String().substring(0, 19);
}
