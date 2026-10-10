import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';

/// Ce que le journal reprend du programme : il n'invente pas le contenu
/// pédagogique, il le recopie du chapitre — librement ajustable ensuite.
abstract final class JournalPrefill {
  /// [current] avec objectif, contenu, stratégie et ressources repris de
  /// [chapitre] (ressources chargées). La C.B, l'évaluation et l'observation
  /// ne viennent pas du chapitre : elles restent celles de [current].
  static JournalFields fromChapitre(
    Chapitre chapitre, {
    JournalFields current = JournalFields.empty,
  }) {
    final objectifs = chapitre.objectifs;
    final objectif = objectifs
        .where((o) => !o.atteint)
        .followedBy(objectifs)
        .firstOrNull;
    return current.copyWith(
      objectif: objectif?.texte ?? '',
      contenu: chapitre.titre,
      strategie: chapitre.strategies.join(', '),
      ressources: chapitre.ressources.map((r) => r.nom).join(' ; '),
    );
  }

  /// La C.B à proposer sur une séance vierge : la dernière saisie pour ce
  /// cours (date, puis rang du créneau), vide s'il n'y en a pas.
  static String lastCb(
    Iterable<JournalEntry> entriesOfCours, {
    required Map<String, int> slotOrder,
  }) {
    JournalEntry? last;
    for (final e in entriesOfCours) {
      if (e.fields.cb.trim().isEmpty) continue;
      if (last == null || _isAfter(e, last, slotOrder)) last = e;
    }
    return last?.fields.cb ?? '';
  }

  static bool _isAfter(
    JournalEntry a,
    JournalEntry b,
    Map<String, int> slotOrder,
  ) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate > 0;
    return (slotOrder[a.timeSlotId] ?? 0) > (slotOrder[b.timeSlotId] ?? 0);
  }
}
