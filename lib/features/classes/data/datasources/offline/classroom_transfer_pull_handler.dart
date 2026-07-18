import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_transfer_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_transfer_pull_repository.dart';

/// [PullHandler] des transferts (F5) — enregistré sur le `PullCoordinator`. Le
/// jeton vit dans `sync_meta` via le repository, le périmètre (école/année) est
/// porté par le JWT. Ne lève pas : l'échec (`Left`) → [PullOutcome.error].
class ClassroomTransferPullHandler implements PullHandler {
  final ClassroomTransferPullRepository _repository;

  const ClassroomTransferPullHandler(this._repository);

  @override
  String get resource => ClassroomTransferPullRepositoryImpl.resource;

  @override
  Future<PullOutcome> pull() async {
    final result = await _repository.syncTransfers();
    return result.fold(
      (failure) => PullOutcome.error(failure.toString()),
      (outcome) => outcome.notModified
          ? const PullOutcome.notModified()
          : PullOutcome.updated(upserted: outcome.upserted),
    );
  }
}
