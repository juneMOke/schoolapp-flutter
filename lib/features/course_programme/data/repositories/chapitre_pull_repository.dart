import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/per_cours_keyset_puller.dart';
import 'package:school_app_flutter/features/academics/domain/entities/offline/academics_delta_pull_outcome.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_pull_writer.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/chapitre_dto.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_sync_api.dart';

/// Préfixe `sync_meta` du flux des chapitres — clé effective
/// `academics_chapitres:{coursId}`, un curseur par cours comme les
/// évaluations. C'est aussi la ressource du registre des disparitions.
const String kAcademicsChapitresResourcePrefix = 'academics_chapitres';

/// La descente des chapitres de tous les cours du professeur, par le moteur
/// des flux scopés cours ([PerCoursKeysetPuller]).
class ChapitrePullRepository {
  final ProgrammeSyncApi _api;
  final ChapitrePullWriter _writer;
  final PerCoursKeysetPuller _puller;
  final Map<String, dynamic> _requiredAuth;

  static const int pageLimit = 100;

  const ChapitrePullRepository({
    required ProgrammeSyncApi api,
    required ChapitrePullWriter writer,
    required PerCoursKeysetPuller puller,
    required Map<String, dynamic> requiredAuth,
  }) : _api = api,
       _writer = writer,
       _puller = puller,
       _requiredAuth = requiredAuth;

  Future<Either<Failure, AcademicsDeltaPullOutcome>> syncChapitres() =>
      _puller.pull<ChapitreDto>(
        resourcePrefix: kAcademicsChapitresResourcePrefix,
        fetchPage: (coursId, cursor) async => (await _api.pullChapitres(
          _requiredAuth,
          coursId,
          cursor,
          pageLimit,
        )).data,
        apply: (page, syncedAt) => _writer.apply(page.items, nowMs: syncedAt),
      );
}
