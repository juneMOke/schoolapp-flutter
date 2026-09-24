import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_message_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_sync_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_write_dao.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_gesture_payload.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_push_failure.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_school_guard.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_api.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_models.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';

/// Handler d'outbox de l'agrégat `EXPENSE_GESTURE` — **un geste du circuit**.
///
/// ## La garde d'ordre (F31), et son échappatoire
///
/// Le serveur accepte une séquence **à condition qu'elle arrive dans
/// l'ordre** (Q4), et le socle ne le garantit pas : le moteur ne lit jamais
/// `aggregate_id`, poursuit après un `retry`, et son backoff retire une
/// entrée de la course pendant 1 à 256 s. L'ordre est donc à la charge de ce
/// handler, et le registre d'ordre est **le fil** : un geste ne part que s'il
/// porte le plus ancien message non accusé de sa dépense, sinon il attend en
/// `blocked` — ni tentative consommée, ni poison.
///
/// ⚠️ **`blocked` ne s'épuise jamais.** Sans échappatoire, un prédécesseur
/// refusé pour de bon gèlerait derrière lui tous les gestes de la même
/// demande, pour toujours. Quand le plus ancien message non accusé est en
/// `SYNC_ERROR`, ses suivants échouent donc à leur tour — la ligne passe « à
/// corriger », ce qui est un état dont on sort.
///
/// ## Les deux 409, aux conduites opposées (F34)
///
/// Seul le `detailCode` les sépare, et s'y tromper réécrit la décision d'un
/// collègue : `DECISION_ALREADY_TAKEN` réaligne et **ne rejoue jamais** ;
/// `TRANSITION_OUT_OF_ORDER` rejoue et **ne réaligne jamais**.
class ExpenseGestureOutboxHandler implements OutboxSyncHandler {
  final ExpenseSyncApi _api;
  final ExpenseSyncDao _dao;
  final ExpenseMessageDao _messages;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const ExpenseGestureOutboxHandler({
    required ExpenseSyncApi api,
    required ExpenseSyncDao dao,
    required ExpenseMessageDao messages,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _messages = messages,
       _currentUser = currentUser,
       _extras = extras,
       _now = now;

  @override
  String get aggregateType => ExpenseWriteDao.gestureAggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final ExpenseGesturePayload payload;
    try {
      payload = ExpenseGesturePayload.fromJson(
        jsonDecode(entry.payload) as Map<String, dynamic>,
      );
    } catch (e) {
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }
    final hold = expenseForeignSchoolHold(entry, _currentUser.schoolId);
    if (hold != null) return hold;

    final order = await _orderGuard(payload);
    if (order != null) return order;

    try {
      final ack = await _send(payload);
      await _dao.applyGestureAck(
        ack.expense,
        schoolId: entry.schoolId ?? '',
        nowMs: _now(),
      );
      await _messages.markMessage(payload.messageId, ExpenseSyncState.synced);
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      return _classify(e, payload, entry);
    } catch (e) {
      // Échec LOCAL après un POST peut-être accusé : le rejeu est inerte par
      // l'uuid du message, donc sûr.
      return OutboxDispatchResult.retry(e.toString());
    }
  }

  /// Le geste porte-t-il le plus ancien message non accusé de sa dépense ?
  ///
  /// Rend `null` quand il peut partir.
  Future<OutboxDispatchResult?> _orderGuard(
    ExpenseGesturePayload payload,
  ) async {
    final oldest = await _messages.oldestUnsettled(payload.expenseId);
    // Plus rien en attente : le message a déjà été accusé, et l'entrée court
    // après un geste réglé. Elle part quand même — le rejeu est inerte.
    if (oldest == null || oldest.id == payload.messageId) return null;
    if (oldest.state == ExpenseSyncState.rejected) {
      // L'échappatoire : le prédécesseur ne partira plus, et attendre son
      // tour reviendrait à ne jamais partir.
      await _messages.markMessage(payload.messageId, ExpenseSyncState.rejected);
      return const OutboxDispatchResult.failed(
        'Un geste antérieur sur cette demande a été refusé : '
        'la suite ne peut plus partir dans l\'ordre',
      );
    }
    return const OutboxDispatchResult.blocked(
      'Un geste antérieur sur cette demande attend encore son tour',
    );
  }

  Future<ExpenseSyncResponseDto> _send(ExpenseGesturePayload payload) {
    final body = payload.toWireJson();
    final id = payload.expenseId;
    return switch (payload.gesture) {
      ExpenseGesture.approve ||
      ExpenseGesture.refuse => _api.decideExpense(_extras, id, body),
      ExpenseGesture.pay => _api.payExpense(_extras, id, body),
      ExpenseGesture.reopen => _api.reopenExpense(_extras, id, body),
      ExpenseGesture.retract => _api.retractExpense(_extras, id, body),
      ExpenseGesture.resubmit => _api.resubmitExpense(_extras, id, body),
      ExpenseGesture.remind => _api.remindExpense(_extras, id, body),
      ExpenseGesture.comment => _api.commentExpense(_extras, id, body),
    };
  }

  Future<OutboxDispatchResult> _classify(
    DioException e,
    ExpenseGesturePayload payload,
    OutboxEntry entry,
  ) async {
    final failure = ExpensePushFailure.of(e);
    if (failure.isTombstoned) {
      await _dao.deleteExpense(payload.expenseId);
      return const OutboxDispatchResult.acked();
    }
    if (failure.isSettledElsewhere) {
      // Un collègue a tranché. On se range derrière son état — fil compris —
      // et le geste s'arrête là. Le rejouer écraserait sa décision.
      final canonical = failure.canonical;
      if (canonical != null) {
        await _dao.applyGestureAck(
          canonical,
          schoolId: entry.schoolId ?? '',
          nowMs: _now(),
        );
      }
      await _messages.markMessage(payload.messageId, ExpenseSyncState.rejected);
      return OutboxDispatchResult.failed(failure.reason);
    }
    // `TRANSITION_OUT_OF_ORDER` et les transitoires se rejouent — et surtout
    // le premier ne réaligne RIEN : la ligne locale est juste.
    if (failure.isRetriableConflict || failure.isTransient) {
      return OutboxDispatchResult.retry(failure.reason);
    }
    // 403, 422 : terminal. Le geste est défait côté serveur — il n'a jamais
    // eu lieu — et la ligne passe « à corriger » (A4, F22).
    await _messages.markMessage(payload.messageId, ExpenseSyncState.rejected);
    await _dao.markGestureRejected(
      payload.expenseId,
      code: failure.storedCode,
      reason: failure.reason,
      nowMs: _now(),
    );
    return OutboxDispatchResult.failed(failure.reason);
  }
}
