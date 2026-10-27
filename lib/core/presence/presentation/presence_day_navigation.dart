/// Ce qu'un registre du jour sait faire de ses jours — le Pointage du
/// personnel et l'appel d'une classe l'implémentent par leur cubit, pour que
/// les gestes de jour (`PresenceRegisterDayActions`) s'écrivent une fois.
abstract interface class PresenceDayNavigation {
  /// Le jour affiché, `YYYY-MM-DD`.
  String get shownDay;

  /// Le premier jour montrable (la rentrée) ; `null` quand il est inconnu.
  String? get firstShownDay;

  /// Le dernier jour montrable : le dernier jour ouvré jusqu'à aujourd'hui.
  String get lastShownDay;

  /// Le jour ouvré précédent (-1) ou suivant (1).
  Future<void> stepDay(int direction);

  /// Le dernier jour ouvré.
  Future<void> goToday();

  /// Un jour choisi ; un week-end ramène au vendredi d'avant.
  Future<void> showDay(String day);

  /// Le registre filtré sur les seuls « à pointer » : recherche et autres
  /// filtres levés, pour qu'on y trouve tous ceux qu'une alerte vient de
  /// nommer.
  void showOnlyUnmarked();
}
