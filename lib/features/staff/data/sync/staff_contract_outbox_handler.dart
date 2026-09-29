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
import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_push_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_push_failure.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_sync_api.dart';

/// Handler d'outbox de l'agrégat `STAFF_CONTRACT` — la pose d'une période.
///
/// **Dépend de la fiche.** Tant que la fiche de l'agent n'est pas connue du
/// serveur (aucune version accusée), la pose attend (`blocked` : ni tentative,
/// ni poison) ; le 409 `STAFF_MEMBER_NOT_YET_SYNCED` n'est qu'un filet. Une
/// fiche absente du poste (purgée) rend la pose sans objet.
class StaffContractOutboxHandler implements OutboxSyncHandler {
  final StaffSyncApi _api;
  final StaffContractSyncDao _dao;
  final StaffMemberDao _members;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const StaffContractOutboxHandler({
    required StaffSyncApi api,
    required StaffContractSyncDao dao,
    required StaffMemberDao members,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _members = members,
       _currentUser = currentUser,
       _extras = extras,
       _now = now;

  @override
  String get aggregateType => StaffContractWriteDao.contractAggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final StaffContractSyncRequestDto? request;
    try {
      request = StaffContractSyncRequestDto.tryParse(jsonDecode(entry.payload));
    } catch (e) {
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }
    if (request == null) {
      return const OutboxDispatchResult.failed('Payload de contrat incomplet');
    }
    final hold = outboxForeignSchoolHold(entry, _currentUser.schoolId);
    if (hold != null) return hold;

    final member = await _members.find(request.staffMemberId);
    if (member == null) {
      return const OutboxDispatchResult.failed('Agent inconnu sur le poste');
    }
    if (member.row['version'] == null) {
      return const OutboxDispatchResult.blocked('Fiche pas encore accusée');
    }

    final contractId = request.contract.id;
    try {
      final ack = await _api.submitStaffContract(
        _extras,
        request.staffMemberId,
        request.toBody(),
      );
      await _dao.applyAck(
        ack.contract,
        schoolId: entry.schoolId ?? '',
        nowMs: _now(),
      );
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      final failure = StaffPushFailure.of(e);
      if (failure.isDependencyWait) {
        return OutboxDispatchResult.blocked(failure.reason);
      }
      if (failure.isTombstoned) {
        await _dao.delete(contractId);
        return const OutboxDispatchResult.acked();
      }
      if (failure.isTransient) {
        return OutboxDispatchResult.retry(failure.reason);
      }
      await _dao.markRejected(
        contractId,
        code: failure.storedCode,
        reason: failure.reason,
        nowMs: _now(),
      );
      return OutboxDispatchResult.failed(failure.reason);
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }
}
