import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/enrollment_local_models.dart'
    show GeneratedDocumentLocalModel;
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_generated_document.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/local/exchange_rate_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_charge_seed_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_ledger_read_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_ledger_sync_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_payment_ack_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_payer_directory_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_payment_write_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/reduction_catalog_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/models/reduction_catalog_local_models.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_sync_models.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/grantable_reduction.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_payer_identity.dart';

/// DAO local du module Facturation (sqflite) — **coordinateur**. Chaque
/// responsabilité vit dans un DAO focalisé (une classe, un fichier) ; ce point
/// d'entrée n'en est que la façade et délègue, pour que les appelants (repos,
/// outbox handler, pull, tests) gardent un seul type à injecter.
///
///  - encaissement local-first (FF3) → [FinancePaymentWriteDao]
///  - ACK / remap (FF4)              → [FinancePaymentAckDao]
///  - créances offline (FF5)         → [FinanceChargeSeedDao]
///  - pull autoritaire (FF2)         → [FinanceLedgerSyncDao]
///  - lectures                       → [FinanceLedgerReadDao]
///  - annuaire des payeurs           → [FinancePayerDirectoryDao]
///  - barème de réductions (ADR-021) → [ReductionCatalogDao]
///  - taux de guichet                → [ExchangeRateDao]
///
/// Aucune méthode ne franchit deux responsabilités : chacune ouvre sa propre
/// transaction dans son DAO, la garantie money-grade est portée là où elle vit.
class FinanceLocalDao {
  final FinancePaymentWriteDao _write;
  final FinancePaymentAckDao _ack;
  final FinanceChargeSeedDao _seed;
  final FinanceLedgerSyncDao _sync;
  final FinanceLedgerReadDao _read;
  final FinancePayerDirectoryDao _payers;
  final ReductionCatalogDao _reductions;
  final ExchangeRateDao _rates;

  FinanceLocalDao(Database db, IdGenerator idGenerator)
    : _write = FinancePaymentWriteDao(db),
      _ack = FinancePaymentAckDao(db),
      _seed = FinanceChargeSeedDao(db, idGenerator),
      _sync = FinanceLedgerSyncDao(db),
      _read = FinanceLedgerReadDao(db),
      _payers = FinancePayerDirectoryDao(db),
      _reductions = ReductionCatalogDao(db),
      _rates = ExchangeRateDao(db);

  // ── Taux de guichet ────────────────────────────────────────────────────────

  /// Cf. `ExchangeRateDao.upsert`.
  Future<void> upsertExchangeRate(ExchangeRateLocalModel rate) =>
      _rates.upsert(rate);

  /// Cf. `ExchangeRateDao.replaceForSchool`.
  Future<void> replaceExchangeRatesForSchool(
    List<ExchangeRateLocalModel> rates, {
    required String schoolId,
  }) => _rates.replaceForSchool(rates, schoolId: schoolId);

  /// Cf. `ExchangeRateDao.ratesForSchool`.
  Future<List<ExchangeRate>> exchangeRatesForSchool(String schoolId) =>
      _rates.ratesForSchool(schoolId);

  // ── Encaissement local-first (FF3) ─────────────────────────────────────────

  Future<void> recordPayment({
    required PaymentLocalModel payment,
    required List<PaymentAllocationLocalModel> allocations,
    List<PaymentTenderLocalModel> tenders = const [],
    GeneratedDocumentLocalModel? receipt,
    required String outboxEntryId,
    String? schoolId,
    String? authorId,
    required int nowMs,
  }) => _write.recordPayment(
    payment: payment,
    allocations: allocations,
    tenders: tenders,
    receipt: receipt,
    outboxEntryId: outboxEntryId,
    schoolId: schoolId,
    authorId: authorId,
    nowMs: nowMs,
  );

  // ── ACK / remap (FF4) ──────────────────────────────────────────────────────

  Future<void> applyPaymentAck(
    PaymentAggregateResponse ack, {
    required int nowMs,
  }) => _ack.applyPaymentAck(ack, nowMs: nowMs);

  // ── Créances offline (FF5) ─────────────────────────────────────────────────

