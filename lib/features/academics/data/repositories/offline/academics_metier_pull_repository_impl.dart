import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_metier_pull_api.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/academics_metier_pull_models.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/per_cours_keyset_puller.dart';
import 'package:school_app_flutter/features/academics/domain/entities/offline/academics_delta_pull_outcome.dart';

/// Préfixes `sync_meta` (curseur + bootstrap) **par cours** des deux ressources
/// métier — clés effectives `academics_evaluations:{coursId}` et
/// `academics_notes:{coursId}`. Curseurs INDÉPENDANTS (split).
const String kAcademicsEvaluationsResourcePrefix = 'academics_evaluations';
const String kAcademicsNotesResourcePrefix = 'academics_notes';

/// Pull KEYSET métier (évaluations, notes), **itéré par cours** par le
/// [PerCoursKeysetPuller]. L'application saute les lignes locales
/// `PENDING_SYNC` (jamais de clobber d'écriture non synchronisée).
class AcademicsMetierPullRepositoryImpl {
  final AcademicsMetierPullApi _api;
  final AcademicsLocalDataSource _local;
  final PerCoursKeysetPuller _puller;
  final Map<String, dynamic> _requiredAuth;

  static const int pageLimit = 100;

  const AcademicsMetierPullRepositoryImpl({
    required AcademicsMetierPullApi api,
    required AcademicsLocalDataSource localDataSource,
    required PerCoursKeysetPuller puller,
    required Map<String, dynamic> requiredAuth,
  }) : _api = api,
       _local = localDataSource,
       _puller = puller,
       _requiredAuth = requiredAuth;

  /// Pull des évaluations de tous les cours locaux.
  Future<Either<Failure, AcademicsDeltaPullOutcome>> syncEvaluations() =>
      _puller.pull<EvaluationDeltaDto>(
        resourcePrefix: kAcademicsEvaluationsResourcePrefix,
        fetchPage: (coursId, cursor) async => (await _api.pullEvaluations(
          _requiredAuth,
          coursId,
          cursor,
          pageLimit,
        )).data,
        apply: (page, syncedAt) => _local.applyPulledEvaluations(
          page.items.map((d) => d.toLocalRow(syncedAt)).toList(),
        ),
      );

  /// Pull des notes de tous les cours locaux.
  Future<Either<Failure, AcademicsDeltaPullOutcome>> syncNotes() =>
      _puller.pull<NoteDeltaDto>(
        resourcePrefix: kAcademicsNotesResourcePrefix,
        fetchPage: (coursId, cursor) async => (await _api.pullNotes(
          _requiredAuth,
          coursId,
          cursor,
          pageLimit,
        )).data,
        apply: (page, syncedAt) => _local.applyPulledNotes(
          page.items.map((d) => d.toLocalRow(syncedAt)).toList(),
        ),
      );
}
