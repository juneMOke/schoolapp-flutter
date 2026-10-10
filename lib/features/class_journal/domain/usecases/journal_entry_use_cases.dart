import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_seance_key.dart';
import 'package:school_app_flutter/features/class_journal/domain/repositories/journal_repository.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_prefill.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/repositories/programme_repository.dart';

/// Ce que la modale d'une séance a besoin de connaître avant de s'ouvrir.
class JournalFormSeed {
  /// Les chapitres du cours, dans l'ordre du programme.
  final List<Chapitre> chapters;

  /// La C.B à proposer sur une séance vierge.
  final String lastCb;

  const JournalFormSeed({required this.chapters, required this.lastCb});
}

/// Les chapitres du cours et la dernière C.B saisie. Un programme illisible
/// laisse la modale ouverte sur « Hors programme », rien de plus grave.
class LoadJournalFormSeedUseCase {
  final ProgrammeRepository _programme;
  final JournalRepository _journal;

  const LoadJournalFormSeedUseCase({
    required ProgrammeRepository programme,
    required JournalRepository journal,
  }) : _programme = programme,
       _journal = journal;

  Future<JournalFormSeed> call(
    String coursId, {
    required Map<String, int> slotOrder,
  }) async {
    final programme = await _programme.loadProgramme(coursId);
    final entries = await _journal.entriesOfCours({coursId});
    return JournalFormSeed(
      chapters: programme.fold(
        (_) => const [],
        (p) => [for (final row in p.chapitres) row.chapitre],
      ),
      lastCb: entries.fold(
        (_) => '',
        (all) => JournalPrefill.lastCb(all, slotOrder: slotOrder),
      ),
    );
  }
}

/// Le chapitre entier (ressources comprises) que le préremplissage recopie ;
/// `null` s'il n'est plus lisible.
class LoadJournalChapterUseCase {
  final ProgrammeRepository _programme;

  const LoadJournalChapterUseCase(this._programme);

  Future<Chapitre?> call(String chapitreId) async =>
      (await _programme.loadChapitre(
        chapitreId,
      )).fold((_) => null, (detail) => detail.chapitre);
}

/// Enregistre la saisie d'une séance — ou la vide ([JournalFields.empty],
/// sans chapitre).
class SaveJournalEntryUseCase {
  final JournalRepository _journal;

  const SaveJournalEntryUseCase(this._journal);

  Future<Either<Failure, JournalEntry>> call(
    JournalSeanceKey key, {
    required JournalFields fields,
    String? chapitreId,
  }) => _journal.save(key, fields: fields, chapitreId: chapitreId);
}
