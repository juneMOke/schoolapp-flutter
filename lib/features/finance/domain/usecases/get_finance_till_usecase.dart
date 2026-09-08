import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/finance_till.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_window.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/finance_repository.dart';

/// Ce qui est entré dans le tiroir sur la fenêtre — frais scolaires **et**
/// ventes boutique.
///
/// Le défaut est [TillPeriod.day] : la question qu'on pose le soir, à la
/// fermeture. Ce qu'il reste à recouvrer est l'autre question, et elle ne se lit
/// pas à la journée — voir [GetFinanceRecoveryUseCase].
class GetFinanceTillUseCase {
  final FinanceRepository _repository;

  const GetFinanceTillUseCase(this._repository);

  Future<Either<Failure, FinanceTill>> call({
    TillWindow window = const TillWindow.day(),
  }) => _repository.getFinanceTill(window: window);
}
