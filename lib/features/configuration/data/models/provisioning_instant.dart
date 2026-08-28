/// Sérialisation des instants du module Configuration.
///
/// **Deux routes, deux formats, pour la même notion.** `dueAt` est un instant
/// UTC sur `POST /provisioning/apply` — suffixe `Z` obligatoire, sans lui le
/// corps est illisible et l'appel rend 400 — et un `LocalDateTime` sur
/// `POST /finance/tariffs`, où le même suffixe est interdit. C'est une dette de
/// contrat côté serveur, assumée et non corrigée.
///
/// Les deux conversions vivent ici, nommées, plutôt que recopiées à chaque
/// appel : c'est la seule façon de rendre l'asymétrie visible au lieu de la
/// laisser se propager en copies presque identiques.
class ProvisioningInstant {
  const ProvisioningInstant._();

  /// Format de `POST /provisioning/apply` : instant UTC, suffixe `Z`.
  ///
  /// Rendu à la seconde et sans fraction : c'est ce que la spécification montre
  /// (`2027-06-30T23:59:59Z`), et une précision qu'on n'a pas ne se feint pas.
  static String toUtcInstant(DateTime value) {
    final utc = value.toUtc();
    return '${_datePart(utc)}T${_timePart(utc)}Z';
  }

  /// Format de `POST·PUT /finance/tariffs` : date-heure locale, **sans `Z`**.
  ///
  /// Le serveur y attend un `LocalDateTime` : le suffixe le ferait échouer.
  static String toLocalDateTime(DateTime value) {
    final utc = value.toUtc();
    return '${_datePart(utc)}T${_timePart(utc)}';
  }

  /// Lit un instant servi, quelle que soit sa forme.
  ///
  /// Tolérant par nécessité : les deux routes ci-dessus rendent l'une avec `Z`,
  /// l'autre sans, et la lecture ne doit pas avoir à savoir laquelle a répondu.
  /// Une valeur illisible rend `null` plutôt que de faire échouer tout un plan.
  static DateTime? parse(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim())?.toLocal();
  }

  /// Fin de journée d'une date de calendrier, en instant UTC.
  ///
  /// L'échéance se saisit en jour (« 30/06/2027 ») et s'entend jusqu'au bout de
  /// ce jour : la ramener à minuit ferait expirer un frais une journée trop tôt.
  static DateTime endOfDayUtc(DateTime day) =>
      DateTime.utc(day.year, day.month, day.day, 23, 59, 59);

  /// Début de journée d'une date de calendrier, en instant UTC.
  static DateTime startOfDayUtc(DateTime day) =>
      DateTime.utc(day.year, day.month, day.day);

  static String _datePart(DateTime utc) =>
      '${utc.year.toString().padLeft(4, '0')}-'
      '${utc.month.toString().padLeft(2, '0')}-'
      '${utc.day.toString().padLeft(2, '0')}';

  static String _timePart(DateTime utc) =>
      '${utc.hour.toString().padLeft(2, '0')}:'
      '${utc.minute.toString().padLeft(2, '0')}:'
      '${utc.second.toString().padLeft(2, '0')}';
}
