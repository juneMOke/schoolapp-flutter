import 'dart:async';

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
/// au read** (FRONT §5), **sans rien attendre** : la revalidation ciblée
/// (§6 step 2) part en même temps mais n'est pas awaitée, et annonce son
/// aboutissement sur `FinanceLedgerRefresher.revalidated` — c'est l'écran qui
/// relit alors. Attendue, elle tenait le skeleton du détail élève jusqu'à ~22 s
/// en réseau dégradé pour afficher des lignes **déjà en base**. L'attente ne
/// subsiste que devant l'**encaissement**, seul endroit où elle borne un risque
/// d'argent, et `FACTURATION_OFFLINE_PLAN.md` §13 ne l'avait jamais placée
/// ailleurs.
///
/// L'UI online (BLoC + widgets) reste inchangée : elle consomme des
/// [StudentCharge] enrichis via les mappers. L'édition admin
/// (`updateStudentChargeExpectedAmount`) reste **déléguée à l'online** (hors
/// périmètre offline-first).
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
      // Revalidation ciblée lancée AVANT la lecture pour partir au plus tôt,
      // mais délibérément NON attendue : ce qui est lent ici c'est le réseau,
      // pas la base. L'endpoint `ledger?studentId` exige l'année — sans elle
      // (flux brouillon du wizard), il n'y a rien à tirer.
      if (academicYearId != null) {
        unawaited(_refresh(studentId, academicYearId));
      }
      final local = await _dao.getChargesByStudent(studentId);
      final scoped = academicYearId == null
          ? local
          : local.where((c) => c.belongsToYear(academicYearId)).toList();
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
