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

  /// Tous les bulletins scellés du mois, en un PDF.
  Future<Either<Failure, Uint8List>> month(String month) =>
      _repository.monthPayslips(month);

  /// L'état de paie du mois.
  Future<Either<Failure, Uint8List>> statement(String month) =>
      _repository.statement(month);

  /// Le bulletin provisoire d'un agent (P8).
  Future<Either<Failure, Uint8List>> preview(
    String month,
    String staffMemberId,
  ) => _repository.payslipPreview(month, staffMemberId);

  Future<Either<Failure, Uint8List>> dashboard(
    String month, {
    required String filter,
    String? query,
  }) => _repository.dashboard(month, filter: filter, query: query);
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
