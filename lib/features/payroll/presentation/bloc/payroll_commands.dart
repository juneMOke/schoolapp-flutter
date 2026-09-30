import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/staff_pay_profile.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_circuit_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_money_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_read_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_settings_use_cases.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_notice.dart';

/// Les gestes de la paie : chacun passe par son cas d'usage et rend l'annonce
/// à montrer — succès, règle refusée, ou écriture impossible.
class PayrollCommands {
  final SavePayrollVariablesUseCase _variables;
  final RecordPayrollGestureUseCase _gesture;
  final DisbursePayrollUseCase _disburse;
  final CancelPayrollDisbursementUseCase _cancelDisbursement;
  final GrantSalaryAdvanceUseCase _grant;
  final CancelSalaryAdvanceUseCase _cancelAdvance;
  final SaveStaffPayProfileUseCase _profile;
  final SavePayrollSettingsUseCase _settings;
  final RecordPayslipShareUseCase _share;
  final FetchPayslipUseCase _payslip;

  const PayrollCommands({
    required SavePayrollVariablesUseCase variables,
    required RecordPayrollGestureUseCase gesture,
    required DisbursePayrollUseCase disburse,
    required CancelPayrollDisbursementUseCase cancelDisbursement,
    required GrantSalaryAdvanceUseCase grant,
    required CancelSalaryAdvanceUseCase cancelAdvance,
    required SaveStaffPayProfileUseCase profile,
    required SavePayrollSettingsUseCase settings,
    required RecordPayslipShareUseCase share,
    required FetchPayslipUseCase payslip,
  }) : _variables = variables,
       _gesture = gesture,
       _disburse = disburse,
       _cancelDisbursement = cancelDisbursement,
       _grant = grant,
       _cancelAdvance = cancelAdvance,
       _profile = profile,
       _settings = settings,
       _share = share,
       _payslip = payslip;

  Future<PayrollNotice> saveVariables(
    PayrollMonthView view,
    PayrollVariables variables, {
    required String name,
  }) async => _notice(
    await _variables(view, variables),
    PayrollNotice(PayrollNoticeKind.variablesSaved, name: name),
  );

  Future<PayrollNotice> gesture(
    PayrollMonthView view,
    PayrollGestureKind kind, {
    String? reason,
  }) async => _notice(
    await _gesture(view, kind, reason: reason),
    PayrollNotice(switch (kind) {
      PayrollGestureKind.submit => PayrollNoticeKind.submitted,
      PayrollGestureKind.validate => PayrollNoticeKind.validated,
      PayrollGestureKind.returnToDraft => PayrollNoticeKind.returned,
      PayrollGestureKind.reopen => PayrollNoticeKind.reopened,
    }),
  );

  Future<PayrollNotice> disburse(
    PayrollMonthView view,
    PayrollDisbursementDraft draft, {
    required String name,
    required String amount,
  }) async => _notice(
    await _disburse(view, draft),
    PayrollNotice(PayrollNoticeKind.paid, name: name, amount: amount),
  );

  Future<PayrollNotice> cancelDisbursement(
    PayrollDisbursement disbursement,
    String reason,
  ) async => _notice(
    await _cancelDisbursement(disbursement, reason),
    const PayrollNotice(PayrollNoticeKind.payCancelled),
  );

  Future<PayrollNotice> grantAdvance(
    PayrollSnapshot snapshot,
    SalaryAdvanceDraft draft, {
    required String name,
    required String amount,
  }) async => _notice(
    await _grant(snapshot, draft),
    PayrollNotice(PayrollNoticeKind.advanceGranted, name: name, amount: amount),
  );

  Future<PayrollNotice> cancelAdvance(
    PayrollSnapshot snapshot,
    SalaryAdvance advance,
    String reason,
  ) async => _notice(
    await _cancelAdvance(snapshot, advance, reason),
    const PayrollNotice(PayrollNoticeKind.advanceCancelled),
  );

  Future<PayrollNotice> saveProfile(StaffPayProfile profile) async => _notice(
    await _profile(profile),
    const PayrollNotice(PayrollNoticeKind.profileSaved),
  );

  Future<PayrollNotice> saveSettings(PayrollSettings settings) async => _notice(
    await _settings(settings),
    const PayrollNotice(PayrollNoticeKind.settingsSaved),
  );

  /// La trace locale d'une diffusion : un échec ne se montre pas, le bulletin
  /// est déjà parti.
  Future<void> recordShare(
    String month,
    String staffMemberId,
    PayrollShareChannel channel,
  ) => _share(month, staffMemberId, channel);

  /// Le bulletin scellé d'un agent — en ligne seulement.
  Future<Either<Failure, Uint8List>> payslip(
    String month,
    String staffMemberId,
  ) => _payslip(month, staffMemberId);

  static PayrollNotice _notice(
    Either<Failure, Unit> result,
    PayrollNotice success,
  ) => result.fold(
    (failure) => failure is PayrollRuleFailure
        ? PayrollNotice(PayrollNoticeKind.refused, rule: failure.rule)
        : const PayrollNotice(PayrollNoticeKind.writeFailed),
    (_) => success,
  );
}
