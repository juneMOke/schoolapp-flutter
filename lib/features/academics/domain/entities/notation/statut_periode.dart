/// Statut d'ouverture d'une période ou sous-période scolaire.
///
/// `unknown` est un repli de résilience : si le backend renvoie une valeur
/// absente ou inconnue, l'entité retombe dessus plutôt que de planter.
enum StatutPeriode { ouverte, cloturee, unknown }

extension StatutPeriodeX on StatutPeriode {
  static StatutPeriode fromApiValue(String? value) =>
      switch (value?.toUpperCase()) {
        'OUVERTE' => StatutPeriode.ouverte,
        'CLOTUREE' => StatutPeriode.cloturee,
        _ => StatutPeriode.unknown,
      };

  String toApiValue() => switch (this) {
    StatutPeriode.ouverte => 'OUVERTE',
    StatutPeriode.cloturee => 'CLOTUREE',
    StatutPeriode.unknown => 'UNKNOWN',
  };
}
