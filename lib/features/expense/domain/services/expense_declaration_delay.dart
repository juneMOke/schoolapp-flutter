import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';

/// Le temps écoulé entre le décaissement d'une déclaration et sa réception
/// par le serveur (E1, option du back) : ce que le promoteur doit voir au
/// visa, puisqu'un décaissement ne s'antidate plus qu'en faussant l'horloge
/// du poste, ou par un envoi hors ligne tardif.
///
/// La réception est l'instant de dépôt de la photo du bon
/// (`voucher.uploadedAt`, alias `declaredAt` du contrat) : écrit par le
/// serveur, jamais effacé, annulation comprise.
abstract final class ExpenseDeclarationDelay {
  /// Au-delà, le serveur ne pose pas le visa d'office : la déclaration
  /// attend le regard de la direction.
  static const Duration lateThreshold = Duration(hours: 72);

  /// L'écart, ou `null` hors déclaration ou tant que le serveur ne l'a pas
  /// reçue. Jamais négatif : le serveur borne le décaissement à son
  /// « maintenant ».
  static Duration? of(Expense expense) {
    if (!expense.isDeclaration) return null;
    final disbursed = expense.disbursedAt;
    final received = expense.voucher?.uploadedAt;
    if (disbursed == null || received == null) return null;
    final gap = received.difference(disbursed);
    return gap.isNegative ? Duration.zero : gap;
  }

  /// Les jours de calendrier, à l'heure de l'école, entre le décaissement et
  /// la réception ; `null` quand [of] l'est.
  static int? days(Expense expense) {
    if (of(expense) == null) return null;
    // En UTC : un fuseau du poste à heure d'été fausserait la soustraction.
    DateTime day(DateTime instant) {
      final d = SchoolTime.today(instant);
      return DateTime.utc(d.year, d.month, d.day);
    }

    final gap = day(
      expense.voucher!.uploadedAt!,
    ).difference(day(expense.disbursedAt!)).inDays;
    return gap < 0 ? 0 : gap;
  }

  /// Plus de 72 h d'écart, strictement — la règle du serveur.
  static bool isLate(Expense expense) =>
      (of(expense) ?? Duration.zero) > lateThreshold;
}
