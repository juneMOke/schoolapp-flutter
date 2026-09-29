import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_contract_repository.dart';

/// Les périodes d'un agent, montants compris.
class LoadStaffContractsUseCase {
  final StaffContractRepository _repository;

  const LoadStaffContractsUseCase(this._repository);

  Future<Either<Failure, List<StaffContract>>> call(String staffMemberId) =>
      _repository.contractsOf(staffMemberId);
}

/// Pose une période et la met en file d'envoi.
class AddStaffContractUseCase {
  final StaffContractRepository _repository;

  const AddStaffContractUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    String staffMemberId,
    StaffContractDraft draft,
  ) => _repository.addContract(staffMemberId, draft);
}

/// Corrige une période — avec un remplaçant, ou sans (doublon).
class CorrectStaffContractUseCase {
  final StaffContractRepository _repository;

  const CorrectStaffContractUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    StaffContract original, {
    required String reason,
    StaffContractDraft? replacement,
  }) => _repository.correctContract(
    original,
    reason: reason,
    replacement: replacement,
  );
}
