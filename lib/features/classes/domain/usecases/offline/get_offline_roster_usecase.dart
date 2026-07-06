import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';

/// Roster ACTIVE d'une classe (CF3). `query` optionnel → recherche locale.
class GetOfflineRosterUseCase {
  final ClassroomOfflineRepository _repository;

  const GetOfflineRosterUseCase(this._repository);

  Future<Either<Failure, List<ClassroomMember>>> call({
    required String classroomId,
    String? query,
  }) {
    final q = query?.trim() ?? '';
    if (q.isEmpty) {
      return _repository.getRoster(classroomId: classroomId);
    }
    return _repository.searchRoster(classroomId: classroomId, query: q);
  }
}
