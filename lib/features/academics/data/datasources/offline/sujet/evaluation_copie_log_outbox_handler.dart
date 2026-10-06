import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_evaluation_sujet_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_copie_log_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/sujet/evaluation_child_outbox_support.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/sujet/evaluation_view_applier.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/sujet_wire_models.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet_codes.dart';

/// Type d'agrégat d'outbox d'une diffusion de copie (une entrée par ligne).
const String kEvaluationCopieLogAggregateType =
    'ACADEMICS_EVALUATION_COPIE_LOG';

/// Pousse une diffusion (`POST …/evaluations/{id}/copie-log`), insert seul :
/// un rejeu rend 200. L'évaluation doit être accusée. La réponse — l'évaluation
/// entière — rafraîchit le journal, qui accuse la ligne au passage.
/// `COPIE_LOG_MISMATCH` (identifiant déjà pris ailleurs) est terminal.
class EvaluationCopieLogOutboxHandler implements OutboxSyncHandler {
  final AcademicsEvaluationSujetApi api;
  final EvaluationCopieLogLocalDataSource copieLog;
  final EvaluationViewApplier views;
  final EvaluationChildOutboxSupport support;
  final Map<String, dynamic> requiredAuth;
  final Clock now;

  const EvaluationCopieLogOutboxHandler({
    required this.api,
    required this.copieLog,
    required this.views,
    required this.support,
    required this.requiredAuth,
    this.now = systemClock,
  });

  @override
  String get aggregateType => kEvaluationCopieLogAggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final CopieLogPushRequestModel request;
    try {
      request = CopieLogPushRequestModel.fromJsonString(entry.payload);
    } catch (_) {
      return const OutboxDispatchResult.failed('Invalid copy log payload');
    }
    final blocked = support.attribution(request.authorId);
    if (blocked != null) return blocked;

    final result = await _send(request);
    if (result.outcome == OutboxDispatchOutcome.failed) {
      try {
        await copieLog.markSyncError(request.entry.id);
      } catch (_) {
        // Terminal même si l'écriture locale échoue.
      }
    }
    return result;
  }

  Future<OutboxDispatchResult> _send(CopieLogPushRequestModel request) async {
    final evaluationId = request.entry.evaluationId;
    try {
      final gate = await support.evaluationGate(evaluationId);
      if (gate != null) return gate;
      final view = await api.logCopie(
        requiredAuth,
        evaluationId,
        request.toBody(),
      );
      await copieLog.markSynced(request.entry.id);
      await views.apply([view], now());
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      final code = ApiErrorParser.detailCodeOf(e.response);
      if (e.response?.statusCode == 422 &&
          code == EvaluationSujetCodes.copieLogMismatch) {
        return OutboxDispatchResult.failed(code!);
      }
      return support.classify(e);
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }
}
