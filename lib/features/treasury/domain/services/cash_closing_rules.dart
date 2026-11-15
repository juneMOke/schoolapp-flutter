import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';

/// Pourquoi « Clôturer la caisse » n'est pas offert, dans l'ordre où l'écran
/// le dit : la première raison trouvée est celle qu'on montre.
enum ClosingBlock {
  /// Un jour passé ou futur : on ne clôture qu'aujourd'hui (R9).
  notToday,

  /// Déjà clôturée aujourd'hui.
  closed,

  /// Ni caissière ni promoteur (`treasury.close`).
  noRight,

  /// La clôture est impossible hors ligne (D2).
  offline,

  /// Des opérations d'argent du jour attendent encore d'être envoyées (D2).
  pendingSync,

  /// Des lignes arrivées après une clôture attendent leur réponse (R19).
  pendingAfterClosure,
}

/// La réponse de la caissière à « Avez-vous bien {reste} dans la caisse ? ».
enum ClosingAnswer { matches, differs }

/// Les règles de la clôture (R9, R15, R19), sans Flutter. Le serveur applique
/// les mêmes et fait foi ; l'écran s'en sert pour activer ses boutons.
abstract final class CashClosingRules {
  static const int minJustificationLength = 5;

  static ClosingBlock? blockOf({
    required bool isToday,
    required bool closed,
    required bool canClose,
    required bool online,
    required int pendingSyncCount,
    required int pendingAfterClosureCount,
  }) {
    if (!isToday) return ClosingBlock.notToday;
    if (closed) return ClosingBlock.closed;
    if (!canClose) return ClosingBlock.noRight;
    if (!online) return ClosingBlock.offline;
    if (pendingSyncCount > 0) return ClosingBlock.pendingSync;
    if (pendingAfterClosureCount > 0) return ClosingBlock.pendingAfterClosure;
    return null;
  }

  /// R9. « Oui » suffit. « Non » demande un déclaré lisible (≥ 0, francs
  /// entiers en CDF) **différent** du reste montré, et une justification d'au
  /// moins 5 caractères après trim.
  static bool canSubmit({
    required ClosingAnswer? answer,
    required TreasuryCurrency currency,
    required int shownExpectedInCents,
    required int? declaredInCents,
    required String justification,
  }) => switch (answer) {
    null => false,
    ClosingAnswer.matches => true,
    ClosingAnswer.differs =>
      declaredInCents != null &&
          declaredInCents >= 0 &&
          currency.acceptsCents(declaredInCents) &&
          declaredInCents != shownExpectedInCents &&
          justification.trim().length >= minJustificationLength,
  };

  /// L'écart d'une réponse « Non » : déclaré − reste montré.
  static int gapOf({
    required int shownExpectedInCents,
    required int declared,
  }) => declared - shownExpectedInCents;

  /// La journée de caisse d'un jour civil : le dimanche n'existe pas, il
  /// compte pour le lundi (R4), comme côté serveur.
  static DateTime cashDayOf(DateTime day) {
    final d = _day(day);
    return d.weekday == DateTime.sunday
        ? DateTime(d.year, d.month, d.day + 1)
        : d;
  }

  /// La journée de caisse voisine (‹ ›), dimanche sauté (R4), bornée par
  /// [min] (le début de l'historique) et [today] (R15). `null` à la borne.
  static DateTime? step(
    DateTime day,
    int direction, {
    required DateTime min,
    required DateTime today,
  }) {
    var next = DateTime(day.year, day.month, day.day + direction);
    if (next.weekday == DateTime.sunday) {
      next = DateTime(next.year, next.month, next.day + direction);
    }
    if (next.isBefore(_day(min)) || next.isAfter(_day(today))) return null;
    return next;
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
