import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_beneficiary_dao.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_history_dao.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_sale_row.dart';
import 'package:school_app_flutter/features/boutique/data/local/sold_at_bound.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/provisional_sales.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_detail.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_history_repository.dart';

/// Lecture locale de la caisse.
class BoutiqueHistoryRepositoryImpl implements BoutiqueHistoryRepository {
  final BoutiqueSaleHistoryDao _dao;
  final BoutiqueSaleBeneficiaryDao _beneficiaries;
  final CurrentUserContext _currentUser;

  /// L'horloge, injectée : un test qui doit attendre minuit n'en est pas un.
  final DateTime Function() _now;

  const BoutiqueHistoryRepositoryImpl({
    required BoutiqueSaleHistoryDao dao,
    required BoutiqueSaleBeneficiaryDao beneficiaries,
    required CurrentUserContext currentUser,
    required DateTime Function() now,
  }) : _dao = dao,
       _beneficiaries = beneficiaries,
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
      final ticketPrintedAt = await _dao.ticketPrintedAt(
        schoolId: schoolId,
        saleId: saleId,
      );
      final (named, beneficiaries) = await _nameBeneficiaries(sale);
      return Right(
        SaleDetail(
          sale: named,
          ticketPrintedAt: ticketPrintedAt,
          beneficiaries: beneficiaries,
        ),
      );
    } catch (e) {
      return Left(StorageFailure('Vente boutique illisible : $e'));
    }
  }

  /// Nomme les élèves que le delta a laissés anonymes, et les liste.
  ///
  /// Les lignes nommées repartent dans la vente : le ticket réimprimé depuis la
  /// fiche les lit, et dit alors « Pour : … » comme le ticket du guichet.
  ///
  /// ⚠️ Un échec de cette lecture ne fait **jamais** tomber la fiche : la vente
  /// se lit sans les noms, comme avant — une fiche illisible pour un nom
  /// manquant serait un recul.
  Future<(RecordedSale, List<SaleBeneficiary>)> _nameBeneficiaries(
    RecordedSale sale,
  ) async {
    // Un ensemble ordonné : chaque élève une fois, dans l'ordre des lignes.
    final ids = <String>{
      for (final line in sale.lines)
        if ((line.beneficiaryStudentId ?? '').isNotEmpty)
          line.beneficiaryStudentId!,
    }.toList();
    if (ids.isEmpty) return (sale, const <SaleBeneficiary>[]);

    Map<String, SaleBeneficiary> known = const {};
    try {
      known = await _beneficiaries.lookup(
        academicYearId: sale.sale.academicYearId,
        studentIds: ids,
      );
    } catch (_) {}

    final frozen = <String, String>{
      for (final line in sale.lines.reversed)
        if ((line.beneficiaryName ?? '').trim().isNotEmpty &&
            line.beneficiaryStudentId != null)
          line.beneficiaryStudentId!: line.beneficiaryName!.trim(),
    };
    String? nameOf(String id) => frozen[id] ?? known[id]?.fullName;

    return (
      RecordedSale(
        sale: sale.sale,
        lines: [
          for (final line in sale.lines)
            (line.beneficiaryName ?? '').trim().isEmpty &&
                    line.beneficiaryStudentId != null
                ? line.withBeneficiaryName(nameOf(line.beneficiaryStudentId!))
                : line,
        ],
      ),
      [
        for (final id in ids)
          SaleBeneficiary(
            studentId: id,
            fullName: nameOf(id),
            classId: known[id]?.classId,
            classLabel: known[id]?.classLabel,
          ),
      ],
    );
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
  Future<Either<Failure, List<SaleHistoryEntry>>> latestSales({
    required String academicYearId,
    required DashboardWindow window,
    required int limit,
  }) async {
    try {
      return Right(
        await _dao.salesBetween(
          schoolId: _currentUser.schoolId ?? '',
          academicYearId: academicYearId,
          fromBound: SoldAtBound.of(window.startInstant),
          toBound: SoldAtBound.of(window.endInstantExclusive),
          limit: limit,
        ),
      );
    } catch (e) {
      return Left(StorageFailure('Dernières ventes boutique illisibles : $e'));
    }
  }

  @override
  Future<Either<Failure, ProvisionalSales>> provisionalSales({
    required String academicYearId,
    required DashboardWindow window,
  }) async {
    try {
      return Right(
        ProvisionalSales(
          await _dao.provisionalLines(
            schoolId: _currentUser.schoolId ?? '',
            academicYearId: academicYearId,
            fromBound: SoldAtBound.of(window.startInstant),
            toBound: SoldAtBound.of(window.endInstantExclusive),
          ),
        ),
      );
    } catch (e) {
      // Une base illisible n'est pas « aucun ticket en attente » : le dire
      // ferait croire au guichet que tout est parti.
      return Left(StorageFailure('Tickets provisoires illisibles : $e'));
    }
  }
}
