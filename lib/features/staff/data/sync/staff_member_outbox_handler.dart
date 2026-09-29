import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_school_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/staff/data/local/staff_member_sync_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_push_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_push_failure.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_sync_api.dart';

/// Handler d'outbox de l'agrégat `STAFF_MEMBER` — la fiche d'un agent.
///
/// 1. **Idempotence** sur l'uuid de la fiche : un rejeu rend 200 et l'état
///    retenu, sans consommer de matricule.
/// 2. **Accusé LWW** : `APPLIED` comme `SUPERSEDED` rendent l'état canonique,
///    appliqué sans jamais écraser une saisie locale plus récente.
/// 3. **Échecs** ([StaffPushFailure]) : 410 efface la fiche ; un refus
///    déterministe la marque « refusée » — sauf si une saisie plus récente l'a
///    remplacée pendant le vol, auquel cas l'entrée repart avec elle.
/// 4. **École** : une fiche d'une autre école du poste attend la session de la
///    sienne.
class StaffMemberOutboxHandler implements OutboxSyncHandler {
  final StaffSyncApi _api;
  final StaffMemberSyncDao _dao;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const StaffMemberOutboxHandler({
    required StaffSyncApi api,
    required StaffMemberSyncDao dao,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _currentUser = currentUser,
       _extras = extras,
       _now = now;

  @override
  String get aggregateType => StaffMemberWriteDao.aggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final StaffMemberSyncRequestDto? request;
    try {
      request = StaffMemberSyncRequestDto.tryParse(jsonDecode(entry.payload));
    } catch (e) {
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }
    // Un payload illisible ne se répare pas en le rejouant.
    if (request == null) {
      return const OutboxDispatchResult.failed('Payload de fiche incomplet');
    }
    final hold = outboxForeignSchoolHold(entry, _currentUser.schoolId);
    if (hold != null) return hold;
    final sent = request.staffMember;

    try {
      final ack = await _api.submitStaffMember(_extras, request.toJson());
      await _dao.applyAck(
        ack.staffMember,
        sentClientUpdatedAt: sent.clientUpdatedAt,
        schoolId: entry.schoolId ?? '',
        nowMs: _now(),
      );
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      final failure = StaffPushFailure.of(e);
      if (failure.isTombstoned) {
        await _dao.delete(sent.id);
        return const OutboxDispatchResult.acked();
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
