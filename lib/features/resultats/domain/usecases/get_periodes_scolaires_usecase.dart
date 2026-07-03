import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/periode_scolaire.dart';
import 'package:school_app_flutter/features/resultats/domain/repositories/resultats_repository.dart';

/// Charge les grandes périodes d'une classe (source des `periodeScolaireId`).
///
/// Un seul paramètre requis ⇒ pas d'objet `Params` (convention projet §6).
class GetPeriodesScolairesUseCase {
  final ResultatsRepository _repository;

  const GetPeriodesScolairesUseCase(this._repository);

  Future<Either<Failure, List<PeriodeScolaire>>> call(String classroomId) =>
      _repository.getPeriodesScolaires(classroomId);
}
