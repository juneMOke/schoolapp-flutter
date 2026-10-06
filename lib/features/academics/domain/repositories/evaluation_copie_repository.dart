import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/copie_diffusion.dart';

/// Le journal des copies d'une évaluation : lu en local, chaque diffusion
/// écrite en local puis envoyée par l'outbox.
abstract class EvaluationCopieRepository {
  /// Journal, la diffusion la plus récente d'abord.
  Future<Either<Failure, List<CopieDiffusion>>> getCopieLog(
    String evaluationId,
  );

  /// Journalise une impression ([CopieKind.print], sans canal) ou un partage
  /// ([CopieKind.share], canal requis).
  Future<Either<Failure, CopieDiffusion>> logDiffusion(
    String evaluationId, {
    required CopieKind kind,
    CopieCanal? canal,
    required bool corrige,
  });
}
