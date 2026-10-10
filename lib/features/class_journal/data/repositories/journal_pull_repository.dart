import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/per_cours_keyset_puller.dart';
import 'package:school_app_flutter/features/academics/domain/entities/offline/academics_delta_pull_outcome.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_pull_writer.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_entry_dto.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_sync_api.dart';

/// Le préfixe des curseurs du flux `academics.journal` : un par cours,
/// `academics_journal:<coursId>`.
const String kAcademicsJournalResourcePrefix = 'academics_journal';

/// La descente du journal de tous les cours du professeur, par le moteur des
/// flux scopés cours ([PerCoursKeysetPuller]).
class JournalPullRepository {
  final JournalSyncApi _api;
  final JournalPullWriter _writer;
  final PerCoursKeysetPuller _puller;
  final Map<String, dynamic> _requiredAuth;

  static const int pageLimit = 100;

  const JournalPullRepository({
    required JournalSyncApi api,
    required JournalPullWriter writer,
    required PerCoursKeysetPuller puller,
    required Map<String, dynamic> requiredAuth,
  }) : _api = api,
       _writer = writer,
       _puller = puller,
       _requiredAuth = requiredAuth;

  Future<Either<Failure, AcademicsDeltaPullOutcome>> syncJournal() =>
      _puller.pull<JournalEntryDto>(
        resourcePrefix: kAcademicsJournalResourcePrefix,
        fetchPage: (coursId, cursor) async => (await _api.pullEntries(
          _requiredAuth,
          coursId,
          cursor,
          pageLimit,
        )).data,
        apply: (page, syncedAt) => _writer.apply(page.items, nowMs: syncedAt),
      );
}
