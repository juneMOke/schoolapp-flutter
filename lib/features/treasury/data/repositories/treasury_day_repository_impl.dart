import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/data/online/treasury_day_api.dart';
import 'package:school_app_flutter/features/treasury/data/repositories/treasury_online.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_closure.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_movement.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_day_repository.dart';

class TreasuryDayRepositoryImpl implements TreasuryDayRepository {
  final TreasuryDayApi _api;

  const TreasuryDayRepositoryImpl(this._api);

  @override
  Future<Either<Failure, TreasuryDay>> day(DateTime date) =>
      guardTreasury(() => _api.day(date));

  @override
  Future<Either<Failure, List<CashMovement>>> movements(
    DateTime date, {
    required String registerId,
    MovementDirection? direction,
  }) => guardTreasury(
    () => _api.movements(date, registerId: registerId, direction: direction),
  );

  @override
  Future<Either<Failure, CashClosure>> close(
    DateTime date, {
    required String id,
    required String registerId,
    required bool matches,
    required int shownExpectedInCents,
    int? declaredAmountInCents,
    String? justification,
  }) => guardTreasury(
    () => _api.close(
      date,
      id: id,
      registerId: registerId,
      matches: matches,
      shownExpectedInCents: shownExpectedInCents,
      declaredAmountInCents: declaredAmountInCents,
      justification: justification,
    ),
  );

  @override
  Future<Either<Failure, Unit>> confirmAfterClosure(
    String movementId, {
    required String id,
    required bool alreadyCounted,
  }) => guardTreasury(() async {
    await _api.confirmAfterClosure(
      movementId,
      id: id,
      alreadyCounted: alreadyCounted,
    );
    return unit;
  });

  @override
  Future<Either<Failure, CashClosure>> reopen(
    String closureId, {
    required String id,
    required String reason,
  }) => guardTreasury(() => _api.reopen(closureId, id: id, reason: reason));
}
