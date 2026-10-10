import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';

/// Le « séance n » de l'étiquette chapitre : le rang chronologique (date, puis
/// créneau) d'une entrée parmi les entrées **renseignées** du même chapitre.
abstract final class JournalSeanceNumbers {
  /// Rend `entryId → n` ; [slotOrder] range deux séances du même jour.
  static Map<String, int> of(
    Iterable<JournalEntry> entries, {
    required Map<String, int> slotOrder,
  }) {
    final byChapitre = <String, List<JournalEntry>>{};
    for (final e in entries) {
      final chapitreId = e.chapitreId;
      if (chapitreId == null || !e.isFilled) continue;
      (byChapitre[chapitreId] ??= []).add(e);
    }
    final numbers = <String, int>{};
    for (final list in byChapitre.values) {
      list.sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        final bySlot = (slotOrder[a.timeSlotId] ?? 0).compareTo(
          slotOrder[b.timeSlotId] ?? 0,
        );
        return bySlot != 0 ? bySlot : a.id.compareTo(b.id);
      });
      for (var i = 0; i < list.length; i++) {
        numbers[list[i].id] = i + 1;
      }
    }
    return numbers;
  }
}
