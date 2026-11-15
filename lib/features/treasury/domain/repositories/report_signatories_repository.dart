import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/report_signatory.dart';

/// Les signataires imprimés au pied des rapports de caisse, en ligne
/// seulement.
abstract class ReportSignatoriesRepository {
  Future<Either<Failure, ReportSignatories>> fetch();

  /// Remplace toute la liste, gardée contre l'écrasement par l'instant de la
  /// liste montrée (`409 SIGNATORIES_CHANGED` sinon).
  Future<Either<Failure, ReportSignatories>> replace({
    required String? expectedUpdatedAt,
    required List<ReportSignatory> signatories,
  });
}
