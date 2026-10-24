import 'package:school_app_flutter/features/payroll/data/local/payroll_arrears_priority_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_arrears_priority_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_outbox_handler.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_sync_api.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_push_failure.dart';

/// `PAYROLL_ARREARS_PRIORITY` — le drapeau « priorité » d'un arriéré (T9),
/// dernier écrit gagne ; attend la fiche de l'agent.
class PayrollArrearsPriorityOutboxHandler
    extends PayrollOutboxHandler<PayrollArrearsPriorityRequestDto> {
  final PayrollSyncApi _api;
  final PayrollArrearsPriorityDao _dao;

  PayrollArrearsPriorityOutboxHandler({
    required PayrollSyncApi api,
    required PayrollArrearsPriorityDao dao,
    required super.outbox,
    required super.currentUser,
    required super.extras,
    super.members,
  }) : _api = api,
       _dao = dao;

  @override
  String get aggregateType => PayrollOutbox.arrearsPriority;

  @override
  String? staffMemberOf(PayrollArrearsPriorityRequestDto request) =>
      request.priority.staffMemberId;

  @override
  PayrollArrearsPriorityRequestDto? parse(Object? raw) =>
      PayrollArrearsPriorityRequestDto.tryParse(raw);

  @override
  Future<void> send(
    PayrollArrearsPriorityRequestDto request,
    String schoolId,
  ) async {
    await _api.submitArrearsPriority(extras, request.toJson());
    await _dao.settle(request, schoolId: schoolId, failed: false);
  }

  @override
  Future<bool> reject(
    PayrollArrearsPriorityRequestDto request,
    StaffPushFailure failure,
    String schoolId,
  ) => _dao.settle(
    request,
    schoolId: schoolId,
    failed: true,
    code: failure.storedCode,
    reason: failure.reason,
  );
}
