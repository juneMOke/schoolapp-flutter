import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Créances locales d'un élève (grand-livre offline).
class GetLocalStudentChargesUseCase {
  final FinanceOfflineRepository _repository;

  const GetLocalStudentChargesUseCase(this._repository);

  Future<Either<Failure, List<LocalStudentCharge>>> call(String studentId) =>
      _repository.getCharges(studentId);
}
