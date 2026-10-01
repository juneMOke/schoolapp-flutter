import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_day.dart';

/// Pourquoi un geste sur l'appel d'un jour est refusé.
enum ClassDayLock {
  /// Le compte ne fait pas l'appel (`attendance.write`).
  forbidden,

  /// Le mois est clôturé : rien ne s'y modifie, justification comprise.
  monthClosed,

  /// L'appel est validé : le rouvrir d'abord.
  validated,

  /// Un jour passé ne se corrige qu'avec `attendance.amend` : appel validé
  /// qu'on ne peut pas rouvrir, ou appel rouvert qu'on ne pourrait pas
  /// revalider (le serveur le refuserait en 403, terminal).
  needsAmend,
}

/// La règle unique du verrou d'une journée, lue par l'écran (pour annoncer
/// avant d'ouvrir une modale) et par les commandes (avant d'écrire).
///
/// [justifying] : poser ou retirer une justification sur un appel validé
/// ne demande pas de le rouvrir (décision 9). Mais un jour passé exige
/// `attendance.amend`, justification comprise : le motif porte le verdict
/// justifiée / injustifiée, et le serveur garde ce geste (plan back,
/// correction 3) — sans le droit, l'envoi prendrait un 403 terminal.
ClassDayLock? classDayLock(
  ClassPresenceDay day, {
  required String today,
  required bool canWrite,
  required bool canAmend,
  bool justifying = false,
}) {
  if (!canWrite) return ClassDayLock.forbidden;
  if (day.monthClosed) return ClassDayLock.monthClosed;
  final past = day.day.compareTo(today) < 0;
  if (day.validated) {
    if (past && !canAmend) return ClassDayLock.needsAmend;
    return justifying ? null : ClassDayLock.validated;
  }
  if (day.reopened && past && !canAmend) return ClassDayLock.needsAmend;
  return null;
}
