import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';

/// Ressources (`PullHandler.resource`) des trois flux du fichier du personnel.
/// Chaque curseur est rangé sous `<ressource>@<école>`.
const String kStaffMembersResource = 'staff_members';
const String kStaffContractsResource = 'staff_contracts';
const String kStaffDocumentsResource = 'staff_documents';

/// La descente du fichier du personnel, flux par flux.
abstract class StaffPullRepository {
  Future<Either<Failure, KeysetPullResult>> syncMembers();

  Future<Either<Failure, KeysetPullResult>> syncContracts();

  Future<Either<Failure, KeysetPullResult>> syncDocuments();
}
