import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/fee_tariff.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/finance_recovery.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/finance_till.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_receipts_page.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_window.dart';

abstract class FinanceRepository {
  Future<Either<Failure, List<FeeTariff>>> getFeeTariffsByLevel({
    required String levelId,
  });

  /// Le recouvrement de l'année scolaire courante — sans fenêtre à choisir.
  Future<Either<Failure, FinanceRecovery>> getFinanceRecovery();

  /// Ce qui est entré dans le tiroir sur la fenêtre — frais et boutique.
  Future<Either<Failure, FinanceTill>> getFinanceTill({
    TillWindow window = const TillWindow.day(),
  });

  /// Les paiements de la fenêtre, **toutes caisses**, page par page.
  ///
  /// Aucune devise n'est demandée : l'écran veut tous les paiements de la
  /// période, et le serveur cadre alors sur la fenêtre seule. Chaque ligne
  /// porte sa devise, et son montant s'écrit avec — rien n'invite à sommer une
  /// colonne qui mêle deux unités.
  ///
  /// ⚠️ Peut échouer en **403** là où [getFinanceTill] réussit — la lecture
  /// nominative demande une seconde permission. L'appelant doit traiter cet
  /// échec **sans** effacer les agrégats déjà affichés.
  Future<Either<Failure, TillReceiptsPage>> getTillReceipts({
    TillWindow window = const TillWindow.day(),
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
