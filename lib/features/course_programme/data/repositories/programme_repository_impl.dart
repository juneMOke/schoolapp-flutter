import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_dao.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_write_dao.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_detail.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/programme.dart';
import 'package:school_app_flutter/features/course_programme/domain/repositories/programme_repository.dart';

/// Le programme lu et écrit sur la tablette. Les évaluations liées se lisent
/// dans la table des évaluations, par leurs `chapitreIds` : aucun compteur ne
/// descend du serveur.
class ProgrammeRepositoryImpl implements ProgrammeRepository {
  final ChapitreDao _dao;
  final ChapitreWriteDao _writer;
  final AcademicsLocalDataSource _evaluations;
  final IdGenerator _ids;
  final CurrentUserContext _currentUser;
  final SyncEngine? _syncEngine;
  final Clock _now;

  const ProgrammeRepositoryImpl({
    required ChapitreDao dao,
    required ChapitreWriteDao writer,
    required AcademicsLocalDataSource evaluations,
    required IdGenerator ids,
    required CurrentUserContext currentUser,
    SyncEngine? syncEngine,
    Clock now = systemClock,
  }) : _dao = dao,
       _writer = writer,
       _evaluations = evaluations,
       _ids = ids,
       _currentUser = currentUser,
       _syncEngine = syncEngine,
       _now = now;

  @override
  String newId() => _ids.newId();

  @override
  Future<Either<Failure, Programme>> loadProgramme(String coursId) =>
      _guard(() async {
        final chapitres = await _dao.chapitresOfCours(coursId);
        final notes = await _dao.notesCountByChapitre(coursId);
        final evaluations = await _evaluations.getEvaluationsForCours(coursId);
        final cited = <String, int>{};
        for (final evaluation in evaluations) {
          for (final id in evaluation.chapitreIds) {
            cited[id] = (cited[id] ?? 0) + 1;
          }
        }
        return Programme(
          coursId: coursId,
          evaluationsCount: evaluations.length,
          chapitres: [
            for (final chapitre in chapitres)
              ProgrammeChapitre(
                chapitre: chapitre,
                notesCount: notes[chapitre.id] ?? 0,
                evaluationsCount: cited[chapitre.id] ?? 0,
              ),
          ],
        );
      });

  @override
  Future<Either<Failure, ChapitreDetail>> loadChapitre(String chapitreId) =>
      _guard(() async {
        final chapitre = await _dao.find(chapitreId);
        if (chapitre == null) throw const _Missing();
        final siblings = await _dao.chapitresOfCours(chapitre.coursId);
        final evaluations = await _evaluations.getEvaluationsForCours(
          chapitre.coursId,
        );
        return ChapitreDetail(
          chapitre: chapitre.copyWith(
            notes: await _dao.notesOf(chapitreId),
            ressources: await _dao.ressourcesOf(chapitreId),
          ),
          numero: siblings.indexWhere((c) => c.id == chapitreId) + 1,
          evaluations: [
            for (final row in evaluations.reversed)
              if (row.chapitreIds.contains(chapitreId)) _linkOf(row),
          ],
        );
      });

  @override
  Future<Either<Failure, Chapitre>> saveChapitre(Chapitre chapitre) async {
    if (chapitre.awaitingDownload) {
      return const Left(ValidationFailure('Chapitre pas encore téléchargé'));
    }
    final nowMs = _now();
    final stamped = chapitre.copyWith(
      clientUpdatedAt: DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true),
      blocs: [
        for (final bloc in chapitre.blocs)
          if (!bloc.isEmpty) bloc,
      ],
    );
    return _write(
      () => _writer.saveChapitre(
        stamped,
        schoolId: _currentUser.schoolId,
        nowMs: nowMs,
      ),
      stamped,
    );
  }

  @override
  Future<Either<Failure, Unit>> deleteChapitre(String chapitreId) => _write(
    () => _writer.deleteChapitre(
      chapitreId,
      schoolId: _currentUser.schoolId,
      nowMs: _now(),
    ),
    unit,
  );

  @override
  Future<Either<Failure, Unit>> reorder(
    String coursId,
    List<String> chapitreIds,
  ) => _write(
    () => _writer.reorder(
      coursId,
      chapitreIds,
      schoolId: _currentUser.schoolId,
      nowMs: _now(),
    ),
    unit,
  );

  static ChapitreEvaluationLink _linkOf(EvaluationRow row) =>
      ChapitreEvaluationLink(
        id: row.id,
        type: TypeEvaluationX.fromApiValue(row.type),
        date: DateTime.fromMillisecondsSinceEpoch(row.evalDate, isUtc: true),
        maxPoints: row.maxPoints,
      );

  /// Un geste local : écrit, puis un envoi opportuniste si le poste est en
  /// ligne. Une écriture qui échoue n'a rien mis en file.
  Future<Either<Failure, T>> _write<T>(
    Future<void> Function() write,
    T result,
  ) async {
    try {
      await write();
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
    final engine = _syncEngine;
    if (engine != null) unawaited(engine.flush());
    return Right(result);
  }

  static Future<Either<Failure, T>> _guard<T>(Future<T> Function() read) async {
    try {
      return Right(await read());
    } on _Missing {
      return const Left(NotFoundFailure('Chapitre introuvable'));
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}

class _Missing implements Exception {
  const _Missing();
}
