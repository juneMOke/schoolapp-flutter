import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_school_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/justification/justification_decision_payload.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/justification/attendance_justification_api.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/justification/attendance_justification_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/justification_enums.dart';

/// Le code d'un `gestureId` déjà servi pour une AUTRE justification : un bug
/// de tablette, rien que l'utilisateur puisse corriger.
const String kDecisionGestureIdConflictCode = 'DECISION_GESTURE_ID_CONFLICT';

/// Pousse la décision de l'école sur une justification
/// (`POST /sync/attendance-justifications/{id}/decision`).
///
/// - 200 → la justification telle que le serveur la tient, **la décision
///   d'une autre tablette comprise** : c'est elle qui s'écrit, jamais celle
///   envoyée ;
/// - 422 `NOT_AN_ABSENCE` / `MONTH_CLOSED` (acceptation seulement) → le
///   serveur garde la demande en attente : elle revient « à traiter », avec
///   la raison, et seul le refus reste possible ;
/// - 422 `DECISION_GESTURE_ID_CONFLICT` → bug de tablette : la demande revient
///   « à traiter », sans rien dire ;
/// - 409 → la demande a déjà été tranchée : elle revient telle que le pull la
///   redescendra, sans rejeu ;
/// - 403 → attente propre si le geste est d'un autre compte, refus sinon ;
/// - autre 4xx → refus définitif, la demande revient « à traiter » ;
/// - réseau, 5xx, 401 → nouvel essai.
///
/// Dans les trois premiers cas d'échec l'entrée sort de la file par `acked` :
/// le serveur a tranché, il n'y a plus rien à envoyer — la décision
/// suivante sera un geste neuf.
class JustificationDecisionOutboxHandler implements OutboxSyncHandler {
  final AttendanceJustificationApi api;
  final AttendanceJustificationLocalDataSource justifications;
  final Map<String, dynamic> requiredAuth;
  final CurrentUserContext currentUser;

  const JustificationDecisionOutboxHandler({
    required this.api,
    required this.justifications,
    required this.requiredAuth,
    required this.currentUser,
  });

  @override
  String get aggregateType => kJustificationDecisionAggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final JustificationDecisionPayload payload;
    try {
      payload = JustificationDecisionPayload.fromJsonString(entry.payload);
    } catch (_) {
      return const OutboxDispatchResult.failed('Invalid decision payload');
    }
    final hold = outboxForeignSchoolHold(entry, currentUser.schoolId);
    if (hold != null) return hold;
    if (payload.authorId == null) {
      return _refuse(payload, JustificationRefusal.noAuthor);
    }
    try {
      final response = await api.decide(
        requiredAuth,
        payload.justificationId,
        payload.toWireJson(),
      );
      await justifications.applyAck(payload, response);
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      return _classify(e, payload);
    } catch (e) {
      // Échec LOCAL après un POST peut-être accusé : le rejeu est inerte par
      // le `gestureId`, donc sûr.
      return OutboxDispatchResult.retry(e.toString());
    }
  }

  Future<OutboxDispatchResult> _classify(
    DioException e,
    JustificationDecisionPayload payload,
  ) async {
    final status = e.response?.statusCode;
    final code = ApiErrorParser.detailCodeOf(e.response);
    final block = JustificationAcceptBlock.fromCode(code);
    if (block != null) {
      await justifications.revertDecision(payload, acceptBlock: block);
      return const OutboxDispatchResult.acked();
    }
    if (code == kDecisionGestureIdConflictCode || status == 409) {
      await justifications.revertDecision(payload);
      return const OutboxDispatchResult.acked();
    }
    if (status == 403) {
      final blocked = OutboxDispatchResult.blockForeignAuthor(
        payload.authorId,
        currentUser.uid,
      );
      if (blocked != null) return blocked;
      return _refuse(payload, JustificationRefusal.forbidden);
    }
    final failure = e.error;
    if (failure is ValidationFailure || failure is NotFoundFailure) {
      return _refuse(payload, JustificationRefusal.rejected);
    }
    return OutboxDispatchResult.retry(
      failure is Failure ? failure.message : e.message,
    );
  }

  Future<OutboxDispatchResult> _refuse(
    JustificationDecisionPayload payload,
    JustificationRefusal refusal,
  ) async {
    await justifications.revertDecision(payload, refusal: refusal);
    return OutboxDispatchResult.failed(
      'Justification decision refused: ${refusal.code}',
    );
  }
}
