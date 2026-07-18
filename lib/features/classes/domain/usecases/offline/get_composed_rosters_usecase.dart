import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';

/// CF4 — Rosters composés (miroir ± transferts pending) de toutes les classes
/// d'un niveau, pour l'affichage optimiste de l'écran d'organisation.
class GetComposedRostersUseCase {
  final ClassroomOfflineRepository _repository;

  const GetComposedRostersUseCase(this._repository);

  Future<Either<Failure, Map<String, List<ClassroomMember>>>> call({
    required String academicYearId,
    required String schoolLevelId,
  }) => _repository.getComposedRosters(
    academicYearId: academicYearId,
    schoolLevelId: schoolLevelId,
  );
}