  /// Cf. `FinanceChargeSeedDao.hasAnyTariffForYear`.
  Future<bool> hasAnyTariffForYear(String academicYearId) =>
      _seed.hasAnyTariffForYear(academicYearId);

  Future<List<LocalStudentCharge>> initializeChargesForStudent({
    required String studentId,
    required String academicYearId,
    required String schoolLevelId,
    String? schoolLevelGroupId,
    String? dueFallback,
    required int nowMs,
  }) => _seed.initializeChargesForStudent(
    studentId: studentId,
    academicYearId: academicYearId,
    schoolLevelId: schoolLevelId,
    schoolLevelGroupId: schoolLevelGroupId,
    dueFallback: dueFallback,
    nowMs: nowMs,
  );

  // ── Pull autoritaire (FF2) ─────────────────────────────────────────────────

  Future<void> replaceTariffsForYears(
    List<FeeTariffLocalModel> tariffs, {
    required List<String> academicYearIds,
  }) => _sync.replaceTariffsForYears(tariffs, academicYearIds: academicYearIds);

  /// Barème de réductions du bundle (racine, scopé ÉCOLE et non année).
  Future<void> replaceReductionCatalogForSchool(
    List<ReductionTypeLocalModel> types,
    List<ReductionLineLocalModel> lines, {
    required String schoolId,
  }) => _reductions.replaceForSchool(types, lines, schoolId: schoolId);

  /// Réductions proposables au guichet pour cette école (ADR-021 V1).
  Future<List<GrantableReduction>> grantableReductionsForSchool(
    String schoolId,
  ) => _reductions.grantableForSchool(schoolId);

  Future<void> upsertLedger({
    List<StudentChargeLocalModel> charges = const [],
    List<PaymentLocalModel> payments = const [],
    List<PaymentAllocationLocalModel> allocations = const [],
    List<PaymentTenderLocalModel> tenders = const [],
  }) => _sync.upsertLedger(
    charges: charges,
    payments: payments,
    allocations: allocations,
    tenders: tenders,
  );

  // ── Lectures ────────────────────────────────────────────────────────────────

  Future<List<LocalStudentCharge>> getChargesByStudent(String studentId) =>
      _read.getChargesByStudent(studentId);

  Future<List<LocalPayment>> getPaymentsByStudent(String studentId) =>
      _read.getPaymentsByStudent(studentId);

  Future<LocalGeneratedDocument?> getPaymentReceipt(String paymentId) =>
      _read.getPaymentReceipt(paymentId);

  Future<List<LocalPaymentAllocation>> getAllocationsByPayment(
    String paymentId,
  ) => _read.getAllocationsByPayment(paymentId);

  Future<List<LocalPaymentAllocation>> getAllocationsByCharge(
    String chargeId,
  ) => _read.getAllocationsByCharge(chargeId);

  Future<List<LocalFeeTariff>> getTariffsByLevel(String schoolLevelId) =>
      _read.getTariffsByLevel(schoolLevelId);

  Future<List<LocalFeeTariff>> getTariffsForLevel({
    required String academicYearId,
    required String schoolLevelId,
    String? schoolLevelGroupId,
  }) => _read.getTariffsForLevel(
    academicYearId: academicYearId,
    schoolLevelId: schoolLevelId,
    schoolLevelGroupId: schoolLevelGroupId,
  );

  Future<List<LocalFeeChargeAggregate>> getFeeChargeAggregates({
    required String academicYearId,
    required String feeCode,
    required List<String> studentIds,
  }) => _read.getFeeChargeAggregates(
    academicYearId: academicYearId,
    feeCode: feeCode,
    studentIds: studentIds,
  );

  // ── Annuaire des payeurs ───────────────────────────────────────────────────

  Future<List<LocalPayerIdentity>> getPayerSuggestions(
    String studentId, {
    int limit = 8,
  }) => _payers.payersForStudent(studentId, limit: limit);

  Future<List<LocalPayerIdentity>> searchPayers({
    String? lastName,
    String? firstName,
    String? surname,
    String? phoneNumber,
    int limit = 20,
  }) => _payers.searchPayers(
    lastName: lastName,
    firstName: firstName,
    surname: surname,
    phoneNumber: phoneNumber,
    limit: limit,
  );
}
