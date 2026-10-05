import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_school_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_read.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_blobs.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_dao.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_local_model.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_sync_dao.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_write_dao.dart';
import 'package:school_app_flutter/features/student_photo/data/student_photo_change_bus.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_api.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_dto.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_push_failure.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_push_request.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';

/// Handler d'outbox de l'agrégat `STUDENT_PHOTO` — la pose ou le retrait de
/// la photo d'un élève.
///
/// **Dépend de l'inscription** : la photo d'un élève saisi sur ce poste attend
/// que sa fiche soit accusée (`blocked`). Une inscription refusée (422,
/// `SYNC_ERROR`) n'est pas morte — elle se corrige et repart — et la photo
/// l'attend donc aussi. Si l'élève disparaît du poste puis que le serveur
/// répond qu'il ne le connaît pas, le geste est refusé et ses octets effacés :
/// la photo ne partira jamais.
class StudentPhotoOutboxHandler implements OutboxSyncHandler {
  final StudentPhotoApi _api;
  final StudentPhotoSyncDao _sync;
  final StudentPhotoDao _photos;
  final StudentPhotoBlobs _blobs;
  final StudentPhotoChangeBus _bus;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const StudentPhotoOutboxHandler({
    required StudentPhotoApi api,
    required StudentPhotoSyncDao sync,
    required StudentPhotoDao photos,
    required StudentPhotoBlobs blobs,
    required StudentPhotoChangeBus bus,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _sync = sync,
       _photos = photos,
       _blobs = blobs,
       _bus = bus,
       _currentUser = currentUser,
       _extras = extras,
       _now = now;

  /// Le refus rangé quand les octets du geste ne sont plus sur le poste.
  static const String bytesLostCode = 'LOCAL_BYTES_LOST';

  @override
  String get aggregateType => StudentPhotoWriteDao.aggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final StudentPhotoPushRequest? parsed;
    try {
      parsed = StudentPhotoPushRequest.tryParse(jsonDecode(entry.payload));
    } catch (e) {
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }
    if (parsed == null) {
      return const OutboxDispatchResult.failed('Payload de photo incomplet');
    }
    final request = parsed;
    final hold = outboxForeignSchoolHold(entry, _currentUser.schoolId);
    if (hold != null) return hold;

    // Déjà soldé (accusé dont l'entrée a survécu) : rien à renvoyer.
    final row = await _sync.find(request.studentId);
    if (row == null) {
      // L'élève a été retiré (registre des disparitions) : sa ligne est
      // partie, ses octets en attente ne partiront jamais.
      final sha = request.sha256;
      if (sha != null) await _blobs.deletePending(request.studentId, sha);
      return const OutboxDispatchResult.acked();
    }
    if (!row.holdsGesture(request.op, request.at)) {
      return const OutboxDispatchResult.acked();
    }

    final student = await _sync.studentSyncState(request.studentId);
    if (student != null && student != SyncState.synced) {
      return const OutboxDispatchResult.blocked(
        'Inscription pas encore accusée',
      );
    }

    if (request.op == StudentPhotoOp.delete) {
      return _push(request, student, () => _api.delete(_extras, request));
    }
    final read = await _blobs.readPending(request.studentId, request.sha256!);
    switch (read) {
      case BlobUnavailable():
        return const OutboxDispatchResult.retry('Magasin indisponible');
      case BlobGone():
        return _reject(request, bytesLostCode, 'Octets de la photo perdus');
      case BlobFound(:final blob):
        if (blob.sha256Hex != request.sha256) {
          return _reject(request, bytesLostCode, 'Octets de la photo altérés');
        }
        return _push(
          request,
          student,
          () => _api.put(_extras, request, blob.bytes),
          sent: blob.bytes,
        );
    }
  }

  Future<OutboxDispatchResult> _push(
    StudentPhotoPushRequest request,
    SyncState? student,
    Future<StudentPhotoStateDto> Function() send, {
    Uint8List? sent,
  }) async {
    final StudentPhotoStateDto state;
    try {
      state = await send();
    } on DioException catch (e) {
      final failure = StudentPhotoPushFailure.of(e);
      // Le poste porte la fiche : son inscription n'est simplement pas encore
      // arrivée. Sans fiche sur le poste, rien ne viendra la débloquer.
      if (failure.awaitsStudent && student != null) {
        return _unlessReplaced(
          request,
          OutboxDispatchResult.blocked(failure.reason),
        );
      }
      if (failure.isStudentGone) return _drop(request);
      if (failure.isTransient) {
        return _unlessReplaced(
          request,
          OutboxDispatchResult.retry(failure.reason),
        );
      }
      return _reject(request, failure.storedCode, failure.reason);
    } catch (e) {
      return _unlessReplaced(request, OutboxDispatchResult.retry(e.toString()));
    }

    final settled = await _sync.applyAck(request, state, nowMs: _now());
    if (settled) await _settleBytes(request, state, sent);
    _bus.emit({request.studentId});
    return const OutboxDispatchResult.acked();
  }

  /// Ce que deviennent les octets une fois le geste accusé : la photo envoyée
  /// devient la copie d'affichage si c'est bien elle que le serveur garde ;
  /// un retrait efface les copies.
  Future<void> _settleBytes(
    StudentPhotoPushRequest request,
    StudentPhotoStateDto state,
    Uint8List? sent,
  ) async {
    final studentId = request.studentId;
    final serverSha = state.sha256;
    if (request.op == StudentPhotoOp.put) {
      final ours =
          sent != null &&
          serverSha != null &&
          sameInstant(state.takenAt, request.at);
      if (ours &&
          await _blobs.writeCache(studentId, StudentPhotoSize.full, sent)) {
        await _photos.markCached(
          studentId,
          StudentPhotoSize.full,
          sha256: serverSha,
        );
      }
      await _blobs.deletePending(studentId, request.sha256!);
    }
    if (serverSha == null) {
      await _blobs.deleteCaches(studentId);
      for (final size in StudentPhotoSize.values) {
        await _photos.markCached(studentId, size, sha256: null);
      }
    }
  }

  Future<OutboxDispatchResult> _reject(
    StudentPhotoPushRequest request,
    String code,
    String reason,
  ) async {
    final marked = await _sync.markRejected(
      request,
      code: code,
      reason: reason,
      nowMs: _now(),
    );
    // Remplacé pendant l'envoi : le nouveau geste repart avec son entrée à
    // lui. L'accusé est gardé par `created_at`, il ne la touchera pas.
    if (!marked) return const OutboxDispatchResult.acked();
    if (request.op == StudentPhotoOp.put) {
      await _blobs.deletePending(request.studentId, request.sha256!);
    }
    _bus.emit({request.studentId});
    return OutboxDispatchResult.failed(reason);
  }

  /// L'élève purgé côté serveur (410) : le geste et ses octets s'effacent.
  Future<OutboxDispatchResult> _drop(StudentPhotoPushRequest request) async {
    if (await _sync.dropGesture(request, nowMs: _now()) &&
        request.op == StudentPhotoOp.put) {
      await _blobs.deletePending(request.studentId, request.sha256!);
    }
    _bus.emit({request.studentId});
    return const OutboxDispatchResult.acked();
  }

  /// Un geste remplacé pendant l'envoi ne se rejoue pas : son entrée porte
  /// déjà le geste neuf, qui ne doit hériter ni de ses tentatives ni de son
  /// backoff.
  Future<OutboxDispatchResult> _unlessReplaced(
    StudentPhotoPushRequest request,
    OutboxDispatchResult result,
  ) async {
    final row = await _sync.find(request.studentId);
    if (row == null || !row.holdsGesture(request.op, request.at)) {
      return const OutboxDispatchResult.acked();
    }
    return result;
  }

  /// Deux instants ISO-8601 égaux à la milliseconde, quelle que soit leur
  /// écriture (le serveur peut rendre des microsecondes, ou un autre format).
  static bool sameInstant(String? a, String? b) {
    final left = a == null ? null : DateTime.tryParse(a);
    final right = b == null ? null : DateTime.tryParse(b);
    if (left == null || right == null) return false;
    return left.millisecondsSinceEpoch == right.millisecondsSinceEpoch;
  }
}
