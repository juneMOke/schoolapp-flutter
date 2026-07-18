import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_transfer_pull_outcome.dart';

/// Contrat du pull keyset des transferts (F5) : capte les transferts visibles
/// serveur (ce poste + ceux faits en ligne) et pose le drapeau
/// `bootstrapComplete`. Ne lève jamais (l'échec est un `Left`).
abstract class ClassroomTransferPullRepository {
  Future<Either<Failure, ClassroomTransferPullOutcome>> syncTransfers();
}
