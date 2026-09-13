import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_delta_columns.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_local_model.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_read_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_sync_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_write_dao.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_push_failure.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_school_guard.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_api.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_models.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';

/// Handler d'outbox de l'agrégat `EXPENSE_WITHDRAWAL` — retirer ou restaurer.
///
/// ## Un geste qui n'a plus d'objet ne part pas
///
/// Le geste envoyé doit être celui qui attend sur la ligne
/// (`withdrawal_pending_at`). Sinon il a été réglé autrement — retrait sur le
/// poste seul, accusé appliqué juste avant une coupure — et il est acquitté
/// sans appel.
///
/// ## Attendre que la dépense existe côté serveur
///
/// Le moteur traite chaque entrée pour elle-même : un contenu rejoué plus tard
/// (5xx) n'empêche pas le retrait qui le suit de partir. Or le serveur répond
/// 404 à un retrait sur une dépense qu'il ne connaît pas encore. Tant que la
/// ligne n'a pas de numéro — c'est-à-dire tant qu'aucun accusé n'est revenu —
/// le retrait attend donc **proprement** (`blocked` : ni tentative, ni poison),
/// et part dès que le contenu est accusé.
///
/// Sauf si le dernier envoi du contenu a été **refusé** : le numéro ne viendra
/// pas, et le retrait attendrait pour toujours. Il se règle alors sur le poste
/// seul ([ExpenseWriteDao.setLocalOnlyWithdrawal]).
class ExpenseWithdrawalOutboxHandler implements OutboxSyncHandler {
  final ExpenseSyncApi _api;
  final ExpenseReadDao _reader;
  final ExpenseWriteDao _writer;
  final ExpenseSyncDao _dao;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const ExpenseWithdrawalOutboxHandler({
    required ExpenseSyncApi api,
    required ExpenseReadDao reader,
    required ExpenseWriteDao writer,
    required ExpenseSyncDao dao,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _reader = reader,
       _writer = writer,
       _dao = dao,
       _currentUser = currentUser,
       _extras = extras,
       _now = now;

  @override
  String get aggregateType => ExpenseWriteDao.withdrawalAggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final ExpenseWithdrawalPayload payload;
    try {
      payload = ExpenseWithdrawalPayload.fromJson(
        jsonDecode(entry.payload) as Map<String, dynamic>,
      );
    } catch (e) {
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }
    final hold = expenseForeignSchoolHold(entry, _currentUser.schoolId);
    if (hold != null) return hold;

    final row = await _reader.find(payload.expenseId);
    // Ligne effacée entre-temps (410, disparition) : plus rien à retirer.
    if (row == null) return const OutboxDispatchResult.acked();
    if (!ExpenseDeltaColumns.sameInstant(
      row.withdrawalPendingAt,
      payload.changedAt,
    )) {
      return const OutboxDispatchResult.acked();
    }
    if (row.expenseNumber == null) return _withoutNumber(row, payload);

    try {
      final ack = await _api.setWithdrawn(
        _extras,
        payload.expenseId,
        payload.toWireJson(),
      );
      await _dao.applyWithdrawalAck(
        ack.expense,
        sentChangedAt: payload.changedAt,
        nowMs: _now(),
      );
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      final failure = ExpensePushFailure.of(e);
      if (failure.isTombstoned) {
        // Purgée côté serveur : la ligne s'efface, le geste n'a plus d'objet.
        await _dao.deleteExpense(payload.expenseId);
        return const OutboxDispatchResult.acked();
      }
      if (failure.status == 404) {
        // Numérotée mais inconnue de l'école : le geste n'a plus d'objet, et
        // l'attente se lève pour que le pull reprenne la main sur la ligne.
        await _dao.releaseWithdrawal(
          payload.expenseId,
          sentChangedAt: payload.changedAt,
          nowMs: _now(),
        );
        return const OutboxDispatchResult.acked();
      }
      if (failure.isTransient) {
        return OutboxDispatchResult.retry(failure.reason);
      }
      final reverted = await _dao.revertWithdrawal(
        payload.expenseId,
        sentChangedAt: payload.changedAt,
        nowMs: _now(),
      );
      return reverted
          ? OutboxDispatchResult.failed(failure.reason)
          : OutboxDispatchResult.retry(failure.reason);
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }

  Future<OutboxDispatchResult> _withoutNumber(
    ExpenseLocalModel row,
    ExpenseWithdrawalPayload payload,
  ) async {
    if (row.syncStatus == ExpenseSyncState.rejected.dbValue) {
      final settled = await _writer.setLocalOnlyWithdrawal(
        expenseId: payload.expenseId,
        deletedAt: payload.deleted ? payload.changedAt : null,
        nowMs: _now(),
        expectedPendingAt: payload.changedAt,
      );
      if (settled) return const OutboxDispatchResult.acked();
    }
    return const OutboxDispatchResult.blocked(
      'Dépense pas encore accusée par le serveur — le retrait attend',
    );
  }
}
