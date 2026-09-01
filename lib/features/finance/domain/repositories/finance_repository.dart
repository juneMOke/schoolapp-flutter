import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/fee_tariff.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/finance_recovery.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/finance_till.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_period.dart';

abstract class FinanceRepository {
  Future<Either<Failure, List<FeeTariff>>> getFeeTariffsByLevel({
    required String levelId,
  });

  /// Le recouvrement de l'année scolaire courante — sans fenêtre à choisir.
  Future<Either<Failure, FinanceRecovery>> getFinanceRecovery();

  /// Ce qui est entré dans le tiroir sur la fenêtre — frais et boutique.
  Future<Either<Failure, FinanceTill>> getFinanceTill({
    TillPeriod period = TillPeriod.day,
  });
}
