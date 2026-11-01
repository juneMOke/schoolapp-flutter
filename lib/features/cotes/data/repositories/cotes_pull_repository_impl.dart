import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_metier_pull_handlers.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/per_cours_keyset_puller.dart';
import 'package:school_app_flutter/features/academics/domain/entities/offline/academics_delta_pull_outcome.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_pull_api.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/ref_cote_cours_local_data_source.dart';
import 'package:school_app_flutter/features/cotes/data/models/cote_delta_dto.dart';

/// Préfixe des curseurs du flux : `academics_cotes:<coursId>`.
const String kAcademicsCotesResourcePrefix = 'academics_cotes';

/// Le flux des cotes, cours par cours, comme les notes.
class CotesPullRepositoryImpl {
  static const int pageLimit = 200;

  final CotesPullApi _api;
  final RefCoteCoursLocalDataSource _local;
  final PerCoursKeysetPuller _puller;
  final Map<String, dynamic> _requiredAuth;

  const CotesPullRepositoryImpl({
    required CotesPullApi api,
    required RefCoteCoursLocalDataSource localDataSource,
    required PerCoursKeysetPuller puller,
    required Map<String, dynamic> requiredAuth,
  }) : _api = api,
       _local = localDataSource,
       _puller = puller,
       _requiredAuth = requiredAuth;

  Future<Either<Failure, AcademicsDeltaPullOutcome>> syncCotes() =>
      _puller.pull<CoteDeltaDto>(
        resourcePrefix: kAcademicsCotesResourcePrefix,
        fetchPage: (coursId, cursor) async => (await _api.pullCotes(
          _requiredAuth,
          coursId,
          cursor,
          pageLimit,
        )).data,
        apply: (page, _) => _local.applyPulled(page.items),
      );
}

/// Les cotes (GET /sync/academics/cotes — `academics.grade.read`).
class CotesPullHandler extends CoursScopedPullHandler {
  CotesPullHandler(CotesPullRepositoryImpl repository)
    : super(
        resource: kAcademicsCotesResourcePrefix,
        requiredPermissions: const [Perm.academicsGradeRead],
        pull: repository.syncCotes,
      );
}
