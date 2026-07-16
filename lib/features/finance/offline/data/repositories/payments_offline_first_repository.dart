import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/mappers/local_finance_online_mappers.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_ledger_refresher.dart';

/// Implémentation **offline-first** de [PaymentsRepository] (Stratégie C).
///
/// Les lectures listent les paiements LOCAUX de l'élève — mélange voulu (FRONT
/// §3) de ce poste (synchronisés ou `PENDING_SYNC`) et de l'autre poste (arrivés
/// par pull) — précédées d'un rafraîchissement ciblé best-effort (§6 step 2).
/// L'écriture (`createPayment`) reste **déléguée à l'online** : l'encaissement
/// réel passe déjà par le chemin local-first (`FinanceOfflineBloc`), ce délégué
/// n'est là que pour honorer le contrat (chemin non emprunté par l'UI).
class PaymentsOfflineFirstRepository implements PaymentsRepository {
  final FinanceLocalDao _dao;
  final LedgerRefresh _refresh;
  final PaymentsRepository _online;

  const PaymentsOfflineFirstRepository({
    required FinanceLocalDao dao,
    required LedgerRefresh refresh,
    required PaymentsRepository online,
  }) : _dao = dao,
       _refresh = refresh,
       _online = online;

  @override
  Future<Either<Failure, List<Payment>>> getPaymentsByStudentAndAcademicYear({
    required String studentId,
    required String academicYearId,
  }) async {
    try {
      await _refresh(studentId, academicYearId);
      final local = await _dao.getPaymentsByStudent(studentId);
      final scoped = local
          .where(
            (p) =>
                p.academicYearId == null || p.academicYearId == academicYearId,
          )
          .map((p) => p.toOnlineEntity())
          .toList();
      return Right(scoped);
    } catch (e) {
      return Left(
        StorageFailure('Lecture locale des paiements impossible : $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<PaymentAllocation>>>
  getPaymentAllocationsByPaymentId({required String paymentId}) async {
    try {
      final local = await _dao.getAllocationsByPayment(paymentId);
      return Right(local.map((a) => a.toOnlineEntity()).toList());
    } catch (e) {
      return Left(
        StorageFailure('Lecture locale des imputations impossible : $e'),
      );
    }
  }

  @override
  Future<Either<Failure, Payment>> createPayment({
    required String studentId,
    required String academicYearId,
    required int amountInCents,
    required String currency,
    required String payerFirstName,
    required String payerLastName,
    String? payerMiddleName,
    required List<CreatePaymentAllocationInput> allocations,
  }) => _online.createPayment(
    studentId: studentId,
    academicYearId: academicYearId,
    amountInCents: amountInCents,
    currency: currency,
    payerFirstName: payerFirstName,
    payerLastName: payerLastName,
    payerMiddleName: payerMiddleName,
    allocations: allocations,
  );
}
