import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/enrollment_local_models.dart'
    show GeneratedDocumentLocalModel;
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Implémentation offline-first du module Facturation : encaissement local
/// (retour immédiat + flush opportuniste), lectures depuis sqflite.
class FinanceOfflineRepositoryImpl implements FinanceOfflineRepository {
  final FinanceLocalDao _dao;
  final IdGenerator _idGenerator;
  final SyncEngine _syncEngine;
  final CurrentUserContext? _currentUser;
  final int Function() _now;

  FinanceOfflineRepositoryImpl({
    required FinanceLocalDao dao,
    required IdGenerator idGenerator,
    required SyncEngine syncEngine,
    CurrentUserContext? currentUser,
    int Function()? now,
  }) : _dao = dao,
       _idGenerator = idGenerator,
       _syncEngine = syncEngine,
       _currentUser = currentUser,
       _now = now ?? systemClock;

  @override
  Future<Either<Failure, String>> recordPayment(
    RecordPaymentDraft draft,
  ) async {
    try {
      final now = _now();
      final paymentId = _idGenerator.newId();
      final allocationsTotal = draft.allocations.fold<int>(
        0,
        (s, a) => s + a.amountInCents,
      );
      final total = draft.amountInCents ?? allocationsTotal;
      // Invariant FRONT §6 step7 / §8 : le total du paiement = Σ des allocations.
      // Fail-fast LOCAL plutôt que de subir un 422 serveur qui immobiliserait
      // l'argent (paiement bloqué en SYNC_ERROR).
      if (total != allocationsTotal) {
        return Left(
          ValidationFailure(
            'Total du paiement ($total) ≠ somme des allocations '
            '($allocationsTotal).',
          ),
        );
      }

      final payment = PaymentLocalModel(
        id: paymentId,
        clientUuid: paymentId,
        studentId: draft.studentId,
        academicYearId: draft.academicYearId,
        amountInCents: total,
        currency: draft.currency,
        method: draft.method ?? 'CASH',
        paidAt: draft.paidAt,
        payerFirstName: draft.payerFirstName,
        payerLastName: draft.payerLastName,
        payerMiddleName: draft.payerMiddleName,
        updatedAt: now,
      );

      final allocations = draft.allocations
          .map(
            (a) => PaymentAllocationLocalModel(
              id: _idGenerator.newId(),
              clientUuid: _idGenerator.newId(),
              paymentId: paymentId,
              studentChargeId: a.studentChargeId,
              feeCode: a.feeCode,
              studentChargeLabel: a.studentChargeLabel,
              amountInCents: a.amountInCents,
              currency: a.currency,
            ),
          )
          .toList();

      final receipt = GeneratedDocumentLocalModel(
        id: _idGenerator.newId(),
        docDomain: 'PAYMENT',
        paymentId: paymentId,
        studentId: draft.studentId,
        docType: 'RC',
        number: 'PROV-${paymentId.substring(0, 8).toUpperCase()}',
        createdAt: now,
      );

      await _dao.recordPayment(
        payment: payment,
        allocations: allocations,
        receipt: receipt,
        outboxEntryId: _idGenerator.newId(),
        authorId: _currentUser?.uid,
        nowMs: now,
      );

      unawaited(_syncEngine.flush());
      return Right(paymentId);
    } catch (e) {
      return Left(StorageFailure('Échec de l\'encaissement local : $e'));
    }
  }

  @override
  Future<Either<Failure, List<LocalStudentCharge>>> initializeCharges({
    required String studentId,
    required String academicYearId,
    required String schoolLevelId,
    String? schoolLevelGroupId,
    String? dueFallback,
  }) async {
    try {
      final charges = await _dao.initializeChargesForStudent(
        studentId: studentId,
        academicYearId: academicYearId,
        schoolLevelId: schoolLevelId,
        schoolLevelGroupId: schoolLevelGroupId,
        dueFallback: dueFallback,
        nowMs: _now(),
      );
      return Right(charges);
    } catch (e) {
      return Left(StorageFailure('Génération de créances impossible : $e'));
    }
  }

  @override
  Future<Either<Failure, List<LocalStudentCharge>>> getCharges(
    String studentId,
  ) => _guard(() => _dao.getChargesByStudent(studentId));

  @override
  Future<Either<Failure, List<LocalPayment>>> getPayments(String studentId) =>
      _guard(() => _dao.getPaymentsByStudent(studentId));

  @override
  Future<Either<Failure, List<LocalPaymentAllocation>>> getAllocations(
    String paymentId,
  ) => _guard(() => _dao.getAllocationsByPayment(paymentId));

  Future<Either<Failure, List<T>>> _guard<T>(
    Future<List<T>> Function() run,
  ) async {
    try {
      return Right(await run());
    } catch (e) {
      return Left(StorageFailure('Lecture locale impossible : $e'));
    }
  }
}
