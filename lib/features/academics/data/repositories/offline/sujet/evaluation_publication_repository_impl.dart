import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_evaluation_sujet_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_publication_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_sujet_local_data_source.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_publication.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet_codes.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/publication_context.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/evaluation_publication_repository.dart';

/// Publications d'une évaluation : appels **en ligne**, jamais rejoués. La
/// réponse du serveur est écrite en local tout de suite ; le delta la
/// confirmera.
class EvaluationPublicationRepositoryImpl
    implements EvaluationPublicationRepository {
  final AcademicsEvaluationSujetApi _api;
  final EvaluationPublicationLocalDataSource _publications;
  final AcademicsLocalDataSource _academics;
  final EvaluationSujetLocalDataSource _sujets;
  final Map<String, dynamic> _requiredAuth;

  const EvaluationPublicationRepositoryImpl({
    required AcademicsEvaluationSujetApi api,
    required EvaluationPublicationLocalDataSource publications,
    required AcademicsLocalDataSource academics,
    required EvaluationSujetLocalDataSource sujets,
    required Map<String, dynamic> requiredAuth,
  }) : _api = api,
       _publications = publications,
       _academics = academics,
       _sujets = sujets,
       _requiredAuth = requiredAuth;

  static const List<String> _refusalCodes = [
    EvaluationSujetCodes.sujetNotPublishable,
    EvaluationSujetCodes.sujetEmpty,
    EvaluationSujetCodes.evaluationIncomplete,
    EvaluationSujetCodes.coursNotOwned,
  ];

  @override
  Future<Either<Failure, PublicationContext>> getContext(
    String evaluationId,
  ) async {
    try {
      final evaluation = await _academics.getEvaluation(evaluationId);
      if (evaluation == null) return const Left(NotFoundFailure());
      final sujet = await _sujets.getSujet(evaluationId);
      final pendingNotes = await _academics.getPendingNotesForEvaluation(
        evaluationId,
      );
      return Right(
        PublicationContext(
          publications: await _publications.getPublications(evaluationId),
          evaluationPending: evaluation.syncState != SyncState.synced,
          // En file ou refusé : le serveur n'a pas la version affichée.
          sujetPending:
              sujet?.syncStatus != null &&
              sujet!.syncStatus != SyncState.synced.dbValue,
          notesPending: pendingNotes.isNotEmpty,
        ),
      );
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PublicationEtat>> publish(
    String evaluationId,
    PublicationKind kind,
  ) => _online(() async {
    final state = await _api.publish(
      _requiredAuth,
      evaluationId,
      kind.pathSegment,
    );
    final etat = state.etat;
    if (etat == null) return const Left(ServerFailure());
    await _publications.setPublication(evaluationId, kind, etat);
    return Right(etat);
  });

  @override
  Future<Either<Failure, Unit>> withdraw(
    String evaluationId,
    PublicationKind kind,
  ) => _online(() async {
    await _api.withdraw(_requiredAuth, evaluationId, kind.pathSegment);
    await _publications.setPublication(evaluationId, kind, null);
    return const Right(unit);
  });

  /// Traduit un refus du serveur (`detailCode`) en
  /// [PublicationRefusedFailure] ; le reste garde le `Failure` de
  /// l'intercepteur.
  Future<Either<Failure, T>> _online<T>(
    Future<Either<Failure, T>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      final code = ApiErrorParser.detailCodeOf(e.response);
      if (code != null && _refusalCodes.contains(code)) {
        final details = ApiErrorParser.detailsOf(e.response);
        return Left(
          PublicationRefusedFailure(
            code,
            saisies: (details?['saisies'] as num?)?.toInt(),
            effectif: (details?['effectif'] as num?)?.toInt(),
          ),
        );
      }
      final failure = e.error;
      return Left(failure is Failure ? failure : const NetworkFailure());
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}
