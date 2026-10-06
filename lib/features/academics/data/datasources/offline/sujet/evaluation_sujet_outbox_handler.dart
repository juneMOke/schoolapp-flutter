import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_evaluation_sujet_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_sujet_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/sujet/evaluation_child_outbox_support.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/sujet/evaluation_view_applier.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet_codes.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/sujet_wire_models.dart';

/// Type d'agrégat d'outbox du sujet (une entrée par évaluation, remplacée à
/// chaque enregistrement : seule la dernière version part).
const String kEvaluationSujetAggregateType = 'ACADEMICS_EVALUATION_SUJET';

/// Pousse le sujet d'une évaluation (`PUT …/evaluations/{id}/sujet`),
/// sous-agrégat LWW sur `clientUpdatedAt`.
///
/// - L'évaluation doit être accusée : en attente → `blocked`, refusée →
///   `failed`.
/// - 200 : la réponse est l'évaluation entière. Si le sujet retenu est le
///   nôtre (`sujetClientUpdatedAt` = celui envoyé), il passe `SYNCED` ; sinon
///   le serveur avait plus récent, on prend le sien — sauf brouillon ré-édité
///   entre-temps, qui repartira. L'évaluation, son journal et ses publications
///   sont rafraîchis au passage.
/// - 422 `MAX_LOCKED` / `QUESTION_MISMATCH` : refus terminal, le brouillon
///   reste lisible avec son code (`sujet_rejection_code`).
/// - 404 (évaluation pas encore acquittée), réseau, 5xx, 401 → nouvel essai ;
///   400, 403 → terminal.
class EvaluationSujetOutboxHandler implements OutboxSyncHandler {
  final AcademicsEvaluationSujetApi api;
  final EvaluationSujetLocalDataSource sujets;
  final EvaluationViewApplier views;
  final EvaluationChildOutboxSupport support;
  final Map<String, dynamic> requiredAuth;
  final Clock now;

  const EvaluationSujetOutboxHandler({
    required this.api,
    required this.sujets,
    required this.views,
    required this.support,
    required this.requiredAuth,
    this.now = systemClock,
  });

  static const List<String> _terminalCodes = [
    EvaluationSujetCodes.maxLocked,
    EvaluationSujetCodes.questionMismatch,
  ];

  @override
  String get aggregateType => kEvaluationSujetAggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final SujetPushRequestModel request;
    try {
      request = SujetPushRequestModel.fromJsonString(entry.payload);
    } catch (_) {
      return const OutboxDispatchResult.failed('Invalid subject payload');
    }
    final blocked = support.attribution(request.authorId);
    if (blocked != null) return blocked;

    try {
      final gate = await support.evaluationGate(request.evaluationId);
      if (gate != null) return gate;

      final view = await api.replaceSujet(
        requiredAuth,
        request.evaluationId,
        request.toBody(),
      );
      if (view.toSujetRow().updatedAt == request.clientUpdatedAt) {
        await sujets.markSujetSynced(
          evaluationId: request.evaluationId,
          pushedUpdatedAt: request.clientUpdatedAt,
        );
      } else {
        await sujets.replaceSupersededSujet(
          evaluationId: request.evaluationId,
          pushedUpdatedAt: request.clientUpdatedAt,
          serverSujet: view.toSujetRow(),
        );
      }
      await views.apply([view], now());
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      final code = ApiErrorParser.detailCodeOf(e.response);
      if (e.response?.statusCode == 422 && _terminalCodes.contains(code)) {
        try {
          await sujets.markSujetSyncError(
            evaluationId: request.evaluationId,
            pushedUpdatedAt: request.clientUpdatedAt,
            rejectionCode: code,
          );
        } catch (_) {
          // Le refus reste terminal même si l'écriture locale échoue : un
          // retry repousserait indéfiniment un 422 déterministe.
        }
        return OutboxDispatchResult.failed(code!);
      }
      return support.classify(e);
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }
}
