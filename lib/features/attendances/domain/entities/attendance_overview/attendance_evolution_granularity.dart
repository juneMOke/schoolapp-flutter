/// Granularite des "buckets" de l'evolution du taux de presence.
///
/// `month` pour une periode annuelle, `week` pour une periode mensuelle,
/// `day` pour une periode hebdomadaire (cf. champ `granularity` du backend).
enum AttendanceEvolutionGranularity { month, week, day }

extension AttendanceEvolutionGranularityX on AttendanceEvolutionGranularity {
  /// Parse la valeur backend. Retombe sur `month` pour une valeur inconnue.
  static AttendanceEvolutionGranularity fromApiValue(String? value) =>
      switch (value?.toLowerCase()) {
        'week' => AttendanceEvolutionGranularity.week,
        'day' => AttendanceEvolutionGranularity.day,
        _ => AttendanceEvolutionGranularity.month,
      };
}
