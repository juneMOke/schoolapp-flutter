import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Génère les créances provisoires d'un nouvel élève depuis la grille (FF5).
class InitializeChargesUseCase {
  final FinanceOfflineRepository _repository;

  const InitializeChargesUseCase(this._repository);

  Future<Either<Failure, List<LocalStudentCharge>>> call({
    required String studentId,
    required String academicYearId,
    required String schoolLevelId,
    String? schoolLevelGroupId,
    String? dueFallback,
  }) => _repository.initializeCharges(
    studentId: studentId,
    academicYearId: academicYearId,
    schoolLevelId: schoolLevelId,
    schoolLevelGroupId: schoolLevelGroupId,
    dueFallback: dueFallback,
  );
}
