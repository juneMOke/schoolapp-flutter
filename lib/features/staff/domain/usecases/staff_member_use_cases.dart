import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_repository.dart';

/// Enregistre une fiche sur la tablette et la met en file d'envoi.
class SaveStaffMemberUseCase {
  final StaffRepository _repository;

  const SaveStaffMemberUseCase(this._repository);

  Future<Either<Failure, Unit>> call(StaffMemberDraft draft) =>
      _repository.saveMember(draft);
}

/// Relit une fiche sur la tablette.
class LoadStaffMemberUseCase {
  final StaffRepository _repository;

  const LoadStaffMemberUseCase(this._repository);

  Future<Either<Failure, StaffMember>> call(String staffMemberId) =>
      _repository.findMember(staffMemberId);
}
