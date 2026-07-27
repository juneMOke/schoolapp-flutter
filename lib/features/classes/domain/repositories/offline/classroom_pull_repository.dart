import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_pull_outcome.dart';

/// Contrat du pull keyset dédié des classes (CF2) : boucle sur son propre
/// curseur jusqu'à `hasMore=false`, indépendamment du roster. Ne lève jamais
/// (l'échec est un `Left`).
abstract class ClassroomPullRepository {
  Future<Either<Failure, ClassroomPullOutcome>> syncClassrooms({
    required String academicYearId,
  });
}
