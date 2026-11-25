import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_permission_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_school_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, SyncEngine, systemClock;
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_read.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_declaration_dao.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_declaration_api.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_declaration_payload.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_push_failure.dart';
import 'package:school_app_flutter/features/expense/data/voucher/expense_voucher_blobs.dart';

/// Handler d'outbox de l'agrégat `EXPENSE_DECLARATION` — une dépense déjà
/// payée, et sa photo (v3, F37).
///
/// **L'argent est sorti avant que le serveur ne réponde.** D'où les règles :
/// 1. un refus terminal ne fait **jamais** disparaître la ligne — elle passe
///    « à régulariser » (F45), y compris sur un 410 qui, ailleurs, efface ;
/// 2. un droit retiré entre-temps **retient** l'entrée au lieu de la perdre
///    (garde de permission du socle) ;
/// 3. le rejeu est inerte (`SUPERSEDED`, même `expense.id`) : tout échec
///    local après le POST se rejoue sans risque.
class ExpenseDeclarationOutboxHandler
    implements OutboxWriteAccess, OutboxSyncHandler {
  final ExpenseDeclarationApi _api;
  final ExpenseDeclarationDao _dao;
  final ExpenseVoucherBlobs _blobs;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const ExpenseDeclarationOutboxHandler({
    required ExpenseDeclarationApi api,
    required ExpenseDeclarationDao dao,
    required ExpenseVoucherBlobs blobs,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _blobs = blobs,
       _currentUser = currentUser,
       _extras = extras,
       _now = now;

  /// Le refus rangé quand la photo n'est plus sur le poste (clé perdue) :
  /// la déclaration ne peut plus partir, et le dit.
  static const String bytesLostCode = 'LOCAL_BYTES_LOST';

  @override
  String get aggregateType => ExpenseDeclarationDao.aggregateType;

  @override
  ModuleAccess? writeAccessFor(OutboxEntry entry) => kExpenseDeclareAccess;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final ExpenseDeclarationPayload payload;
    try {
      payload = ExpenseDeclarationPayload.fromJson(
        jsonDecode(entry.payload) as Map<String, dynamic>,
      );
    } catch (e) {
      // Illisible ne se répare pas : la ligne passe « à régulariser » plutôt
      // que de rester comptée en attente, son fil gelé derrière elle.
      await _dao.markRefused(
        entry.aggregateId,
        code: 'PAYLOAD_UNREADABLE',
        reason: 'PAYLOAD_UNREADABLE',
        nowMs: _now(),
      );
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }
    final hold = outboxForeignSchoolHold(entry, _currentUser.schoolId);
    if (hold != null) return hold;
    final expenseId = payload.expense.id;

    final BlobRead voucher;
    try {
      voucher = await _blobs.read(expenseId);
    } catch (e) {
      return OutboxDispatchResult.retry('Photo du bon illisible : $e');
    }
    switch (voucher) {
      case BlobUnavailable():
        // Panne passagère du magasin : surtout ne rien condamner.
        return const OutboxDispatchResult.retry(
          'Magasin des bons indisponible',
        );
      case BlobGone():
        await _refuse(payload, code: bytesLostCode, reason: bytesLostCode);
        return const OutboxDispatchResult.failed(
          'La photo du bon n’est plus sur la tablette',
        );
      case BlobFound(:final blob):
        return _send(entry, payload, blob.bytes);
    }
  }

  Future<OutboxDispatchResult> _send(
    OutboxEntry entry,
    ExpenseDeclarationPayload payload,
    List<int> bytes,
  ) async {
    try {
      final ack = await _api.submit(
        _extras,
        payload,
        bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
      );
      await _dao.applyAck(
        ack.expense,
        localMessageIds: {payload.messageId, ?payload.visaMessageId},
        schoolId: entry.schoolId ?? '',
        nowMs: _now(),
      );
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      if (isOutboxPermissionDenial(e)) {
        return const OutboxDispatchResult.permissionDenied();
      }
      final failure = ExpensePushFailure.of(e);
      // Une route absente (déploiement en cours) n'est pas un refus du fond.
      final routeMissing =
          failure.detailCode == null &&
          (failure.status == 404 || failure.status == 405);
      if (failure.isTransient || routeMissing) {
        return _retry(entry, payload, failure.reason);
      }
      await _refuse(payload, code: failure.storedCode, reason: failure.reason);
      return OutboxDispatchResult.failed(failure.reason);
    } catch (e) {
      // Échec LOCAL après un POST peut-être accusé : le rejeu rend
      // `SUPERSEDED` et le même état.
      return _retry(entry, payload, e.toString());
    }
  }

  /// Rejoue — sauf à la dernière tentative avant que le moteur n'empoisonne
  /// l'entrée : la ligne passe alors « à régulariser » (F45). Sans cela elle
  /// resterait comptée en attente, et ses gestes bloqués derrière elle pour
  /// toujours.
  Future<OutboxDispatchResult> _retry(
    OutboxEntry entry,
    ExpenseDeclarationPayload payload,
    String reason,
  ) async {
    if (entry.attempts + 1 >= SyncEngine.defaultMaxAttempts) {
      await _refuse(payload, code: 'POISONED', reason: reason);
      return OutboxDispatchResult.failed(reason);
    }
    return OutboxDispatchResult.retry(reason);
  }

  Future<void> _refuse(
    ExpenseDeclarationPayload payload, {
    required String code,
    required String reason,
  }) => _dao.markRefused(
    payload.expense.id,
    code: code,
    reason: reason,
    nowMs: _now(),
  );
}
