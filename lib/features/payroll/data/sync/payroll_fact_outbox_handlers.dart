import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_disbursement_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/local/salary_advance_dao.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_disbursement_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_outbox_handler.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_sync_api.dart';
import 'package:school_app_flutter/features/payroll/data/sync/salary_advance_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_push_failure.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

// Les deux faits de la paie : de l'argent est sorti. Un refus ne les efface
// jamais — ils restent en erreur, listés à régulariser.
//
// Un fait **annulé sur la tablette** avant d'être accusé ne part plus jamais,
// même rejoué à la main : le serveur l'enregistrerait alors que l'écran le
// montre annulé, et aucun pull ne corrigerait l'écart.

/// Le code rangé sur un fait annulé avant d'avoir été envoyé.
const String kPayrollLocallyCancelled = 'LOCALLY_CANCELLED';

/// `SALARY_ADVANCE` — une avance octroyée. Attend les gestes du mois où elle
/// commence posés avant elle.
class SalaryAdvanceOutboxHandler
    extends PayrollOutboxHandler<SalaryAdvanceRequestDto> {
  final PayrollSyncApi _api;
  final SalaryAdvanceDao _dao;

  SalaryAdvanceOutboxHandler({
    required PayrollSyncApi api,
    required SalaryAdvanceDao dao,
    required super.outbox,
    required super.currentUser,
    required super.extras,
  }) : _api = api,
       _dao = dao;

  @override
  String get aggregateType => PayrollOutbox.advance;

  @override
  Set<String> get waitsFor => const {PayrollOutbox.gesture};

  @override
  SalaryAdvanceRequestDto? parse(Object? raw) =>
      SalaryAdvanceRequestDto.tryParse(raw);

  @override
  Future<OutboxDispatchResult?> hold(
    SalaryAdvanceRequestDto request,
    String schoolId,
  ) async {
    if (!await _dao.cancellations.isCancelled(request.advance.id)) return null;
    await _dao.mark(
      request.advance.id,
      StaffSyncState.failed,
      code: kPayrollLocallyCancelled,
    );
    return const OutboxDispatchResult.acked();
  }

  @override
  Future<void> send(SalaryAdvanceRequestDto request, String schoolId) async {
    await _api.submitAdvance(extras, request.toJson());
    await _dao.mark(request.advance.id, StaffSyncState.synced);
  }

  @override
  Future<bool> reject(
    SalaryAdvanceRequestDto request,
    StaffPushFailure failure,
    String schoolId,
  ) async {
    await _dao.mark(
      request.advance.id,
      StaffSyncState.failed,
      code: failure.storedCode,
      reason: failure.reason,
    );
    return true;
  }
}

/// `PAYROLL_DISBURSEMENT` — un salaire versé. Attend, sur la même ligne, le
/// versement ou l'annulation posés avant lui ; attend aussi la validation
/// qu'il nomme (`409 PAYROLL_NOT_YET_VALIDATED`, `blocked`).
class PayrollDisbursementOutboxHandler
    extends PayrollOutboxHandler<PayrollDisbursementRequestDto> {
  final PayrollSyncApi _api;
  final PayrollDisbursementDao _dao;

  PayrollDisbursementOutboxHandler({
    required PayrollSyncApi api,
    required PayrollDisbursementDao dao,
    required super.outbox,
    required super.currentUser,
    required super.extras,
  }) : _api = api,
       _dao = dao;

  @override
  String get aggregateType => PayrollOutbox.disbursement;

  @override
  Set<String> get waitsFor => const {
    PayrollOutbox.disbursement,
    PayrollOutbox.disbursementCancellation,
  };

  @override
  PayrollDisbursementRequestDto? parse(Object? raw) =>
      PayrollDisbursementRequestDto.tryParse(raw);

  @override
  Future<OutboxDispatchResult?> hold(
    PayrollDisbursementRequestDto request,
    String schoolId,
  ) async {
    final id = request.disbursement.id;
    if (!await _dao.cancellations.isCancelled(id)) return null;
    await _dao.mark(id, StaffSyncState.failed, code: kPayrollLocallyCancelled);
    return const OutboxDispatchResult.acked();
  }

  @override
  Future<void> send(
    PayrollDisbursementRequestDto request,
    String schoolId,
  ) async {
    await _api.submitDisbursement(extras, request.toJson());
    await _dao.mark(request.disbursement.id, StaffSyncState.synced);
  }

  @override
  Future<bool> reject(
    PayrollDisbursementRequestDto request,
    StaffPushFailure failure,
    String schoolId,
  ) async {
    await _dao.mark(
      request.disbursement.id,
      StaffSyncState.failed,
      code: failure.storedCode,
      reason: failure.reason,
    );
    return true;
  }
}
