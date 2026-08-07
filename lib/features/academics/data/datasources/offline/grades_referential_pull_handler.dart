import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/grades_referential_pull_repository_impl.dart';

/// [PullHandler] du bundle `grades-referential` (réf de saisie, ETag). Ne
/// lève pas — enregistré sur le `PullCoordinator`.
class GradesReferentialPullHandler implements PullHandler {
  final GradesReferentialPullRepositoryImpl _repository;

  const GradesReferentialPullHandler(this._repository);

  @override
  String get resource => kGradesReferentialResource;

  @override
  Future<PullOutcome> pull() async {
    final result = await _repository.syncGradesReferential();
    return result.fold(
      (failure) => PullOutcome.error(failure.toString()),
      (outcome) => outcome.notModified
          ? const PullOutcome.notModified()
          : PullOutcome.updated(upserted: outcome.upserted),
    );
  }
}
