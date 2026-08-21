import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/device/device_identity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_author_directory.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/enrollment_local_models.dart'
    show GeneratedDocumentLocalModel;
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_generated_document.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Implémentation offline-first du module Facturation : encaissement local
/// (retour immédiat + flush opportuniste), lectures depuis sqflite.
class FinanceOfflineRepositoryImpl implements FinanceOfflineRepository {
  final FinanceLocalDao _dao;
  final IdGenerator _idGenerator;
  final SyncEngine _syncEngine;
  final CurrentUserContext? _currentUser;

  /// Résout le NOM du caissier depuis son uid (implémenté par
  /// `AuthSessionManager`). Optionnel : sans lui, la ligne porte l'uid seul.
  final OutboxAuthorDirectory? _authorDirectory;

  /// Identifiant d'installation, préfixe du numéro provisoire.
  final DeviceIdentityService? _deviceIdentity;

  final int Function() _now;

  FinanceOfflineRepositoryImpl({
    required FinanceLocalDao dao,
    required IdGenerator idGenerator,
    required SyncEngine syncEngine,
    CurrentUserContext? currentUser,
    OutboxAuthorDirectory? authorDirectory,
    DeviceIdentityService? deviceIdentity,
    int Function()? now,
  }) : _dao = dao,
       _idGenerator = idGenerator,
       _syncEngine = syncEngine,
       _currentUser = currentUser,
       _authorDirectory = authorDirectory,
       _deviceIdentity = deviceIdentity,
       _now = now ?? systemClock;

  @override
  Future<Either<Failure, String>> recordPayment(
    RecordPaymentDraft draft,
  ) async {
    try {
      final now = _now();
      // Caissier et appareil sont résolus AVANT la transaction et STAMPÉS sur
      // la ligne : le ticket provisoire est une projection de `payments`, et il
      // doit pouvoir nommer qui a encaissé des mois plus tard, sur une tablette
      // partagée, alors que l'entrée d'outbox qui portait l'auteur aura été
      // supprimée à l'ACK (RG-012-7/11). Best-effort : une identité indisponible
      // laisse les colonnes vides, jamais un encaissement en échec.
      final cashierUid = _currentUser?.uid;
      final cashier = cashierUid == null
          ? null
          : await _resolveCashier(cashierUid);
      final deviceId = await _resolveDeviceId();
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
        cashierUid: cashierUid,
        cashierFirstName: cashier?.firstName,
        cashierLastName: cashier?.lastName,
        deviceId: deviceId,
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
        number: _provisionalNumber(paymentId, deviceId),
        provisionalNumber: _provisionalNumber(paymentId, deviceId),
        createdAt: now,
      );

      await _dao.recordPayment(
        payment: payment,
        allocations: allocations,
        receipt: receipt,
        outboxEntryId: _idGenerator.newId(),
        // Garde-fou tenant de l'outbox : sans lui la colonne reste NULL et
        // l'entrée devient inéligible au flush scopé école, seul rempart
        // contre un rejeu inter-établissement après reconnexion.
        schoolId: _currentUser?.schoolId,
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
  Future<Either<Failure, bool>> hasFeeGridForYear(String academicYearId) async {
    try {
      return Right(await _dao.hasAnyTariffForYear(academicYearId));
    } catch (_) {
      // Base illisible : on ne prétend pas savoir. L'appelant traite l'échec
      // comme « grille absente » (fail-closed : mieux vaut bloquer que
      // d'annoncer un montant qu'on ne peut pas justifier).
      return const Left(StorageFailure('Failed to probe fee grid'));
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

  @override
  Future<Either<Failure, LocalGeneratedDocument?>> getPaymentReceipt(
    String paymentId,
  ) => _guard(() => _dao.getPaymentReceipt(paymentId));

  @override
  Future<Either<Failure, List<LocalFeeTariff>>> getFeeTariffsForLevel({
    required String academicYearId,
    required String schoolLevelId,
    String? schoolLevelGroupId,
  }) => _guard(
    () => _dao.getTariffsForLevel(
      academicYearId: academicYearId,
      schoolLevelId: schoolLevelId,
      schoolLevelGroupId: schoolLevelGroupId,
    ),
  );

  @override
  Future<Either<Failure, List<LocalFeeChargeAggregate>>>
  getFeeChargeAggregates({
    required String academicYearId,
    required String feeCode,
    required List<String> studentIds,
  }) => _guard(
    () => _dao.getFeeChargeAggregates(
      academicYearId: academicYearId,
      feeCode: feeCode,
      studentIds: studentIds,
    ),
  );

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } catch (e) {
      return Left(StorageFailure('Lecture locale impossible : $e'));
    }
  }

  /// Identité affichable du caissier. `null` si l'annuaire ne sait pas répondre
  /// — auquel cas le ticket taira le nom plutôt que d'inventer.
  Future<OutboxAuthorIdentity?> _resolveCashier(String uid) async {
    try {
      return await _authorDirectory?.identityOf(uid);
    } catch (_) {
      return null;
    }
  }

  /// Identifiant d'installation, généré au premier besoin. `null` si le secure
  /// storage est indisponible : l'encaissement prime sur la traçabilité.
  Future<String?> _resolveDeviceId() async {
    try {
      return await _deviceIdentity?.getOrCreateDeviceId();
    } catch (_) {
      return null;
    }
  }

  /// `PROV-<idAppareil>-<8 hex du paiement>` (RG-012-10, zone Z3).
  ///
  /// Le segment appareil est OMIS quand l'identifiant n'a pas pu être résolu :
  /// le format dégradé `PROV-<8 hex>` reste celui déjà produit sur le terrain
  /// avant la v19, donc lisible par tout ce qui existe. Deux formats coexistent
  /// délibérément — aucune migration ne réécrit les numéros déjà remis à des
  /// parents sur du papier.
  static String _provisionalNumber(String paymentId, String? deviceId) {
    final suffix = paymentId.substring(0, 8).toUpperCase();
    if (deviceId == null || deviceId.isEmpty) return 'PROV-$suffix';
    return 'PROV-${DeviceIdentityService.shorten(deviceId)}-$suffix';
  }
}
