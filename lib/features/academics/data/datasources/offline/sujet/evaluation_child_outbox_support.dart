import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';

/// Ce que partagent les envois rattachés à une évaluation — le sujet, le
/// journal des copies : la garde d'auteur, la garde « évaluation accusée » et
/// le classement des erreurs réseau.
class EvaluationChildOutboxSupport {
  final AcademicsLocalDataSource academics;
  final CurrentUserContext? currentUser;

  const EvaluationChildOutboxSupport({
    required this.academics,
    this.currentUser,
  });

  /// Tablette partagée : une écriture d'un autre compte ne part pas sous ce
  /// jeton (le serveur la refuserait en 403 terminal) ; elle attend la
  /// reconnexion de son auteur.
  OutboxDispatchResult? attribution(String? authorId) {
    if (authorId == null || authorId == currentUser?.uid) return null;
    return const OutboxDispatchResult.blocked(
      'Saisie d\'un autre utilisateur — repartira à sa reconnexion',
    );
  }

  /// L'évaluation doit être connue du serveur : en attente → on attend ;
  /// refusée ou évincée → l'écriture ne pourra jamais s'y rattacher.
  Future<OutboxDispatchResult?> evaluationGate(String evaluationId) async {
    final evaluation = await academics.getEvaluation(evaluationId);
    if (evaluation == null) {
      return const OutboxDispatchResult.failed('Évaluation absente');
    }
    return switch (evaluation.syncState) {
      SyncState.pendingSync => const OutboxDispatchResult.blocked(
        'Évaluation non synchronisée — partira après elle',
      ),
      SyncState.syncError => const OutboxDispatchResult.failed(
        'Évaluation refusée par le serveur',
      ),
      _ => null,
    };
  }

  /// Erreurs hors refus métier : 404 (évaluation pas encore acquittée) et
  /// réseau, 5xx, 401 → nouvel essai ; 400 et 403 → terminal.
  OutboxDispatchResult classify(DioException e) {
    final failure = e.error;
    final message = failure is Failure ? failure.message : e.message;
    if (e.response?.statusCode == 404) {
      return OutboxDispatchResult.retry(message);
    }
    if (failure is ValidationFailure || failure is UnauthorizedFailure) {
      return OutboxDispatchResult.failed(message ?? 'Rejected');
    }
    return OutboxDispatchResult.retry(message);
  }
}
