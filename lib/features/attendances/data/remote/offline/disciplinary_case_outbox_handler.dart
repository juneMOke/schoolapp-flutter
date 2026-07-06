import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart'
    show OutboxOperation;
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/attendances/data/models/offline/create_disciplinary_case_offline_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/update_disciplinary_case_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/remote/disciplinary_case_remote_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/disciplinary_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/disciplinary_case_offline_repository_impl.dart'
    show kDisciplinaryAggregateType;

/// Pousse les cas disciplinaires (DF-2). Deux régimes selon l'opération :
///
/// - **CREATE (régime A)** : `POST /disciplinary-cases` avec l'`id` CLIENT
///   honoré → idempotent (rejeu ⇒ 0 doublon). Succès → cas marqué SYNCED.
/// - **UPDATE (régime C)** : `PUT /disciplinary-cases/{id}` (status + sanction
///   courante). 409 (verrou optimiste périmé) → refetch best-effort + retry
///   (rejeu LWW). Réconciliation `version` complète = TODO (le read model
///   n'expose pas encore `version`/`updatedAt` — back DG-2).
class DisciplinaryCaseOutboxHandler implements OutboxSyncHandler {
  final DisciplinaryCaseRemoteDataSource remoteDataSource;
  final DisciplinaryLocalDataSource localDataSource;
  final Map<String, dynamic> requiredAuth;
  final Clock now;

  const DisciplinaryCaseOutboxHandler({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.requiredAuth,
    this.now = systemClock,
  });

  @override
  String get aggregateType => kDisciplinaryAggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) {
    return switch (entry.operation) {
      OutboxOperation.create => _dispatchCreate(entry),
      OutboxOperation.update ||
      OutboxOperation.upsert => _dispatchUpdate(entry),
    };
  }

  Future<OutboxDispatchResult> _dispatchCreate(OutboxEntry entry) async {
    late final CreateDisciplinaryCaseOfflineRequestModel request;
    try {
      request = CreateDisciplinaryCaseOfflineRequestModel.fromJsonString(
        entry.payload,
      );
    } catch (_) {
      return const OutboxDispatchResult.failed('Invalid create payload');
    }

    try {
      await remoteDataSource.createCaseWithClientId(requiredAuth, request);
      await localDataSource.markCaseSynced(entry.aggregateId, syncedAt: now());
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      return _mapDioError(e);
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }

  Future<OutboxDispatchResult> _dispatchUpdate(OutboxEntry entry) async {
    late final UpdateDisciplinaryCaseRequestModel request;
    try {
      request = UpdateDisciplinaryCaseRequestModel.fromJsonString(
        entry.payload,
      );
    } catch (_) {
      return const OutboxDispatchResult.failed('Invalid update payload');
    }

    try {
      await remoteDataSource.updateDisciplinaryCase(
        requiredAuth,
        entry.aggregateId,
        request,
      );
      await localDataSource.markCaseSynced(entry.aggregateId, syncedAt: now());
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      if (e.error is ConflictFailure) {
        // 409 : refetch best-effort puis rejeu (LWW). On ne fait pas échouer.
        await _refetchQuietly(entry.aggregateId);
        return const OutboxDispatchResult.retry('Conflict — refetch + replay');
      }
      return _mapDioError(e);
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }

  /// Refetch silencieux pour rafraîchir l'état serveur avant rejeu (409).
  Future<void> _refetchQuietly(String caseId) async {
    try {
      await remoteDataSource.getCaseById(requiredAuth, caseId);
    } catch (_) {
      // Best-effort : un échec de refetch n'empêche pas le rejeu (retry).
    }
  }

  OutboxDispatchResult _mapDioError(DioException e) {
    final failure = e.error;
    if (failure is ValidationFailure || failure is NotFoundFailure) {
      return OutboxDispatchResult.failed(
        failure is Failure ? failure.message : 'Rejected',
      );
    }
    return OutboxDispatchResult.retry(
      failure is Failure ? failure.message : e.message,
    );
  }
}
