import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_detail.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sales_history_period.dart';

/// L'historique des ventes du guichet — **lecture locale seule**.
abstract class BoutiqueHistoryRepository {
  Future<Either<Failure, List<SaleHistoryEntry>>> salesOfPeriod({
    required String academicYearId,
    required SalesHistoryPeriod period,
  });

  /// Une vente entière, ses lignes et la trace de son impression.
  Future<Either<Failure, SaleDetail>> saleDetail(String saleId);

  /// Note qu'un ticket est sorti de l'imprimante.
  ///
  /// **Ne rend rien et n'échoue jamais visiblement** : c'est un renseignement
  /// d'affichage, et le perdre ne coûte qu'une mention. Le faire remonter
  /// ferait afficher une erreur après une impression réussie.
  Future<void> markTicketPrinted(String saleId);
}
