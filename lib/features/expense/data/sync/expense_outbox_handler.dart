import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/auth/outbox_push_access.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_sync_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_write_dao.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_push_failure.dart';
import 'package:school_app_flutter/core/offline/outbox_school_guard.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_api.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_models.dart';
import 'package:school_app_flutter/core/offline/outbox_permission_guard.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';

/// Handler d'outbox de l'agrégat `EXPENSE` — le contenu d'une dépense.
///
/// 1. **Idempotence** sur `expense.id` : un rejeu rend 200 et l'état retenu.
/// 2. **Accusé LWW** : `APPLIED` comme `SUPERSEDED` rendent l'état canonique,
///    appliqué sans jamais écraser une saisie locale plus récente
///    ([ExpenseSyncDao.applyContentAck]).
/// 3. **Classement des échecs** ([ExpensePushFailure]) : 410 efface la ligne,
///    un refus déterministe la marque « à corriger » (A4) — sauf si une saisie
///    plus récente l'a remplacée pendant le vol, auquel cas l'entrée repart
///    avec elle au lieu d'être gelée en `SYNC_ERROR`.
/// 4. **École** : une dépense d'une autre école du poste attend la session de
///    la sienne ([outboxForeignSchoolHold]).
class ExpenseOutboxHandler implements OutboxWriteAccess, OutboxSyncHandler {
  final ExpenseSyncApi _api;
  final ExpenseSyncDao _dao;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const ExpenseOutboxHandler({
    required ExpenseSyncApi api,
    required ExpenseSyncDao dao,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _currentUser = currentUser,
       _extras = extras,
       _now = now;

  @override
  String get aggregateType => ExpenseWriteDao.aggregateType;

  /// Une avance au personnel exige en plus `hr.pay.read`, vérifié dans le code
  /// du serveur (`StaffAdvanceContent`). La tablette ne pose le bloc
  /// `staffAdvance` que sur ce type de dépense.
  @override
  ModuleAccess? writeAccessFor(OutboxEntry entry) {
    final ExpenseSyncRequestDto request;
    try {
      request = ExpenseSyncRequestDto.fromJson(
        jsonDecode(entry.payload) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
    return request.expense.staffAdvance == null
        ? kExpenseWriteAccess
        : kStaffAdvancePushAccess;
  }

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final ExpenseSyncRequestDto request;
    try {
      request = ExpenseSyncRequestDto.fromJson(
        jsonDecode(entry.payload) as Map<String, dynamic>,
      );
    } catch (e) {
      // Un payload illisible ne se répare pas en le rejouant.
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }
    final hold = outboxForeignSchoolHold(entry, _currentUser.schoolId);
    if (hold != null) return hold;
    final sent = request.expense;

    try {
      final ack = await _api.submitExpense(_extras, request);
      await _dao.applyContentAck(
        ack.expense,
        sentClientUpdatedAt: sent.clientUpdatedAt,
        schoolId: entry.schoolId ?? '',
        nowMs: _now(),
        authorId: request.authorId,
      );
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      final failure = ExpensePushFailure.of(e);
      if (failure.isTombstoned) {
        // Purgée côté serveur : la rejouer la ferait osciller. La ligne
        // s'efface, et l'entrée n'a plus rien à pousser.
        await _dao.deleteExpense(sent.id);
        return const OutboxDispatchResult.acked();
      }
      if (isOutboxPermissionDenial(e)) {
        return const OutboxDispatchResult.permissionDenied();
      }
      if (failure.isTransient) {
        return OutboxDispatchResult.retry(failure.reason);
      }
      final marked = await _dao.markRejected(
        sent.id,
        sentClientUpdatedAt: sent.clientUpdatedAt,
        code: failure.storedCode,
        reason: failure.reason,
        nowMs: _now(),
      );
      // Une saisie plus récente a remplacé l'entrée pendant le vol : la geler
      // en `SYNC_ERROR` gèlerait la correction elle-même.
      return marked
          ? OutboxDispatchResult.failed(failure.reason)
          : OutboxDispatchResult.retry(failure.reason);
    } catch (e) {
      // Échec LOCAL après un POST peut-être accusé : le rejeu est idempotent
      // et rendra le même état — sens de panne sûr.
      return OutboxDispatchResult.retry(e.toString());
    }
  }
}
