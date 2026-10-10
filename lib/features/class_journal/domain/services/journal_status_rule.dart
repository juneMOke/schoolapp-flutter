import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_status.dart';

/// Le statut d'une séance, dérivé de son entrée et de sa date.
///
/// Un refus du serveur prime : la saisie reste lisible, mais elle est à
/// corriger. Une saisie pas encore envoyée compte déjà.
abstract final class JournalStatusRule {
  /// [date] et [today] sont des jours civils (minuit).
  static JournalStatus of(
    JournalEntry? entry, {
    required DateTime date,
    required DateTime today,
  }) {
    if (entry != null && entry.isRejected) return JournalStatus.rejected;
    if (entry != null && entry.isFilled) return JournalStatus.filled;
    return date.isBefore(today)
        ? JournalStatus.missing
        : JournalStatus.toPrepare;
  }
}
