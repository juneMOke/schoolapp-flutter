import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/attachments/attachment_fetcher.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/depot/evaluation_depot_local_data_source.dart';
import 'package:school_app_flutter/features/academics/domain/entities/depot/depot_copie.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/depot_copie_repository.dart';

/// Les copies déposées : lecture locale, pages à la demande.
class DepotCopieRepositoryImpl implements DepotCopieRepository {
  final EvaluationDepotLocalDataSource local;
  final AttachmentFetcher fetcher;
  final Map<String, dynamic> requiredAuth;

  const DepotCopieRepositoryImpl({
    required this.local,
    required this.fetcher,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, List<DepotCopie>>> depots(String evaluationId) async {
    try {
      return Right(await local.depotsOf(evaluationId));
    } catch (_) {
      return const Left(StorageFailure('Local homework copies read failed'));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> fichier(
    String evaluationId,
    DepotFichier fichier,
  ) async {
    final fetched = await fetcher.fetch(
      path: AppConstants.academicsDepotFichierContentEndpoint
          .replaceFirst('{evaluationId}', Uri.encodeComponent(evaluationId))
          .replaceFirst('{fichierId}', Uri.encodeComponent(fichier.id)),
      ref: fichier.ref,
      extras: requiredAuth,
    );
    return switch (fetched) {
      AttachmentFetched(:final bytes) => Right(bytes),
      AttachmentFetchFailed(error: AttachmentFetchError.offline) => const Left(
        NetworkFailure(),
      ),
      AttachmentFetchFailed() => const Left(NotFoundFailure()),
    };
  }
}
