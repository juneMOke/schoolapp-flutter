import 'package:dio/dio.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/exchange_rate_remote_data_source.dart';
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/device/device_identity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_author_directory.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/payment_composer.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_generated_document.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_level_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
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

  final int Function() _now;

  /// Les gardes et la composition d'un encaissement, partagées avec la
  /// correction d'un versement. Il résout aussi le NOM du caissier
  /// (`authorDirectory`) et l'identifiant d'installation (`deviceIdentity`),
  /// préfixe du numéro provisoire.
  final PaymentComposer _composer;

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
       _now = now ?? systemClock,
       _rates = rates,
       _requiredAuth = requiredAuth,
       _composer = PaymentComposer(
         idGenerator: idGenerator,
         currentUser: currentUser,
         authorDirectory: authorDirectory,
         deviceIdentity: deviceIdentity,
       );

  @override
  Future<Either<Failure, String>> recordPayment(
    RecordPaymentDraft draft,
  ) async {
    try {
      final now = _now();
      // Gardes money-grade et composition des lignes : partagées avec le
      // remplaçant d'une correction de versement (`PaymentComposer`).
      final composed = await _composer.compose(draft, nowMs: now);
      final failure = composed.fold<Failure?>((f) => f, (_) => null);
      if (failure != null) return Left(failure);
      final lines = composed.fold((_) => null, (c) => c)!;
      final payment = lines.payment;
      final allocations = lines.allocations;
      final tenders = lines.tenders;
      final receipt = lines.receipt;
      final paymentId = payment.id;

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
  Future<Either<Failure, Map<String, String>>> getFeeSectionTitles() async {
    try {
      // Scopé depuis la session, comme les taux : sur une tablette partagée, le
      // titre d'une école servi à l'autre renommerait des frais qui ne sont pas
      // les siens. Sans école résolue, le DAO rend une table vide et les écrans
      // nomment par la nature localisée.
      final schoolId = _currentUser?.schoolId ?? '';
      return Right(await _dao.feeSectionTitlesForSchool(schoolId));
    } catch (_) {
      // Un cache illisible ne fait pas tomber une fiche : elle se nomme par la
      // nature localisée, ce qu'elle faisait déjà avant que ce cache existe.
      return const Left(StorageFailure('Failed to read fee section titles'));
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

  @override
  Future<Either<Failure, List<String>>> getFeeCodesForYear(
    String academicYearId,
  ) => _guard(() => _dao.getFeeCodesForYear(academicYearId));

  @override
  Future<Either<Failure, List<LocalFeeLevelAggregate>>>
  getFeeChargePositionsByLevel({
    required String academicYearId,
    required String feeCode,
    String? schoolLevelGroupId,
  }) => _guard(
    () => _dao.getFeeChargePositionsByLevel(
      academicYearId: academicYearId,
      feeCode: feeCode,
      schoolLevelGroupId: schoolLevelGroupId,
    ),
  );

  @override
  Future<Either<Failure, List<LocalRecoveryLine>>> getRecoveryPositions({
    required String academicYearId,
    required List<String> feeCodes,
    String? schoolLevelGroupId,
  }) => _guard(
    () => _dao.getRecoveryPositions(
      academicYearId: academicYearId,
      feeCodes: feeCodes,
      schoolLevelGroupId: schoolLevelGroupId,
    ),
  );

  @override
  Future<Either<Failure, int>> countPendingPayments() =>
      _guard(_dao.countPendingPayments);

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } catch (e) {
      return Left(StorageFailure('Lecture locale impossible : $e'));
    }
  }
}
