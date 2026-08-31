import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_history_dao.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_detail.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sales_history_period.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_history_repository.dart';

/// Lecture locale de la caisse.
class BoutiqueHistoryRepositoryImpl implements BoutiqueHistoryRepository {
  final BoutiqueSaleHistoryDao _dao;
  final CurrentUserContext _currentUser;

  /// L'horloge, injectée : un test qui doit attendre minuit n'en est pas un.
  final DateTime Function() _now;

  const BoutiqueHistoryRepositoryImpl({
    required BoutiqueSaleHistoryDao dao,
    required CurrentUserContext currentUser,
    required DateTime Function() now,
  }) : _dao = dao,
       _currentUser = currentUser,
       _now = now;

  @override
  Future<Either<Failure, SaleDetail>> saleDetail(String saleId) async {
    try {
      final schoolId = _currentUser.schoolId ?? '';
      final sale = await _dao.saleById(schoolId: schoolId, saleId: saleId);
      // Une vente ouverte depuis la liste existe. Si elle a disparu — purge,
      // école changée sous la tablette —, l'écran doit le DIRE : afficher une
      // fiche vide ferait croire à une vente sans article.
      if (sale == null) return const Left(NotFoundFailure());
      return Right(
        SaleDetail(
          sale: sale,
          ticketPrintedAt: await _dao.ticketPrintedAt(
            schoolId: schoolId,
            saleId: saleId,
          ),
        ),
      );
    } catch (e) {
      return Left(StorageFailure('Vente boutique illisible : $e'));
    }
  }

  @override
  Future<void> markTicketPrinted(String saleId) async {
    try {
      await _dao.markTicketPrinted(
        saleId: saleId,
        atMs: _now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // Avalé, délibérément : le ticket EST sorti. Faire remonter l'échec
      // d'une trace d'affichage afficherait une erreur après une impression
      // réussie, et laisserait croire que le papier n'est pas valable.
    }
  }

  @override
  Future<Either<Failure, List<SaleHistoryEntry>>> salesOfPeriod({
    required String academicYearId,
    required SalesHistoryPeriod period,
  }) async {
    try {
      final rows = await _dao.salesSince(
        schoolId: _currentUser.schoolId ?? '',
        academicYearId: academicYearId,
        soldAtBound: period.boundFor(_now()),
      );
      return Right(rows);
    } catch (e) {
      // Une lecture d'affichage ne remonte pas d'exception nue : l'écran a un
      // état d'erreur, et une base illisible n'est pas une caisse vide — dire
      // « aucune vente » à un guichet qui vient d'en encaisser trois serait
      // pire qu'une erreur.
      return Left(StorageFailure('Historique boutique illisible : $e'));
    }
  }
}
