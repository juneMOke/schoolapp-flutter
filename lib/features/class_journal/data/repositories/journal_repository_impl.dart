import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_dao.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_write_dao.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_seance_key.dart';
import 'package:school_app_flutter/features/class_journal/domain/repositories/journal_repository.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_ids.dart';

/// Le journal sur la tablette : lecture locale, écriture locale + outbox, puis
/// un envoi opportuniste si le poste est en ligne.
class JournalRepositoryImpl implements JournalRepository {
  final JournalDao _dao;
  final JournalWriteDao _writer;
  final CurrentUserContext _currentUser;
  final SyncEngine? _syncEngine;
  final Clock _now;

  const JournalRepositoryImpl({
    required JournalDao dao,
    required JournalWriteDao writer,
    required CurrentUserContext currentUser,
    SyncEngine? syncEngine,
    Clock now = systemClock,
  }) : _dao = dao,
       _writer = writer,
       _currentUser = currentUser,
       _syncEngine = syncEngine,
       _now = now;

  @override
  Future<Either<Failure, List<JournalEntry>>> entriesOfCours(
    Set<String> coursIds,
  ) async {
    try {
      return Right(await _dao.entriesOfCours(coursIds));
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, JournalEntry>> save(
    JournalSeanceKey key, {
    required JournalFields fields,
    String? chapitreId,
  }) async {
    final nowMs = _now();
    final entry = JournalEntry(
      id: JournalIds.entryId(key),
      coursId: key.coursId,
      date: key.date,
      timeSlotId: key.timeSlotId,
      chapitreId: chapitreId,
      fields: fields,
      clientUpdatedAt: DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true),
      syncState: RecordSyncState.pending,
    );
    try {
      await _writer.save(
        entry,
        schoolId: _currentUser.schoolId,
        authorId: _currentUser.uid,
        nowMs: nowMs,
      );
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
    final engine = _syncEngine;
    if (engine != null) unawaited(engine.flush());
    return Right(entry);
  }
}
