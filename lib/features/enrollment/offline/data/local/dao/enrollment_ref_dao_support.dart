// Primitives partagées par les DAO de pull Inscription (référentiel / seed /
// réconciliation), issues du découpage de l'ancien `EnrollmentRefDao`.

/// Placeholders `?, ?, …` pour une clause `IN (...)`, dimensionnés sur [args].
String sqlMarks(List<Object?> args) => List.filled(args.length, '?').join(', ');

/// ISO-8601 serveur → epoch ms, **tolérant** : une valeur absente ou malformée
/// retombe sur [fallback] au lieu de lever `FormatException`. Sans cette garde,
/// un seul horodatage serveur invalide ferait échouer l'apply de TOUTE la page
/// de pull — et comme le curseur `sync_meta` n'avance qu'après un apply réussi,
/// la même page empoisonnée serait re-demandée puis re-rejetée à chaque cycle,
/// **figeant définitivement (et en silence) la ressource** (cf. revue #21).
int isoToEpochMillis(String iso, {required int fallback}) =>
    DateTime.tryParse(iso)?.millisecondsSinceEpoch ?? fallback;
