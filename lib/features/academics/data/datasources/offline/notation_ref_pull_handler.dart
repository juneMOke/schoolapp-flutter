import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/notation_ref_pull_repository_impl.dart';

/// [PullHandler] du squelette de notation par cours (réf du détail cours).
/// Enregistré sur le `PullCoordinator`. Ne lève pas.
class NotationRefPullHandler implements PullHandler {
  final NotationRefPullRepositoryImpl _repository;

  const NotationRefPullHandler(this._repository);

  @override
  String get resource => kNotationSkeletonResource;

  @override
  Future<PullOutcome> pull() async {
    final result = await _repository.syncNotationSkeletons();
    return result.fold(
      (failure) => PullOutcome.error(failure.toString()),
      (outcome) => outcome.notModified
          ? const PullOutcome.notModified()
          : PullOutcome.updated(upserted: outcome.upserted),
    );
  }
}
