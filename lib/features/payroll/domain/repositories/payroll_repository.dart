import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_fingerprint.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/staff_pay_profile.dart';

/// La paie telle que la tablette la connaît — lecture 100 % locale, écriture
/// 100 % file d'envoi. Le dépôt normalise ; il ne juge pas : les gardes
/// métier (brouillon, droits, montants) se tiennent avant lui.
abstract class PayrollRepository {
  Future<Either<Failure, PayrollSnapshot>> load();

  Future<Either<Failure, Unit>> saveVariables(
    String month,
    PayrollVariables variables,
  );

  /// Pose un geste du circuit ; [expected] = l'empreinte vue (SUBMIT,
  /// VALIDATE), [reason] = le motif (RETURN, REOPEN).
  Future<Either<Failure, Unit>> recordGesture(
    String month,
    PayrollGestureKind kind, {
    String? reason,
    PayrollFingerprint? expected,
  });

  Future<Either<Failure, Unit>> saveProfile(StaffPayProfile profile);

  Future<Either<Failure, Unit>> saveSettings(PayrollSettings settings);

  Future<Either<Failure, Unit>> grantAdvance(SalaryAdvanceDraft draft);

  Future<Either<Failure, Unit>> cancelAdvance(String advanceId, String reason);

  Future<Either<Failure, Unit>> disburse(PayrollDisbursementDraft draft);

  Future<Either<Failure, Unit>> cancelDisbursement(
    PayrollDisbursement disbursement,
    String reason,
  );

  /// Trace locale d'une diffusion (jamais poussée).
  Future<Either<Failure, Unit>> recordShare(
    String month,
    String staffMemberId,
    PayrollShareChannel channel,
  );
}
