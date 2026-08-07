/// Conversion epoch-ms ↔ ISO-8601 (UTC) pour les horloges métier offline.
///
/// Le local stocke les timestamps en **epoch ms** (INTEGER sqflite) ; le wire les
/// veut en **date-time ISO-8601** (`clientUpdatedAt`, `createdAt`, `serverUpdatedAt`).
/// Le round-trip est exact à la milliseconde. Parsing **tolérant** au pull
/// (valeur nulle/illisible → `null`) — jamais d'exception (anti poison-page).
class EpochIsoHelper {
  const EpochIsoHelper._();

  /// epoch ms → ISO-8601 UTC (`2026-07-18T09:41:12.000Z`).
  static String toIso(int epochMs) => DateTime.fromMillisecondsSinceEpoch(
    epochMs,
    isUtc: true,
  ).toIso8601String();

  /// ISO-8601 → epoch ms, **tolérant** : `null` si absent/illisible.
  static int? tryToEpochMs(Object? iso) {
    if (iso == null) return null;
    final parsed = DateTime.tryParse(iso.toString());
    return parsed?.millisecondsSinceEpoch;
  }
}
