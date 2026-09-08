import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/fee_tariff.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/finance_recovery.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/finance_till.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_receipts_page.dart';
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

  /// Les reçus **d'une caisse** sur la fenêtre, page par page.
  ///
  /// [currency] n'a pas de défaut, et c'est délibéré : la table décrit une
  /// caisse. Un appel sans devise part en 400 côté serveur, et un défaut ici
  /// n'aurait fait que déplacer l'ambiguïté d'un étage.
  ///
  /// ⚠️ Peut échouer en **403** là où [getFinanceTill] réussit — la lecture
  /// nominative demande une seconde permission. L'appelant doit traiter cet
  /// échec **sans** effacer les agrégats déjà affichés.
  Future<Either<Failure, TillReceiptsPage>> getTillReceipts({
    required String currency,
    TillPeriod period = TillPeriod.day,
    int page = 0,
    int size = TillReceiptsQuery.defaultPageSize,
  });
}

/// Les bornes que le serveur impose à la table nominative.
abstract final class TillReceiptsQuery {
  /// Ce que la maquette pagine, et ce que le serveur prend par défaut.
  static const int defaultPageSize = 8;

  /// Au-delà, le serveur répond **400** — jamais un écrêtage silencieux, qui
  /// ferait conclure d'une réponse courte que la fenêtre est creuse.
  static const int maxPageSize = 100;
}
