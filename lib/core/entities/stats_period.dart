/// Periode d'agregation des statistiques, partagee par les modules de stats.
///
/// Factorisee ici (au lieu d'un enum par module) car la meme notion
/// `year | month | week` est utilisee par attendance-stats, et a terme par
/// finance-stats / enrollment-stats (cf. TODO de migration dans le README).
enum StatsPeriod { year, month, week }

extension StatsPeriodX on StatsPeriod {
  /// Valeur envoyee au backend (query `period`).
  String get apiValue => switch (this) {
    StatsPeriod.year => 'year',
    StatsPeriod.month => 'month',
    StatsPeriod.week => 'week',
  };

  /// Parse la valeur backend (champ `period` d'une reponse de stats).
  /// Retombe sur `year` pour une valeur absente ou inconnue.
  static StatsPeriod fromApiValue(String? value) =>
      switch (value?.toLowerCase()) {
        'month' => StatsPeriod.month,
        'week' => StatsPeriod.week,
        _ => StatsPeriod.year,
      };
}
