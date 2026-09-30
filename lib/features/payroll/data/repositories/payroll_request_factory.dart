import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_cancellation_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_disbursement_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_write_requests.dart';
import 'package:school_app_flutter/features/payroll/data/sync/salary_advance_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/staff_pay_profile_dto.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_fingerprint.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/staff_pay_profile.dart';

/// Traduit une saisie en la requête figée qui partira : identifiants neufs,
/// auteur et horloge estampillés **à la saisie** — c'est ce que le serveur
/// comparera.
class PayrollRequestFactory {
  final String authorId;
  final String schoolId;

  /// Instant UTC ISO-8601 de la saisie.
  final String stamp;
  final IdGenerator _ids;

  const PayrollRequestFactory({
    required this.authorId,
    required this.schoolId,
    required this.stamp,
    required IdGenerator ids,
  }) : _ids = ids;

  String get _today => stamp.substring(0, 10);

  PayrollVariablesRequestDto variables(String month, PayrollVariables v) =>
      PayrollVariablesRequestDto(
        month: month,
        staffMemberId: v.staffMemberId,
        overtimeMinutes: v.overtimeMinutes,
        overtimeRateInCents: v.overtimeRateInCents,
        dependentChildren: v.dependentChildren,
        clientUpdatedAt: stamp,
        authorId: authorId,
      );

  PayrollGestureRequestDto gesture(
    String month,
    PayrollGestureKind kind, {
    String? reason,
    PayrollFingerprint? expected,
  }) => PayrollGestureRequestDto(
    gestureId: _ids.newId(),
    month: month,
    kind: kind.wire,
    reason: reason,
    expected: expected,
    clientRecordedAt: stamp,
    authorId: authorId,
  );

  StaffPayProfileRequestDto profile(StaffPayProfile profile) =>
      StaffPayProfileRequestDto(
        profile: StaffPayProfileDto(
          staffMemberId: profile.staffMemberId,
          dependentChildren: profile.dependentChildren,
          // Exigé par le serveur : sans choix, les espèces.
          preferredMode: (profile.preferredMode ?? PayoutMode.cash).wire,
          operator: profile.operator?.wire,
          payoutPhone: _blankToNull(profile.payoutPhone),
          bankName: _blankToNull(profile.bankName),
          bankAccount: _blankToNull(profile.bankAccount),
          clientUpdatedAt: stamp,
        ),
        authorId: authorId,
      );

  SalaryAdvanceRequestDto advance(SalaryAdvanceDraft draft) =>
      SalaryAdvanceRequestDto(
        advance: SalaryAdvanceDto(
          id: _ids.newId(),
          staffMemberId: draft.staffMemberId,
          amountInCents: draft.amount.amountInCents,
          currency: draft.amount.currency,
          installments: draft.installments,
          firstMonth: draft.firstMonth,
          reason: draft.reason.wire,
          reasonDetail: _blankToNull(draft.reasonDetail),
          mode: draft.mode.wire,
          grantedOn: draft.grantedOn.isEmpty ? _today : draft.grantedOn,
          clientRecordedAt: stamp,
        ),
        authorId: authorId,
      );

  /// Seuls les champs du mode choisi partent : un numéro resté dans le profil
  /// ne voyage pas avec un versement en espèces.
  PayrollDisbursementRequestDto disbursement(PayrollDisbursementDraft draft) {
    final mobile = draft.mode == PayoutMode.mobileMoney;
    final bank = draft.mode == PayoutMode.bank;
    return PayrollDisbursementRequestDto(
      disbursement: PayrollDisbursementDto(
        id: _ids.newId(),
        month: draft.month,
        staffMemberId: draft.staffMemberId,
        validationGestureId: draft.validationGestureId,
        amountInCents: draft.amount.amountInCents,
        currency: draft.amount.currency,
        mode: draft.mode.wire,
        operator: mobile ? draft.operator?.wire : null,
        payoutPhone: mobile ? _blankToNull(draft.payoutPhone) : null,
        reference: mobile || bank
            ? _blankToNull(draft.reference)?.toUpperCase()
            : null,
        bankName: bank ? _blankToNull(draft.bankName) : null,
        bankAccount: bank ? _blankToNull(draft.bankAccount) : null,
        signedRegister: draft.mode == PayoutMode.cash && draft.signedRegister,
        paidAt: stamp,
      ),
      authorId: authorId,
    );
  }

  PayrollCancellationRequestDto cancellation(String targetId, String reason) =>
      PayrollCancellationRequestDto(
        clientRecordedAt: stamp,
        cancellationId: _ids.newId(),
        targetId: targetId,
        reason: reason,
        authorId: authorId,
      );

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
