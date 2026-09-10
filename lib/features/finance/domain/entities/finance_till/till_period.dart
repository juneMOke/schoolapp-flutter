/// La fenêtre que la caisse totalise.
///
/// **Le jour par défaut** — c'est la question qu'on pose le soir, à la
/// fermeture. Les trois autres grains répondent à la même question sur une
/// fenêtre plus large ; aucun ne demande d'attendu, puisque tout y est déjà
/// encaissé.
///
/// ⚠️ **`custom` ne se demande jamais seul** : il exige deux bornes, et le
/// serveur refuse en 400 une fenêtre libre sans elles — comme il refuse des
/// bornes posées sur une autre période. C'est `TillWindow` qui rend ces
/// requêtes inconstructibles ; cet enum ne porte que le nom du grain.
///
/// ## Pourquoi cet enum ne descend pas dans `core/entities/stats_period.dart`
///
/// Le socle partage déjà `StatsPeriod { year, month, week }` entre les modules
/// de statistiques, et un TODO y invitait la finance à s'y ranger. **Ce TODO
/// est caduc.** `day` n'existe que pour la caisse : le serveur l'a
/// délibérément tenu hors du jeu de valeurs par défaut de son parseur, parce
/// que les stats d'inscriptions et de présences l'auraient accepté puis répondu
/// n'importe quoi, faute d'unité de compte à la journée. Factoriser ici
/// rouvrirait exactement ce que le serveur vient de fermer.
enum TillPeriod { day, week, month, year, custom }

extension TillPeriodX on TillPeriod {
  /// La valeur envoyée en query. Toute autre part en **400**, jamais en repli
  /// silencieux sur le défaut.
  String get apiValue => switch (this) {
    TillPeriod.day => 'day',
    TillPeriod.week => 'week',
    TillPeriod.month => 'month',
    TillPeriod.year => 'year',
    TillPeriod.custom => 'custom',
  };
}
