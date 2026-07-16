import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/student_charges_repository.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/mappers/local_finance_online_mappers.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_ledger_refresher.dart';

/// Implémentation **offline-first** de [StudentChargesRepository] (Stratégie C).
///
/// Les lectures sont servies par le grand-livre LOCAL avec le **reste composé
/// au read** (FRONT §5), précédées d'un **rafraîchissement ciblé** best-effort
/// (§6 step 2) qui peuple le local si le réseau est là. L'UI online (BLoC +
/// widgets) reste inchangée : elle consomme des [StudentCharge] enrichis via les
/// mappers. L'édition admin (`updateStudentChargeExpectedAmount`) reste
/// **déléguée à l'online** (hors périmètre offline-first).
class StudentChargesOfflineFirstRepository implements StudentChargesRepository {
  final FinanceLocalDao _dao;
  final LedgerRefresh _refresh;
  final StudentChargesRepository _online;

  const StudentChargesOfflineFirstRepository({
    required FinanceLocalDao dao,
    required LedgerRefresh refresh,
    required StudentChargesRepository online,
  }) : _dao = dao,
       _refresh = refresh,
       _online = online;

  @override
  Future<Either<Failure, List<StudentCharge>>> getStudentCharges({
    required String studentId,
    required String levelId,
  }) => _readCharges(studentId, academicYearId: null);

  @override
  Future<Either<Failure, List<StudentCharge>>> getStudentChargesByAcademicYear({
    required String studentId,
    required String academicYearId,
  }) => _readCharges(studentId, academicYearId: academicYearId);

  Future<Either<Failure, List<StudentCharge>>> _readCharges(
    String studentId, {
    required String? academicYearId,
  }) async {
    try {
      // Rafraîchissement ciblé (best-effort) AVANT la lecture — l'endpoint
      // ledger?studentId exige l'année, donc on ne peut le tenter que si connue.
      if (academicYearId != null) {
        await _refresh(studentId, academicYearId);
      }
      final local = await _dao.getChargesByStudent(studentId);
      final scoped = academicYearId == null
          ? local
          : local
                .where(
                  (c) =>
                      c.academicYearId == null ||
                      c.academicYearId == academicYearId,
                )
                .toList();
      return Right(scoped.map((c) => c.toOnlineEntity()).toList());
    } catch (e) {
      return Left(
        StorageFailure('Lecture locale des créances impossible : $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<PaymentAllocation>>>
  getPaymentAllocationsByChargeId({required String chargeId}) async {
    try {
      final local = await _dao.getAllocationsByCharge(chargeId);
      return Right(local.map((a) => a.toOnlineEntity()).toList());
    } catch (e) {
      return Left(
        StorageFailure('Lecture locale des imputations impossible : $e'),
      );
    }
  }

  @override
  Future<Either<Failure, StudentCharge>> updateStudentChargeExpectedAmount({
    required String studentChargeId,
    required String studentId,
    required double expectedAmountInCents,
  }) => _online.updateStudentChargeExpectedAmount(
    studentChargeId: studentChargeId,
    studentId: studentId,
    expectedAmountInCents: expectedAmountInCents,
  );
}
