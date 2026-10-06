import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_metier_pull_repository_impl.dart'
    show kAcademicsChapitresResourcePrefix;
import 'package:school_app_flutter/features/academics/data/repositories/offline/per_cours_keyset_puller.dart';
import 'package:school_app_flutter/features/academics/domain/entities/offline/academics_delta_pull_outcome.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_pull_writer.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_blobs.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/chapitre_dto.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_sync_api.dart';

/// La descente des chapitres de tous les cours du professeur, par le moteur
/// des flux scopés cours ([PerCoursKeysetPuller]).
class ChapitrePullRepository {
  final ProgrammeSyncApi _api;
  final ChapitrePullWriter _writer;
  final PerCoursKeysetPuller _puller;
  final ProgrammeBlobs? _blobs;
  final Map<String, dynamic> _requiredAuth;

  static const int pageLimit = 100;

  const ChapitrePullRepository({
    required ProgrammeSyncApi api,
    required ChapitrePullWriter writer,
    required PerCoursKeysetPuller puller,
    required Map<String, dynamic> requiredAuth,
    ProgrammeBlobs? blobs,
  }) : _api = api,
       _writer = writer,
       _puller = puller,
       _blobs = blobs,
       _requiredAuth = requiredAuth;

  /// Après une descente qui a écrit, les fichiers des ressources retirées
  /// ailleurs (absentes de la liste serveur) quittent le magasin.
  Future<Either<Failure, AcademicsDeltaPullOutcome>> syncChapitres() async {
    final result = await _pull();
    final blobs = _blobs;
    if (blobs != null && result.fold((_) => false, (o) => o.upserted > 0)) {
      await blobs.reclaimOrphans();
    }
    return result;
  }

  Future<Either<Failure, AcademicsDeltaPullOutcome>> _pull() =>
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
