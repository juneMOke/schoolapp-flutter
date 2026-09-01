import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/finance_recovery.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/finance_repository.dart';

/// Le recouvrement de l'année scolaire courante.
///
/// **Sans paramètre**, et c'est le fond de l'écran : le recouvrement est un
/// état, il ne se lit qu'à l'échelle où les créances existent. Ce qui entre au
/// jour le jour se demande à [GetFinanceTillUseCase].
class GetFinanceRecoveryUseCase {
  final FinanceRepository _repository;

  const GetFinanceRecoveryUseCase(this._repository);

  Future<Either<Failure, FinanceRecovery>> call() =>
      _repository.getFinanceRecovery();
}
