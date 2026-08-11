import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/enrollment_local_models.dart'
    show GeneratedDocumentLocalModel;
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_generated_document.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_charge_seed_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_ledger_read_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_ledger_sync_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_payment_ack_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_payment_write_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_sync_models.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';

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
///
/// Aucune méthode ne franchit deux responsabilités : chacune ouvre sa propre
/// transaction dans son DAO, la garantie money-grade est portée là où elle vit.
class FinanceLocalDao {
  final FinancePaymentWriteDao _write;
  final FinancePaymentAckDao _ack;
  final FinanceChargeSeedDao _seed;
  final FinanceLedgerSyncDao _sync;
  final FinanceLedgerReadDao _read;

  FinanceLocalDao(Database db, IdGenerator idGenerator)
    : _write = FinancePaymentWriteDao(db),
      _ack = FinancePaymentAckDao(db),
      _seed = FinanceChargeSeedDao(db, idGenerator),
      _sync = FinanceLedgerSyncDao(db),
      _read = FinanceLedgerReadDao(db);

  // ── Encaissement local-first (FF3) ─────────────────────────────────────────

  Future<void> recordPayment({
    required PaymentLocalModel payment,
    required List<PaymentAllocationLocalModel> allocations,
    GeneratedDocumentLocalModel? receipt,
    required String outboxEntryId,
    String? schoolId,
    String? authorId,
    required int nowMs,
  }) => _write.recordPayment(
    payment: payment,
    allocations: allocations,
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

  Future<void> upsertLedger({
    List<StudentChargeLocalModel> charges = const [],
    List<PaymentLocalModel> payments = const [],
    List<PaymentAllocationLocalModel> allocations = const [],
  }) => _sync.upsertLedger(
    charges: charges,
    payments: payments,
    allocations: allocations,
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
}
