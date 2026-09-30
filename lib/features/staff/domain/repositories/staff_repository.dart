import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';

/// Le fichier du personnel tel que la tablette le connaît — lecture 100 %
/// locale.
abstract class StaffRepository {
  Future<Either<Failure, StaffFileSnapshot>> loadFile();

  /// Une fiche, relue sur la tablette.
  Future<Either<Failure, StaffMember>> findMember(String staffMemberId);

  /// Écrit la fiche sur la tablette et la met en file d'envoi, dans une seule
  /// transaction. La fiche doit avoir été validée : le dépôt normalise, il ne
  /// juge pas.
  Future<Either<Failure, Unit>> saveMember(StaffMemberDraft draft);
}
