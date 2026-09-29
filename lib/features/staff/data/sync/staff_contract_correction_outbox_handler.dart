import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_school_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/staff/data/local/staff_contract_sync_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_push_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_push_failure.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_sync_api.dart';

/// Handler d'outbox de l'agrégat `STAFF_CONTRACT_CORRECTION` — la correction
/// d'une période saisie par erreur.
///
/// **Dépend de la période corrigée** : tant qu'elle n'est pas connue du
/// serveur, la correction attend (`blocked`) ; le 409
/// `STAFF_CONTRACT_NOT_YET_SYNCED` n'est qu'un filet. Un refus rend la période
/// d'origine à la frise et efface le remplaçant, jamais accepté.
class StaffContractCorrectionOutboxHandler implements OutboxSyncHandler {
  final StaffSyncApi _api;
  final StaffContractSyncDao _dao;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const StaffContractCorrectionOutboxHandler({
    required StaffSyncApi api,
    required StaffContractSyncDao dao,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _currentUser = currentUser,
       _extras = extras,
       _now = now;

  @override
  String get aggregateType => StaffContractWriteDao.correctionAggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final StaffContractCorrectionRequestDto? request;
    try {
      request = StaffContractCorrectionRequestDto.tryParse(
        jsonDecode(entry.payload),
      );
    } catch (e) {
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }
    if (request == null) {
      return const OutboxDispatchResult.failed(
        'Payload de correction incomplet',
      );
    }
    final hold = outboxForeignSchoolHold(entry, _currentUser.schoolId);
    if (hold != null) return hold;
    if (!await _dao.isSynced(request.contractId)) {
      return const OutboxDispatchResult.blocked('Période pas encore accusée');
    }

    try {
      final ack = await _api.correctStaffContract(_extras, request.toBody());
      await _dao.applyCorrectionAck(
        corrected: ack.corrected,
        replacement: ack.replacement,
        schoolId: entry.schoolId ?? '',
        nowMs: _now(),
      );
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      final failure = StaffPushFailure.of(e);
      if (failure.isDependencyWait) {
        return OutboxDispatchResult.blocked(failure.reason);
      }
      if (failure.isTransient) {
        return OutboxDispatchResult.retry(failure.reason);
      }
      // 410 compris : la période purgée ne se corrige plus, le remplaçant
      // tombe avec elle.
      await _dao.rejectCorrection(
        contractId: request.contractId,
        replacementId: request.replacement?.id,
        code: failure.storedCode,
        reason: failure.reason,
        nowMs: _now(),
      );
      return failure.isTombstoned
          ? const OutboxDispatchResult.acked()
          : OutboxDispatchResult.failed(failure.reason);
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }
}
