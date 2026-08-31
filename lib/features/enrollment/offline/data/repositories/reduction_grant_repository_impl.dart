import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_reduction_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/reduction_grant_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/grantable_reduction.dart';

/// Le catalogue vit dans la Facturation ; on le lit par un **seam** plutôt que
/// par un import direct, comme le pull le fait déjà pour la grille tarifaire et
/// le catalogue boutique (invariant I-4).
typedef GrantableReductionsReader =
    Future<List<GrantableReduction>> Function(String schoolId);

class ReductionGrantRepositoryImpl implements ReductionGrantRepository {
  final EnrollmentReductionDao dao;
  final GrantableReductionsReader readGrantable;
  final CurrentUserContext currentUser;
  final Clock now;

  const ReductionGrantRepositoryImpl({
    required this.dao,
    required this.readGrantable,
    required this.currentUser,
    this.now = systemClock,
  });

  @override
  Future<Either<Failure, List<GrantableReduction>>> grantable() async {
    try {
      return Right(await readGrantable(currentUser.schoolId ?? ''));
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> grantedFor(String enrollmentId) async {
    try {
      return Right(await dao.codesFor(enrollmentId));
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> replaceGrants(
    String enrollmentId,
    List<String> codes,
  ) async {
    try {
      await dao.replaceFor(enrollmentId, codes, nowMs: now());
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}
