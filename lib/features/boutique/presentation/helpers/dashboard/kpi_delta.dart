/// L'évolution d'un chiffre contre la période précédente : « +11 % », « −3 % ».
///
/// `null` quand elle n'a pas de sens — et alors l'écran ne montre rien plutôt
/// qu'un « +∞ % » :
///  - précédent nul : rien à quoi se comparer ;
///  - fenêtre précédente qui chevauche la rentrée : quelques jours se
///    compareraient à une semaine pleine.
abstract final class KpiDelta {
  static String? of(int? current, int? previous, {bool comparable = true}) {
    if (!comparable || current == null || previous == null || previous == 0) {
      return null;
    }
    final percent = ((current - previous) / previous * 100).round();
    // Le vrai signe moins (U+2212), pas le trait d'union : il a la largeur du
    // plus, et les chiffres tabulaires restent alignés.
    return percent >= 0 ? '+$percent %' : '−${percent.abs()} %';
  }

  /// Vrai pour une baisse — l'écran la teinte autrement.
  static bool isDown(int? current, int? previous) =>
      current != null && previous != null && current < previous;
}
