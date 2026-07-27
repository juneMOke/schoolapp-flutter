import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_distribution_criterion.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';

class DistributeStudentsToClassroomsUseCase {
  final ClassroomRepository _repository;
  final ClassroomOfflineRepository _offlineRepository;

  const DistributeStudentsToClassroomsUseCase({
    required ClassroomRepository repository,
    required ClassroomOfflineRepository offlineRepository,
  }) : _repository = repository,
       _offlineRepository = offlineRepository;

  /// Renvoie `Right(true)` si le re-pull local (miroir des classes créées) a
  /// aussi réussi, `Right(false)` si seule la répartition serveur a réussi
  /// (re-pull à retenter plus tard) — même contrat que
  /// [ClassroomOfflineRepository]'s reassign flow.
  Future<Either<Failure, bool>> call({
    required String academicYearId,
    required String schoolLevelGroupId,
    required String schoolLevelId,
    required ClassroomDistributionCriterion distributionCriterion,
  }) async {
    final distributed = await _repository.distributeStudentsToClassrooms(
      academicYearId: academicYearId,
      schoolLevelGroupId: schoolLevelGroupId,
      schoolLevelId: schoolLevelId,
      distributionCriterion: distributionCriterion,
    );

    return distributed.fold(Left.new, (_) async {
      final repull = await _offlineRepository.syncClassrooms(
        academicYearId: academicYearId,
      );
      return Right(repull.isRight());
    });
  }
}
