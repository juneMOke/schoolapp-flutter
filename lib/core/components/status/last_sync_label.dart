import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Depuis combien de temps la tablette et le serveur se sont parlé.
///
/// « À l'instant », « Il y a 12 min », « Il y a 3 h », « Il y a 2 jours ».
///
/// [lastSyncAtMs] est une estampille en **heure serveur** ; l'écoulé se mesure
/// contre l'horloge de l'appareil. Mélanger deux horloges ne pose pas de
/// problème ici parce qu'on ne **date** rien : on mesure une durée, et son
/// signe est borné à zéro — l'horloge serveur peut être en avance sur celle
/// d'une tablette restée hors ligne, et un écoulé négatif se lirait « à
/// l'instant » indéfiniment.
///
/// Rend `null` si aucune synchro n'est connue ; l'appelant décide alors quoi
/// dire — une pastille se tait, un total de caisse annonce « jamais
/// synchronisé ».
///
/// ⚠️ **Cette estampille date le *pull*, pas le *push*.** Elle n'avance que
/// sur un cycle de lecture qui a ramené des données : un envoi réussi il y a
/// deux minutes peut coexister avec un « Il y a 3 h ». L'écart va toujours dans
/// le sens **prudent** — on annonce des chiffres plus vieux qu'ils ne sont,
/// jamais plus frais.
String? relativeLastSyncLabel(
  AppLocalizations l10n,
  int? lastSyncAtMs, {
  DateTime Function()? now,
}) {
  if (lastSyncAtMs == null) return null;

  final currentMs = (now?.call() ?? DateTime.now()).millisecondsSinceEpoch;
  final rawElapsed = currentMs - lastSyncAtMs;
  final elapsed = rawElapsed < 0 ? 0 : rawElapsed;

  if (elapsed < Duration.millisecondsPerMinute) {
    return l10n.syncLastSyncJustNow;
  }
  if (elapsed < Duration.millisecondsPerHour) {
    return l10n.syncLastSyncMinutesAgo(
      elapsed ~/ Duration.millisecondsPerMinute,
    );
  }
  if (elapsed < Duration.millisecondsPerDay) {
    return l10n.syncLastSyncHoursAgo(elapsed ~/ Duration.millisecondsPerHour);
  }
  return l10n.syncLastSyncDaysAgo(elapsed ~/ Duration.millisecondsPerDay);
}
