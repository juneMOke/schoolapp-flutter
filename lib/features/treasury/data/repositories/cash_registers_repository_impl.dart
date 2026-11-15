import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/data/online/cash_registers_api.dart';
import 'package:school_app_flutter/features/treasury/data/repositories/treasury_online.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_adjustment.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/cash_registers_repository.dart';

class CashRegistersRepositoryImpl implements CashRegistersRepository {
  final CashRegistersApi _api;

  const CashRegistersRepositoryImpl(this._api);

  @override
  Future<Either<Failure, List<RegisterConfig>>> list() =>
      guardTreasury(_api.list);

  @override
  Future<Either<Failure, CashRegister>> create({
    required TreasuryCurrency currency,
    required String? name,
    required int openingAmountInCents,
  }) => guardTreasury(
    () => _api.create(
      currency: currency,
      name: name,
      openingAmountInCents: openingAmountInCents,
    ),
  );

  @override
  Future<Either<Failure, CashAdjustment>> adjust({
    required String registerId,
    required String id,
    required int shownExpectedInCents,
    required int newAmountInCents,
    required String reason,
  }) => guardTreasury(
    () => _api.adjust(
      registerId: registerId,
      id: id,
      shownExpectedInCents: shownExpectedInCents,
      newAmountInCents: newAmountInCents,
      reason: reason,
    ),
  );

  @override
  Future<Either<Failure, List<CashAdjustment>>> adjustments(
    String registerId,
  ) => guardTreasury(() => _api.adjustments(registerId));
}
