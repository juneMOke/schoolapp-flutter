import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_pull_outcome.dart';

/// Contrat du PULL KEYSET de la Discipline (`GET /sync/disciplinary-cases`).
/// Cadré à l'année, résumable, ne lève jamais (échec encodé en `Left`).
abstract class DisciplinaryPullRepository {
  Future<Either<Failure, DisciplinaryPullOutcome>> syncDisciplinaryCases();
}
