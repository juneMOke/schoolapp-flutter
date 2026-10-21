import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/provisional_sales.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_detail.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';

/// Les ventes enregistrées sur le poste — **lecture locale seule** : les
/// dernières, les tickets provisoires, et la fiche d'une vente.
abstract class BoutiqueHistoryRepository {
  /// Les [limit] dernières ventes de [window], provisoires comprises — lues
  /// ici et non au serveur : le poste les détient toutes, et c'est ce qui lui
  /// montre aussi celles qui ne sont pas encore parties.
  Future<Either<Failure, List<SaleHistoryEntry>>> latestSales({
    required String academicYearId,
    required DashboardWindow window,
    required int limit,
  });

  /// Les tickets de [window] que le serveur ne connaît pas encore.
  Future<Either<Failure, ProvisionalSales>> provisionalSales({
    required String academicYearId,
    required DashboardWindow window,
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
