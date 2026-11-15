import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/data/local/treasury_closure_dao.dart';
import 'package:school_app_flutter/features/treasury/data/online/treasury_day_api.dart';
import 'package:school_app_flutter/features/treasury/data/repositories/treasury_online.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_closure.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_movement.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_period.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_day_repository.dart';

class TreasuryDayRepositoryImpl implements TreasuryDayRepository {
  final TreasuryDayApi _api;

  /// Le verrou local des encaissements (R11) : chaque clôture lue ou faite
  /// en ligne y est recopiée, pour qu'il prenne sans attendre le flux.
  final TreasuryClosureDao? _closures;

  const TreasuryDayRepositoryImpl(this._api, {TreasuryClosureDao? closures})
    : _closures = closures;

  @override
  Future<Either<Failure, TreasuryDay>> day(DateTime date) async {
    final startedMs = _closures?.nowMs();
    final result = await guardTreasury(() => _api.day(date));
    if (result case Right(:final value) when value.isToday) {
      await _syncToday(value, startedMs ?? 0);
    }
    return result;
  }

  /// La journée d'aujourd'hui, lue en ligne, dit l'état du verrou : les
  /// caisses closes, et celles qui ne le sont plus.
  Future<void> _syncToday(TreasuryDay day, int readStartedMs) async {
    final dao = _closures;
    if (dao == null) return;
    try {
      await dao.recordRead(
        day.date,
        live: [
          for (final summary in day.registers)
            if (summary.closure != null) summary.closure!,
        ],
        openRegisterIds: [
          for (final summary in day.registers)
            if (!summary.isClosed) summary.register.id,
        ],
        readStartedMs: readStartedMs,
      );
    } catch (_) {
      // Le flux `treasury.closures` rattrapera au prochain tirage.
    }
  }

  @override
  Future<Either<Failure, TreasuryPeriod>> period(DateTime from, DateTime to) =>
      guardTreasury(() => _api.period(from, to));

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
  }) async {
    final result = await guardTreasury(
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
    await _recordOf(result);
    return result;
  }

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
  }) async {
    final result = await guardTreasury(
      () => _api.reopen(closureId, id: id, reason: reason),
    );
    await _recordOf(result);
    return result;
  }

  /// La clôture rendue, ou celle que porte le refus (déjà clôturée, déjà
  /// rouverte) : dans les deux cas, c'est l'état du serveur.
  Future<void> _recordOf(Either<Failure, CashClosure> result) => _record([
    ?result.fold(
      (failure) => failure is TreasuryRefusalFailure ? failure.closure : null,
      (closure) => closure,
    ),
  ]);

  /// Une base locale qui échoue ne fait jamais échouer le geste en ligne.
  Future<void> _record(List<CashClosure> closures) async {
    final dao = _closures;
    if (dao == null || closures.isEmpty) return;
    try {
      await dao.recordLocal(closures);
    } catch (_) {
      // Le flux `treasury.closures` rattrapera au prochain tirage.
    }
  }
}
