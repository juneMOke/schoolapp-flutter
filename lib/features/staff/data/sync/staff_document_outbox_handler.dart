import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_school_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_sync_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_push_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_transfer_api.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_push_failure.dart';

/// Handler d'outbox de l'agrégat `STAFF_DOCUMENT` — le versement d'une pièce.
///
/// **Dépend de la fiche**, comme la pose d'un contrat : tant qu'elle n'est pas
/// accusée, la pièce attend (`blocked`, « bloquée par la fiche »). Les octets
/// sont relus dans le magasin chiffré au moment de l'envoi ; une pièce dont les
/// octets ont disparu (clé perdue) ne peut plus partir et le dit.
class StaffDocumentOutboxHandler implements OutboxSyncHandler {
  final StaffDocumentTransferApi _api;
  final StaffDocumentSyncDao _dao;
  final StaffMemberDao _members;
  final EncryptedBlobStore _store;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const StaffDocumentOutboxHandler({
    required StaffDocumentTransferApi api,
    required StaffDocumentSyncDao dao,
    required StaffMemberDao members,
    required EncryptedBlobStore store,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _members = members,
       _store = store,
       _currentUser = currentUser,
       _extras = extras,
       _now = now;

  /// Le refus rangé quand les octets ne sont plus sur le poste.
  static const String bytesLostCode = 'LOCAL_BYTES_LOST';

  @override
  String get aggregateType => StaffDocumentWriteDao.aggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final StaffDocumentUploadDto? request;
    try {
      request = StaffDocumentUploadDto.tryParse(jsonDecode(entry.payload));
    } catch (e) {
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }
    if (request == null) {
      return const OutboxDispatchResult.failed('Payload de pièce incomplet');
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

    final read = await _store.read(request.id);
    switch (read) {
      case BlobUnavailable():
        return const OutboxDispatchResult.retry('Magasin indisponible');
      case BlobGone():
        const reason = 'Octets de la pièce perdus sur le poste';
        await _dao.markRejected(
          request.id,
          code: bytesLostCode,
          reason: reason,
          nowMs: _now(),
        );
        return const OutboxDispatchResult.failed(reason);
      case BlobFound(:final blob):
        return _send(entry, request, blob.bytes);
    }
  }

  Future<OutboxDispatchResult> _send(
    OutboxEntry entry,
    StaffDocumentUploadDto request,
    Uint8List bytes,
  ) async {
    try {
      final ack = await _api.upload(_extras, request, bytes);
      await _dao.applyAck(ack, schoolId: entry.schoolId ?? '', nowMs: _now());
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      final failure = StaffPushFailure.of(e);
      if (failure.isDependencyWait) {
        return OutboxDispatchResult.blocked(failure.reason);
      }
      if (failure.isTombstoned) {
        await _dao.delete(request.id);
        await _store.delete(request.id);
        return const OutboxDispatchResult.acked();
      }
      if (failure.isTransient) {
        return OutboxDispatchResult.retry(failure.reason);
      }
      await _dao.markRejected(
        request.id,
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
