import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_closure.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_movement.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_period.dart';

/// La journée de caisse et ses gestes — **en ligne seulement** : la clôture est
/// impossible hors ligne (D2).
abstract class TreasuryDayRepository {
  Future<Either<Failure, TreasuryDay>> day(DateTime date);

  Future<Either<Failure, List<CashMovement>>> movements(
    DateTime date, {
    required String registerId,
    MovementDirection? direction,
  });

  /// Clôture une caisse aujourd'hui. [id] est la clé de rejeu du geste ;
  /// [shownExpectedInCents] le reste que la modale a montré.
  Future<Either<Failure, CashClosure>> close(
    DateTime date, {
    required String id,
    required String registerId,
    required bool matches,
    required int shownExpectedInCents,
    int? declaredAmountInCents,
    String? justification,
  });

  /// Répond à une ligne arrivée après une clôture (R19).
  Future<Either<Failure, Unit>> confirmAfterClosure(
    String movementId, {
    required String id,
    required bool alreadyCounted,
  });

  /// Rouvre la clôture du jour (promoteur, R20).
  Future<Either<Failure, CashClosure>> reopen(
    String closureId, {
    required String id,
    required String reason,
  });

  /// Une semaine ou un mois (B7), dates de l'école incluses.
  Future<Either<Failure, TreasuryPeriod>> period(DateTime from, DateTime to);
}
