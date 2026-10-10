import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_seance_key.dart';

/// Le journal du professeur, lu et écrit **sur la tablette** : chaque saisie
/// réussit localement d'abord, le serveur tranche plus tard dans l'accusé.
abstract class JournalRepository {
  /// Toutes les entrées des cours [coursIds].
  Future<Either<Failure, List<JournalEntry>>> entriesOfCours(
    Set<String> coursIds,
  );

  /// Enregistre la saisie de la séance [key], horodatée maintenant, et la met
  /// en file. Vider une séance = [JournalFields.empty] sans chapitre.
  Future<Either<Failure, JournalEntry>> save(
    JournalSeanceKey key, {
    required JournalFields fields,
    String? chapitreId,
  });
}
