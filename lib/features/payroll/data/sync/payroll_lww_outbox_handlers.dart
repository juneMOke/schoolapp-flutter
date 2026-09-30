import 'package:school_app_flutter/core/staff/local/payroll_settings_seed.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_settings_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_variables_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/staff_pay_profile_dao.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_outbox_handler.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_sync_api.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_write_requests.dart';
import 'package:school_app_flutter/features/payroll/data/sync/staff_pay_profile_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_push_failure.dart';

// Les trois remontées « dernier écrit gagne » de la paie : l'accusé et le
// refus se jugent sur l'horloge envoyée — une saisie retouchée pendant le vol
// part à son tour.

/// `PAYROLL_SETTINGS` — les réglages de l'école.
class PayrollSettingsOutboxHandler
    extends PayrollOutboxHandler<PayrollSettingsRequestDto> {
  final PayrollSyncApi _api;
  final PayrollSettingsDao _dao;

  PayrollSettingsOutboxHandler({
    required PayrollSyncApi api,
    required PayrollSettingsDao dao,
    required super.outbox,
    required super.currentUser,
    required super.extras,
  }) : _api = api,
       _dao = dao;

  @override
  String get aggregateType => PayrollOutbox.settings;

  @override
  PayrollSettingsRequestDto? parse(Object? raw) =>
      PayrollSettingsRequestDto.tryParse(raw);

  @override
  Future<void> send(PayrollSettingsRequestDto request, String schoolId) async {
    final response = await _api.putSettings(extras, request.toJson());
    await _dao.settle(
      schoolId,
      sentClientUpdatedAt: request.clientUpdatedAt,
      failed: false,
      retained: PayrollSettingsSeed.tryParse(response),
    );
  }

  @override
  Future<bool> reject(
    PayrollSettingsRequestDto request,
    StaffPushFailure failure,
    String schoolId,
  ) => _dao.settle(
    schoolId,
    sentClientUpdatedAt: request.clientUpdatedAt,
    failed: true,
    code: failure.storedCode,
    reason: failure.reason,
  );
}

/// `STAFF_PAY_PROFILE` — le profil de paie d'un agent ; attend la fiche
/// (`409 STAFF_MEMBER_NOT_YET_SYNCED`).
class StaffPayProfileOutboxHandler
    extends PayrollOutboxHandler<StaffPayProfileRequestDto> {
  final PayrollSyncApi _api;
  final StaffPayProfileDao _dao;

  StaffPayProfileOutboxHandler({
    required PayrollSyncApi api,
    required StaffPayProfileDao dao,
    required super.outbox,
    required super.currentUser,
    required super.extras,
  }) : _api = api,
       _dao = dao;

  @override
  String get aggregateType => PayrollOutbox.profile;

  @override
  StaffPayProfileRequestDto? parse(Object? raw) =>
      StaffPayProfileRequestDto.tryParse(raw);

  @override
  Future<void> send(StaffPayProfileRequestDto request, String schoolId) async {
    final response = await _api.submitProfile(extras, request.toJson());
    await _dao.settle(
      request.profile.staffMemberId,
      sentClientUpdatedAt: request.profile.clientUpdatedAt,
      failed: false,
      retained: StaffPayProfileDto.tryParse(response),
    );
  }

  @override
  Future<bool> reject(
    StaffPayProfileRequestDto request,
    StaffPushFailure failure,
    String schoolId,
  ) => _dao.settle(
    request.profile.staffMemberId,
    sentClientUpdatedAt: request.profile.clientUpdatedAt,
    failed: true,
    code: failure.storedCode,
    reason: failure.reason,
  );
}

/// `PAYROLL_VARIABLES` — les éléments variables d'un agent. Attend les gestes
/// du mois posés avant eux : « rouvrir puis corriger » ne doit pas arriver
/// sur une paie encore validée.
class PayrollVariablesOutboxHandler
    extends PayrollOutboxHandler<PayrollVariablesRequestDto> {
  final PayrollSyncApi _api;
  final PayrollVariablesDao _dao;

  PayrollVariablesOutboxHandler({
    required PayrollSyncApi api,
    required PayrollVariablesDao dao,
    required super.outbox,
    required super.currentUser,
    required super.extras,
  }) : _api = api,
       _dao = dao;

  @override
  String get aggregateType => PayrollOutbox.variables;

  @override
  Set<String> get waitsFor => const {PayrollOutbox.gesture};

  @override
  PayrollVariablesRequestDto? parse(Object? raw) =>
      PayrollVariablesRequestDto.tryParse(raw);

  @override
  Future<void> send(PayrollVariablesRequestDto request, String schoolId) async {
    await _api.submitVariables(extras, request.toJson());
    await _dao.settle(request, schoolId: schoolId, failed: false);
  }

  @override
  Future<bool> reject(
    PayrollVariablesRequestDto request,
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
