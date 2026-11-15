import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_adjustment.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';

/// Les caisses de l'école et leurs ajustements — **en ligne seulement**.
abstract class CashRegistersRepository {
  /// Les caisses, dans l'ordre de création.
  Future<Either<Failure, List<RegisterConfig>>> list();

  /// Crée la caisse d'une devise. Un nom vide devient « Caisse USD » /
  /// « Caisse CDF » côté serveur.
  Future<Either<Failure, CashRegister>> create({
    required TreasuryCurrency currency,
    required String? name,
    required int openingAmountInCents,
  });

  /// Ajuste le montant détenu. [id] est la clé de rejeu du geste ;
  /// [shownExpectedInCents] le montant actuel que l'écran a montré.
  Future<Either<Failure, CashAdjustment>> adjust({
    required String registerId,
    required String id,
    required int shownExpectedInCents,
    required int newAmountInCents,
    required String reason,
  });

  /// L'historique des ajustements d'une caisse, le plus récent en tête.
  Future<Either<Failure, List<CashAdjustment>>> adjustments(String registerId);
}
