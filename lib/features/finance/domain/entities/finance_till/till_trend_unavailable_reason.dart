/// Pourquoi une caisse n'a **pas** de tendance à afficher.
///
/// Les deux cas se ressemblent dans la charge utile — `trendPercent` vaut `null`
/// dans les deux — et se lisent très différemment à l'écran :
///
/// * [beforeSchoolYear] est une **limite de la mesure**. Il n'existe pas de
///   période comparable parce qu'elle tomberait avant la rentrée, et le serveur
///   refuse de comparer deux campagnes de frais. L'écran le **dit** : sinon, en
///   septembre, la tuile perd son delta tous les jours sans raison visible et
///   quelqu'un finit par ouvrir un ticket.
/// * [previousPeriodEmpty] est un **fait de la période regardée**. La période
///   précédente existe et n'a rien encaissé. L'écran se **tait** : « +∞ % »
///   serait faux, « 0 % » annoncerait une stabilité que personne n'a observée,
///   et une phrase expliquerait une absence qui se comprend d'elle-même.
///
/// Le serveur nomme la cause ; **il n'écrit pas la phrase**. Une chaîne rendue
/// là-bas serait intraduisible et intestable.
enum TillTrendUnavailableReason {
  beforeSchoolYear,
  previousPeriodEmpty;

  /// La valeur du fil, ou `null` — **jamais un repli**.
  ///
  /// Une valeur inconnue rend `null`, donc « pas de raison connue », donc la
  /// tuile se tait : c'est le comportement d'avant ce champ, et le bon défaut si
  /// le serveur ajoute un jour une troisième cause que cet écran ne sait pas
  /// formuler. Retomber sur [beforeSchoolYear] ferait afficher une explication
  /// fausse.
  static TillTrendUnavailableReason? fromWire(String? raw) => switch (raw
      ?.trim()
      .toUpperCase()) {
    'BEFORE_SCHOOL_YEAR' => TillTrendUnavailableReason.beforeSchoolYear,
    'PREVIOUS_PERIOD_EMPTY' => TillTrendUnavailableReason.previousPeriodEmpty,
    _ => null,
  };

  /// La valeur du fil, pour le chemin retour.
  String get wireValue => switch (this) {
    TillTrendUnavailableReason.beforeSchoolYear => 'BEFORE_SCHOOL_YEAR',
    TillTrendUnavailableReason.previousPeriodEmpty => 'PREVIOUS_PERIOD_EMPTY',
  };
}
