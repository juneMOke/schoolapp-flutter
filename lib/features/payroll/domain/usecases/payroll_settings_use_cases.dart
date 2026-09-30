import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/phone_number_format.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/staff_pay_profile.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_repository.dart';

/// Enregistre le profil de paie d'un agent.
class SaveStaffPayProfileUseCase {
  final PayrollRepository _repository;

  const SaveStaffPayProfileUseCase(this._repository);

  Future<Either<Failure, Unit>> call(StaffPayProfile profile) async {
    if (profile.dependentChildren < 0) {
      return Left(PayrollRuleFailure(PayrollRule.invalidAmount));
    }
    final phone = profile.payoutPhone;
    if (phone != null &&
        phone.isNotEmpty &&
        !PhoneNumberFormat.isValid(phone)) {
      return Left(PayrollRuleFailure(PayrollRule.mobileDetailsRequired));
    }
    return _repository.saveProfile(profile);
  }
}

/// Enregistre les réglages de paie de l'école (direction).
class SavePayrollSettingsUseCase {
  final PayrollRepository _repository;

  const SavePayrollSettingsUseCase(this._repository);

  Future<Either<Failure, Unit>> call(PayrollSettings settings) async {
    final invalid =
        settings.monthlyHoursDivisor <= 0 ||
        settings.overtimeMultiplierPermille < 1000 ||
        settings.byCurrency.values.any(
          (currency) =>
              currency.childAllowanceInCents < 0 ||
              currency.defaultOvertimeRateInCents < 0 ||
              currency.overtimeRateStepInCents < 0,
        );
    if (invalid) return Left(PayrollRuleFailure(PayrollRule.invalidAmount));
    return _repository.saveSettings(settings);
  }
}
