import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
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
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_payer_identity.dart';
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
      // Invariant FRONT §6 step7 / §8 : le total du paiement = Σ des
      // allocations — **devise par devise**.
      //
      // Le serveur a resserré `ALLOCATION_SUM_MISMATCH` : un total juste
      // globalement mais mal réparti est désormais refusé. La comparaison
      // scalaire d'avant laissait passer 1 000 $ + 2 000 FC déclarés contre
      // 2 000 $ + 1 000 FC imputés — le total « collait », la répartition non.
      // Le 422 tombait alors sur de l'argent physiquement reçu, reçu déjà
      // imprimé, et l'immobilisait en SYNC_ERROR. Ce fail-fast LOCAL est ce qui
      // l'empêche d'arriver.
      final allocationsBag = MoneyBag.sumBy(
        draft.allocations,
        (a) => Money.parse(a.amountInCents, a.currency),
      );
      final declaredBag = draft.amountInCents == null
          ? allocationsBag
          : MoneyBag.of([Money.parse(draft.amountInCents!, draft.currency)]);

      if (declaredBag != allocationsBag) {
        return Left(
          ValidationFailure(
            'Total du paiement ($declaredBag) ≠ somme des allocations '
            '($allocationsBag), devise par devise.',
          ),
        );
      }

      // Le contrat de push porte encore un montant scalaire (D2 non livré) : un
      // versement à deux devises ne peut pas remonter. L'UI le refuse déjà
      // (`_isMixedCurrency`) ; cette garde-ci ferme le chemin programmatique,
      // parce que c'est ici que l'argent devient une écriture.
      final sole = allocationsBag.soleEntry;
      if (sole == null) {
        return Left(
          ValidationFailure(
            'Un versement ne peut pas porter plusieurs devises tant que le '
            'contrat de synchro n\'en accepte qu\'une ($allocationsBag).',
          ),
        );
      }
      final total = sole.amountInCents;

      final payment = PaymentLocalModel(
        id: paymentId,
        clientUuid: paymentId,
        studentId: draft.studentId,
        academicYearId: draft.academicYearId,
        amountInCents: total,
        // La devise vient des IMPUTATIONS, pas du brouillon : c'est elle qui
        // fait foi côté serveur (`allocation.currency == charge.currency`), et
        // les deux ne peuvent plus diverger puisqu'elles viennent d'être
        // comparées.
        currency: sole.currency,
        method: draft.method ?? 'CASH',
        paidAt: draft.paidAt,
        payerFirstName: draft.payerFirstName,
        payerLastName: draft.payerLastName,
        payerMiddleName: draft.payerMiddleName,
        payerPhoneNumber: draft.payerPhoneNumber,
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
  Future<Either<Failure, List<LocalPayerIdentity>>> getPayerSuggestions(
    String studentId, {
    int limit = 8,
  }) async {
    try {
      return Right(await _dao.getPayerSuggestions(studentId, limit: limit));
    } catch (_) {
      // Une suggestion est un confort : base illisible → l'écran retombe sur la
      // saisie manuelle, qui n'a jamais cessé d'être offerte. Jamais de
      // remontée bruyante, l'encaissement n'en dépend pas.
      return const Left(StorageFailure('Failed to read payer suggestions'));
    }
  }

  @override
  Future<Either<Failure, List<LocalPayerIdentity>>> searchPayers({
    String? lastName,
    String? firstName,
    String? surname,
    String? phoneNumber,
    int limit = 20,
  }) async {
    try {
      return Right(
        await _dao.searchPayers(
          lastName: lastName,
          firstName: firstName,
          surname: surname,
          phoneNumber: phoneNumber,
          limit: limit,
        ),
      );
    } catch (_) {
      return const Left(StorageFailure('Failed to search payers'));
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
