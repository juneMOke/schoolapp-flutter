import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_deduction_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_deduction_type_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_deduction_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_outbox_handler.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_sync_api.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction_codes.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_gate.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_push_failure.dart';

/// `PAYROLL_DEDUCTION_TYPE` — une rubrique du catalogue. Une pierre tombale
/// la retire : elle a été supprimée, elle ne revient pas.
class PayrollDeductionTypeOutboxHandler
    extends PayrollOutboxHandler<PayrollDeductionTypeRequestDto> {
  final PayrollSyncApi _api;
  final PayrollDeductionTypeDao _dao;

  PayrollDeductionTypeOutboxHandler({
    required PayrollSyncApi api,
    required PayrollDeductionTypeDao dao,
    required super.outbox,
    required super.currentUser,
    required super.extras,
  }) : _api = api,
       _dao = dao;

  @override
  String get aggregateType => PayrollOutbox.deductionType;

  @override
  PayrollDeductionTypeRequestDto? parse(Object? raw) =>
      PayrollDeductionTypeRequestDto.tryParse(raw);

  @override
  Future<void> send(
    PayrollDeductionTypeRequestDto request,
    String schoolId,
  ) async {
    await _api.submitDeductionType(extras, request.toJson());
    await _dao.acknowledge(request, schoolId: schoolId);
  }

  @override
  Future<bool> reject(
    PayrollDeductionTypeRequestDto request,
    StaffPushFailure failure,
    String schoolId,
  ) => _dao.refuse(
    request,
    schoolId: schoolId,
    code: failure.storedCode,
    reason: failure.reason,
  );

  @override
  bool get handlesTombstone => true;

  @override
  Future<void> tombstoned(
    PayrollDeductionTypeRequestDto request,
    String schoolId,
  ) => _dao.remove(schoolId, request.id);
}

/// `PAYROLL_DEDUCTION` — une saisie. Elle attend la rubrique qu'elle vise,
/// partie de cette tablette, et les gestes du mois posés avant elle.
///
/// Rubrique refusée sans que le serveur l'ait jamais eue, ou supprimée (410) :
/// la saisie échoue au lieu d'attendre, sinon le 409 d'attente gèlerait le
/// mois, dont les gestes l'attendent.
class PayrollDeductionOutboxHandler
    extends PayrollOutboxHandler<PayrollDeductionRequestDto> {
  final PayrollSyncApi _api;
  final PayrollDeductionDao _dao;
  final PayrollDeductionTypeDao _types;

  PayrollDeductionOutboxHandler({
    required PayrollSyncApi api,
    required PayrollDeductionDao dao,
    required PayrollDeductionTypeDao types,
    required super.outbox,
    required super.currentUser,
    required super.extras,
    super.members,
  }) : _api = api,
       _dao = dao,
       _types = types;

  @override
  String get aggregateType => PayrollOutbox.deduction;

  @override
  String? staffMemberOf(PayrollDeductionRequestDto request) =>
      request.staffMemberId;

  @override
  Set<String> get waitsFor => const {PayrollOutbox.gesture};

  @override
  Set<String> waitsForAnyOf(PayrollDeductionRequestDto request) => const {
    PayrollOutbox.deductionType,
  };

  @override
  PayrollDeductionRequestDto? parse(Object? raw) =>
      PayrollDeductionRequestDto.tryParse(raw);

  @override
  Future<OutboxDispatchResult?> hold(
    PayrollDeductionRequestDto request,
    String schoolId,
  ) async {
    final type = await _types.of(schoolId, request.deductionTypeId);
    if (type.state == StaffParentState.unsent) {
      return const OutboxDispatchResult.blocked('Rubrique pas encore accusée');
    }
    if (type.state != StaffParentState.refused) return null;
    final reason =
        'Rubrique ${type.label ?? request.deductionTypeId} refusée : '
        'elle n\'arrivera jamais au serveur';
    await reject(
      request,
      StaffPushFailure.local(PayrollDeductionCodes.typeRefused, reason),
      schoolId,
    );
    return OutboxDispatchResult.failed(reason);
  }

  @override
  Future<void> send(PayrollDeductionRequestDto request, String schoolId) async {
    await _api.submitDeduction(extras, request.toJson());
    await _dao.settle(request, schoolId: schoolId, failed: false);
  }

  @override
  Future<bool> reject(
    PayrollDeductionRequestDto request,
    StaffPushFailure failure,
    String schoolId,
  ) => _dao.settle(
    request,
    schoolId: schoolId,
    failed: true,
    code: failure.storedCode,
    reason: failure.reason,
  );

  @override
  bool get handlesTombstone => true;

  /// Le geste s'efface : l'envoi s'acquitte, et la saisie reste hors calcul,
  /// le temps que l'économe lise pourquoi le net remonte.
  @override
  Future<void> tombstoned(
    PayrollDeductionRequestDto request,
    String schoolId,
  ) => _dao.settle(
    request,
    schoolId: schoolId,
    failed: true,
    code: PayrollDeductionCodes.tombstoned,
    reason: 'Rubrique supprimée',
  );
}
