import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payslip_repository.dart';

/// Lit toute la paie sur la tablette.
class LoadPayrollUseCase {
  final PayrollRepository _repository;

  const LoadPayrollUseCase(this._repository);

  Future<Either<Failure, PayrollSnapshot>> call() => _repository.load();
}

/// Télécharge le bulletin scellé d'un agent — le serveur n'en sert pas de
/// recueil : « tous les bulletins » n'existe qu'en provisoire, sur la tablette.
class FetchPayslipUseCase {
  final PayslipRepository _repository;

  const FetchPayslipUseCase(this._repository);

  Future<Either<Failure, Uint8List>> call(String month, String staffMemberId) =>
      _repository.payslip(month, staffMemberId);
}

/// Note sur la tablette qu'un bulletin l'a quittée (WhatsApp ouvert, PDF).
class RecordPayslipShareUseCase {
  final PayrollRepository _repository;

  const RecordPayslipShareUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    String month,
    String staffMemberId,
    PayrollShareChannel channel,
  ) => _repository.recordShare(month, staffMemberId, channel);
}
