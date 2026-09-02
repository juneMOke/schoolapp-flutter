import 'package:dio/dio.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/exchange_rate_remote_data_source.dart';
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/tender_composition.dart';
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

  /// Publie le taux chez le serveur. `null` = ce build ne le fait pas — la pose
  /// reste alors locale, et le pull l'effacera : c'est le régime des tests, pas
  /// celui de l'application.
  final ExchangeRateRemoteDataSource? _rates;

  /// Les extras d'authentification exigés par l'intercepteur.
  final Map<String, dynamic>? _requiredAuth;

  FinanceOfflineRepositoryImpl({
    required FinanceLocalDao dao,
    required IdGenerator idGenerator,
    required SyncEngine syncEngine,
    CurrentUserContext? currentUser,
    OutboxAuthorDirectory? authorDirectory,
    DeviceIdentityService? deviceIdentity,
    int Function()? now,
    ExchangeRateRemoteDataSource? rates,
    Map<String, dynamic>? requiredAuth,
  }) : _dao = dao,
       _idGenerator = idGenerator,
       _syncEngine = syncEngine,
       _currentUser = currentUser,
       _authorDirectory = authorDirectory,
       _deviceIdentity = deviceIdentity,
       _now = now ?? systemClock,
       _rates = rates,
       _requiredAuth = requiredAuth;

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
      final declaredBag = draft.amounts ?? allocationsBag;

      if (declaredBag != allocationsBag) {
        return Left(
          ValidationFailure(
            'Total du paiement ($declaredBag) ≠ somme des allocations '
            '($allocationsBag), devise par devise.',
          ),
        );
      }

      // Un versement à deux devises est désormais un cas NOMINAL : c'est un
      // acte de guichet, donc un versement, un reçu, une notification — pas
      // deux. La garde qui l'interdisait ici a tenu la place le temps que le
      // contrat porte `amounts[]`.
      //
      // Reste le refus du versement vide : rien à encaisser n'est pas un
      // encaissement.
      if (allocationsBag.isEmpty || allocationsBag.isAllZero) {
        return const Left(ValidationFailure('Aucun montant à encaisser.'));
      }

      // SECONDE garde, et elle porte sur autre chose que la première.
      //
      // Celle du dessus compare de l'imputé à de l'imputé — `amounts` est en
      // devise de créance — et reste juste quoi qu'il arrive. Celle-ci confronte
      // ce qui est entré dans le TIROIR à ce qui a été imputé, via le taux :
      // sans elle, encaisser 100 000 FC pour une créance de 50 $ quand le taux
      // du jour en vaut 145 000 laisse la créance éteinte, la caisse cohérente,
      // et 45 000 FC partis — invisible à tout contrôle existant.
      //
      // `null` = le parent a réglé dans la devise de la créance : l'identité,
      // c'est-à-dire le cas courant, qui ne coûte aucune arithmétique.
      final tenderDrafts =
          draft.tenders ??
          TenderComposition.identityFor(allocationsBag.entries);
      final violation = TenderComposition.check(
        allocations: allocationsBag.entries,
        tenders: tenderDrafts,
      );
      if (violation != null) {
        return Left(ValidationFailure(violation.message));
      }

      final payment = PaymentLocalModel(
        id: paymentId,
        clientUuid: paymentId,
        studentId: draft.studentId,
        academicYearId: draft.academicYearId,
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
              feeTariffId: a.feeTariffId,
              feeCode: a.feeCode,
              studentChargeLabel: a.studentChargeLabel,
              amountInCents: a.amountInCents,
              currency: a.currency,
            ),
          )
          .toList();

      final tenders = [
        for (final tender in tenderDrafts)
          PaymentTenderLocalModel(
            id: _idGenerator.newId(),
            clientUuid: _idGenerator.newId(),
            paymentId: paymentId,
            amountInCents: tender.amountInCents,
            currency: tender.currency,
            rateMicros: tender.rateMicros,
            pivotCurrency: tender.pivotCurrency,
          ),
      ];

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
        tenders: tenders,
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
  Future<Either<Failure, List<ExchangeRate>>> getExchangeRates() async {
    try {
      // Scopé depuis la session, jamais depuis un payload : un taux d'une école
      // servi au guichet d'une autre est un défaut d'argent. Sans école
      // résolue, le DAO rend une liste vide et la bascule reste éteinte — le
      // guichet propose un taux, il ne l'invente pas.
      final schoolId = _currentUser?.schoolId ?? '';
      return Right(await _dao.exchangeRatesForSchool(schoolId));
    } catch (_) {
      // Une série illisible n'empêche pas d'encaisser : l'écran retombe sur le
      // règlement dans la devise de la créance, qui n'a jamais cessé d'être
      // offert. Une lecture ne fait pas échouer un versement.
      return const Left(StorageFailure('Failed to read exchange rates'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveExchangeRate({
    required String base,
    required String quote,
    required int rateMicros,
    required DateTime effectiveFrom,
    int? divergenceBandBp,
  }) async {
    // Un taux nul ou négatif diviserait ou inverserait de l'argent, et une paire
    // incomplète ne se résout jamais : on refuse ici plutôt que d'écrire une
    // ligne que la lecture écarterait en silence — le paramétrage semblerait
    // alors sans effet.
    if (rateMicros <= 0) {
      return const Left(ValidationFailure('Taux de guichet invalide.'));
    }
    final normalizedBase = CurrencyCode.normalize(base);
    final normalizedQuote = CurrencyCode.normalize(quote);
    if (normalizedBase.isEmpty || normalizedQuote.isEmpty) {
      return const Left(ValidationFailure('Devises du taux incomplètes.'));
    }
    if (normalizedBase == normalizedQuote) {
      return const Left(
        ValidationFailure('Un taux relie deux devises différentes.'),
      );
    }
    final schoolId = _currentUser?.schoolId ?? '';
    if (schoolId.isEmpty) {
      return const Left(
        ValidationFailure('Aucune école résolue pour ce paramétrage.'),
      );
    }

    try {
      // Le serveur d'abord : c'est lui qui publie le taux, et le pull le
      // redescendra à tous les postes. Écrire d'abord en local donnerait un
      // guichet qui applique un taux que la direction croit posé — et que le
      // premier cycle de synchro effacerait.
      final publisher = _rates;
      if (publisher != null) {
        await publisher.publish(
          _requiredAuth ?? const {},
          base: normalizedBase,
          quote: normalizedQuote,
          rateMicros: rateMicros,
          divergenceBandBp: divergenceBandBp,
        );
      }
      await _dao.upsertExchangeRate(
        ExchangeRateLocalModel(
          schoolId: schoolId,
          base: normalizedBase,
          quote: normalizedQuote,
          effectiveFrom: effectiveFrom.toUtc().toIso8601String(),
          rateMicros: rateMicros,
          divergenceBandBp: divergenceBandBp,
          setBy: _currentUser?.uid,
          syncedAt: _now(),
        ),
      );
      return const Right(unit);
    } on DioException catch (e) {
      // Le serveur a refusé, ou la liaison a lâché. **Rien n'est écrit en
      // local** : un taux qui s'afficherait posé sans exister chez le serveur
      // disparaîtrait au premier pull, et la direction croirait avoir paramétré
      // ce que le guichet n'a jamais eu.
      final code = e.response?.statusCode;
      if (code == 403) {
        return const Left(
          ValidationFailure(
            'Ce compte ne peut pas poser de taux : demandez à la direction.',
          ),
        );
      }
      if (code == 422) {
        return const Left(
          ValidationFailure(
            'Taux refusé : un taux ne se pose pas dans le passé, et une devise '
            'vers elle-même n\'est pas un taux.',
          ),
        );
      }
      return const Left(
        NetworkFailure(
          'Taux non enregistré — la connexion est nécessaire pour le publier.',
        ),
      );
    } catch (e) {
      return Left(StorageFailure('Échec de l\'écriture du taux : $e'));
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
