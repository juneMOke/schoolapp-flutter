import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_request.dart';

/// La correction de niveau, écrite et lue sur la tablette. L'envoi au serveur
/// passe par l'outbox.
abstract class LevelCorrectionRepository {
  /// Inscriptions dont la correction vient de changer sur ce poste.
  Stream<Set<String>> get changes;

  /// Pose la correction. `Right(false)` : une correction de la même inscription
  /// attend déjà, rien n'est écrit. `Left(ValidationFailure)` sur une demande
  /// incohérente (motif vide, niveau cible identique).
  Future<Either<Failure, bool>> correct(LevelCorrectionRequest request);

  /// La dernière correction de l'inscription, `null` s'il n'y en a pas.
  Future<Either<Failure, LevelCorrection?>> latestFor(String enrollmentId);
}
