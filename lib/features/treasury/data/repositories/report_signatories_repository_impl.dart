import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/data/online/report_signatories_api.dart';
import 'package:school_app_flutter/features/treasury/data/repositories/treasury_online.dart';
import 'package:school_app_flutter/features/treasury/data/wire/report_signatories_wire.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/report_signatory.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/report_signatories_repository.dart';

class ReportSignatoriesRepositoryImpl implements ReportSignatoriesRepository {
  final ReportSignatoriesApi _api;

  const ReportSignatoriesRepositoryImpl(this._api);

  @override
  Future<Either<Failure, ReportSignatories>> fetch() =>
      guardTreasury(_api.fetch);

  @override
  Future<Either<Failure, ReportSignatories>> replace({
    required String? expectedUpdatedAt,
    required List<ReportSignatory> signatories,
  }) async {
    final result = await guardTreasury(
      () => _api.replace(
        expectedUpdatedAt: expectedUpdatedAt,
        signatories: signatories,
      ),
    );
    return result.leftMap(_withCurrentList);
  }

  /// Un `SIGNATORIES_CHANGED` porte la liste actuelle dans `details` : on la
  /// rend lisible pour l'écran. Illisible, le refus reste tel quel.
  static Failure _withCurrentList(Failure failure) {
    if (failure is! TreasuryRefusalFailure ||
        failure.refusal != TreasuryRefusal.signatoriesChanged) {
      return failure;
    }
    final current = ReportSignatoriesWire.fromDetails(failure.details);
    return current == null ? failure : SignatoriesChangedFailure(current);
  }
}
