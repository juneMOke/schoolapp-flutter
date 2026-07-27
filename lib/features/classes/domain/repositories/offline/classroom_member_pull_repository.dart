import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_member_pull_outcome.dart';

/// Contrat du pull keyset dédié du roster (CF2) : boucle sur son propre
/// curseur jusqu'à `hasMore=false`, indépendamment des classes. Ne lève jamais
/// (l'échec est un `Left`).
abstract class ClassroomMemberPullRepository {
  Future<Either<Failure, ClassroomMemberPullOutcome>> syncMembers({
    required String academicYearId,
  });
}
