/// Jour d'ouverture de l'emploi du temps (grille hebdomadaire récurrente,
/// LUN→SAM).
///
/// La sérialisation wire est en majuscules (`MON`..`SAT`). [WeekdayX.fromWire]
/// retombe sur [Weekday.mon] pour toute valeur absente ou inconnue — repli de
/// résilience cohérent avec les autres enums du domaine (cf. `TypeEvaluation`,
/// `StatutPeriode`).
enum Weekday { mon, tue, wed, thu, fri, sat }

extension WeekdayX on Weekday {
  /// Valeur wire majuscule (`MON`..`SAT`).
  String get wire => name.toUpperCase();

  /// Reconstruit un [Weekday] depuis sa valeur wire (insensible à la casse).
  ///
  /// Repli sur [Weekday.mon] si la valeur est absente ou inconnue.
  static Weekday fromWire(String? value) => Weekday.values.firstWhere(
    (d) => d.wire == (value ?? '').toUpperCase(),
    orElse: () => Weekday.mon,
  );
}
