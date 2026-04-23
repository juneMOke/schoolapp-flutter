import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/fee_tariff.dart';
abstract class FinanceRepository {
  Future<Either<Failure, List<FeeTariff>>> getFeeTariffsByLevel({
    required String levelId,
  });
}
